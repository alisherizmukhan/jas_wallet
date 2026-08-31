package com.jaswallet.app

import android.app.Activity
import android.bluetooth.BluetoothManager
import android.content.Context
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.saltosystems.justinmobile.sdk.ble.IJustinBleDigitalKeyRetriever
import com.saltosystems.justinmobile.sdk.ble.IJustinBleResultAndDiscoverCallbacks
import com.saltosystems.justinmobile.sdk.ble.JustinBle
import com.saltosystems.justinmobile.sdk.common.DigitalKeyRetrieveParams
import com.saltosystems.justinmobile.sdk.common.OpResult
import com.saltosystems.justinmobile.sdk.common.TechnologyVersion
import com.saltosystems.justinmobile.sdk.common.UnlockingMode
import com.saltosystems.justinmobile.sdk.common.UnlockingParams
import com.saltosystems.justinmobile.sdk.exceptions.JustinException
import com.saltosystems.justinmobile.sdk.model.DigitalKey

class SaltoPlugin(private val activity: Activity) : MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL = "com.jasaim/salto"
        // Filter logcat with:  adb logcat -s SaltoPlugin
        private const val TAG = "SaltoPlugin"

        fun registerWith(flutterEngine: FlutterEngine, activity: Activity) {
            Log.d(TAG, "registerWith: registering channel '$CHANNEL' on ${activity.javaClass.name}")
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            channel.setMethodCallHandler(SaltoPlugin(activity))
        }
    }

    override fun onMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "onMethodCall: method='${call.method}'")
        when (call.method) {
            "startUnlock" -> {
                val keyHex = call.argument<String>("digitalKeyHex")
                if (keyHex.isNullOrBlank()) {
                    Log.w(TAG, "startUnlock: keyHex is null/blank -> noKey")
                    result.success("noKey")
                    return
                }
                startUnlock(keyHex, result)
            }
            "validateKey" -> {
                val keyHex = call.argument<String>("digitalKeyHex")
                val valid = if (keyHex.isNullOrBlank()) false else try {
                    DigitalKey(keyHex).isValid
                } catch (e: Exception) {
                    Log.e(TAG, "validateKey: exception while validating", e)
                    false
                }
                Log.d(TAG, "validateKey: keyLen=${keyHex?.length ?: 0} -> valid=$valid")
                result.success(valid)
            }
            "getSdkInt" -> {
                Log.d(TAG, "getSdkInt: ${Build.VERSION.SDK_INT}")
                result.success(Build.VERSION.SDK_INT)
            }
            "getBluetoothState" -> {
                val state = getBluetoothAdapterState()
                Log.d(TAG, "getBluetoothState: $state")
                result.success(state)
            }
            else -> {
                Log.w(TAG, "onMethodCall: notImplemented for '${call.method}'")
                result.notImplemented()
            }
        }
    }

    private fun startUnlock(keyHex: String, result: MethodChannel.Result) {
        Log.d(TAG, "startUnlock: begin, keyLen=${keyHex.length}")
        try {
            val digitalKey = DigitalKey(keyHex)
            Log.d(TAG, "startUnlock: DigitalKey created, isValid=${digitalKey.isValid}")
            val justinBle = JustinBle.getInstance(activity.applicationContext)
            Log.d(TAG, "startUnlock: JustinBle instance obtained, calling startUnlocking()")
            var deviceFound = false

            justinBle.startUnlocking(
                object : IJustinBleDigitalKeyRetriever {
                    override fun retrieve(params: DigitalKeyRetrieveParams): DigitalKey {
                        Log.d(TAG, "retrieve: SDK requested digital key")
                        return digitalKey
                    }
                },
                object : IJustinBleResultAndDiscoverCallbacks {
                    override fun onDeviceFound() {
                        deviceFound = true
                        Log.d(TAG, "onDeviceFound: BLE turnstile discovered")
                    }

                    override fun onSuccess(justinResult: com.saltosystems.justinmobile.sdk.model.JustinResult) {
                        val res = when (justinResult.opResult) {
                            OpResult.AUTH_SUCCESS_ACCESS_GRANTED -> "granted"
                            OpResult.AUTH_SUCCESS_ACCESS_REJECTED -> "rejected"
                            else -> "failure"
                        }
                        Log.d(TAG, "onSuccess: opResult=${justinResult.opResult} -> status=$res; deviceFound=$deviceFound")
                        result.success(
                            mapOf(
                                "status" to res,
                                "detail" to "opResult=${justinResult.opResult}; deviceFound=$deviceFound",
                            ),
                        )
                    }

                    override fun onFailure(ex: JustinException) {
                        val code = ex.errorCode
                        val res = when {
                            code == 410 -> "timeout"
                            code == 402 -> "noKey"
                            else -> "failure"
                        }
                        Log.e(TAG, "onFailure: errorCode=$code -> status=$res; deviceFound=$deviceFound; message=${ex.message}", ex)
                        val detail =
                            "errorCode=$code; deviceFound=$deviceFound; message=${ex.message ?: ""}"
                        result.success(mapOf("status" to res, "detail" to detail))
                    }
                },
                UnlockingParams.Builder()
                    .unlockingMode(UnlockingMode.STANDARD_MODE)
                    .technologyVersion(TechnologyVersion.V1)
                    .build()
            )
            Log.d(TAG, "startUnlock: startUnlocking() call returned (awaiting async callbacks)")
        } catch (e: JustinException) {
            val status = if (e.errorCode == 402) "noKey" else "failure"
            Log.e(TAG, "startUnlock: JustinException errorCode=${e.errorCode} -> status=$status", e)
            result.success(
                mapOf(
                    "status" to status,
                    "detail" to "errorCode=${e.errorCode}; deviceFound=false; message=${e.message ?: ""}",
                ),
            )
        } catch (e: Throwable) {
            // Catch Throwable (not just Exception) so NoClassDefFoundError / linkage
            // errors from the bare AAR are surfaced instead of crashing silently.
            Log.e(TAG, "startUnlock: unexpected ${e.javaClass.name}: ${e.message}", e)
            result.success(
                mapOf(
                    "status" to "failure",
                    "detail" to "deviceFound=false; message=${e.javaClass.name}: ${e.message ?: ""}",
                ),
            )
        }
    }

    // Raw BluetoothAdapter state, read directly rather than relying only on
    // permission_handler's on/off serviceStatus — this additionally
    // distinguishes the transitional STATE_TURNING_ON/STATE_TURNING_OFF
    // states (adapter exists but isn't settled yet) from a genuinely
    // missing adapter, so the Dart side can show "Bluetooth is starting up"
    // instead of a flat pass/fail.
    //
    // Returns one of BluetoothAdapter.STATE_OFF(10)/STATE_TURNING_ON(11)/
    // STATE_ON(12)/STATE_TURNING_OFF(13); -1 if no adapter is present on
    // this device; -3 if BLUETOOTH_CONNECT (required on API 31+ to read
    // adapter state) has not been granted.
    private fun getBluetoothAdapterState(): Int {
        return try {
            val manager = activity.applicationContext
                .getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            val adapter = manager?.adapter ?: return -1
            adapter.state
        } catch (e: SecurityException) {
            Log.w(TAG, "getBluetoothAdapterState: missing BLUETOOTH_CONNECT permission", e)
            -3
        } catch (e: Throwable) {
            Log.e(TAG, "getBluetoothAdapterState failed: ${e.javaClass.name}: ${e.message}", e)
            -1
        }
    }
}

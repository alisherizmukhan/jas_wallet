import Flutter
import SaltoJustINMobileSDK
import CoreBluetooth

class SaltoHandler: NSObject, FlutterPlugin, CBCentralManagerDelegate {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.jasaim/salto",
            binaryMessenger: registrar.messenger()
        )
        let instance = SaltoHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // Dedicated CBCentralManager purely for reading adapter state (poweredOn/
    // poweredOff/unauthorized/unsupported/resetting) — separate from
    // whatever CBCentralManager the SALTO SDK itself manages internally for
    // the actual unlock scan. Lazily created on first use, then reused.
    // CBCentralManagerOptionShowPowerAlertKey is disabled so merely checking
    // readiness never pops the system "Turn on Bluetooth" alert on its own —
    // that would be surprising for what is meant to be a passive read.
    private lazy var bluetoothManager: CBCentralManager = {
        CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionShowPowerAlertKey: false]
        )
    }()

    // Required by CBCentralManagerDelegate. No action needed here — state
    // is read on demand via the "getBluetoothState" method below rather
    // than pushed through this delegate callback.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {}

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startUnlock":
            guard let args = call.arguments as? [String: Any],
                  let keyHex = args["digitalKeyHex"] as? String,
                  !keyHex.isEmpty else {
                result("noKey")
                return
            }
            startUnlock(keyHex: keyHex, result: result)
        case "validateKey":
            guard let args = call.arguments as? [String: Any],
                  let keyHex = args["digitalKeyHex"] as? String,
                  !keyHex.isEmpty else {
                result(false)
                return
            }
            do {
                let _ = try DigitalKey(hexData: keyHex)
                // If DigitalKey initializes without throwing, the key is valid
                result(true)
            } catch {
                result(false)
            }
        case "getBluetoothState":
            // Raw CBManagerState so the Dart side can distinguish
            // poweredOff/unauthorized/unsupported/resetting rather than a
            // flat on/off — Dart owns the human-readable mapping so both
            // platforms share one mapping surface (see
            // SaltoPlatformChannel.bluetoothState).
            result(Int(bluetoothManager.state.rawValue))
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func startUnlock(keyHex: String, result: @escaping FlutterResult) {
        do {
            let key = try DigitalKey(hexData: keyHex)
            let params = UnlockingParams(
                unlockingMode: .standard,
                technologyVersion: .v1
            )
            var deviceFound = false

            JustinBle.sharedInstance.startUnlocking(
                digitalKeyBlock: { _ in key },
                deviceFound: {
                    deviceFound = true
                },
                success: { justinResult in
                    let res: String
                    let opResultCode = UInt8(truncatingIfNeeded: justinResult.getOpResult())
                    switch opResultCode {
                    case OpResult.accessGranted:
                        res = "granted"
                    case OpResult.accessRejected:
                        res = "rejected"
                    default:
                        res = "failure"
                    }
                    let detail = "opResult=\(justinResult.getOpResult()); deviceFound=\(deviceFound)"
                    DispatchQueue.main.async {
                        result([
                            "status": res,
                            "detail": detail
                        ])
                    }
                },
                failure: { error in
                    let err = error as NSError
                    let res: String
                    if err.domain.contains("timeout") || err.code == 410 {
                        res = "timeout"
                    } else if err.code == 402 {
                        res = "noKey"
                    } else {
                        res = "failure"
                    }
                    let detail =
                        "errorCode=\(err.code); domain=\(err.domain); deviceFound=\(deviceFound); message=\(err.localizedDescription)"
                    DispatchQueue.main.async {
                        result([
                            "status": res,
                            "detail": detail
                        ])
                    }
                },
                params: params
            )
        } catch {
            result([
                "status": "failure",
                "detail": "deviceFound=false; message=\(error.localizedDescription)"
            ])
        }
    }
}

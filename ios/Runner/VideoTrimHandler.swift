import Flutter
import AVFoundation

class VideoTrimHandler: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.jaswallet/video_trim",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(VideoTrimHandler(), channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "trimVideo" else {
            result(FlutterMethodNotImplemented)
            return
        }
        guard let args = call.arguments as? [String: Any],
              let inputPath  = args["inputPath"]  as? String,
              let outputPath = args["outputPath"] as? String,
              let startMs    = args["startMs"]    as? Int,
              let endMs      = args["endMs"]      as? Int else {
            result(FlutterError(
                code: "MISSING_ARG",
                message: "inputPath, outputPath, startMs, endMs are required",
                details: nil
            ))
            return
        }

        let inputURL  = URL(fileURLWithPath: inputPath)
        let outputURL = URL(fileURLWithPath: outputPath)

        // Remove existing output file if present
        try? FileManager.default.removeItem(at: outputURL)

        let asset = AVURLAsset(url: inputURL)
        guard let session = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetPassthrough
        ) else {
            result(FlutterError(
                code: "TRIM_FAILED",
                message: "Cannot create AVAssetExportSession",
                details: nil
            ))
            return
        }

        session.outputURL      = outputURL
        session.outputFileType = .mp4

        let start = CMTime(value: CMTimeValue(startMs), timescale: 1000)
        let end   = CMTime(value: CMTimeValue(endMs),   timescale: 1000)
        session.timeRange = CMTimeRange(start: start, end: end)

        session.exportAsynchronously {
            DispatchQueue.main.async {
                switch session.status {
                case .completed:
                    result(outputPath)
                default:
                    result(FlutterError(
                        code: "TRIM_FAILED",
                        message: session.error?.localizedDescription ?? "Export failed or cancelled",
                        details: nil
                    ))
                }
            }
        }
    }
}

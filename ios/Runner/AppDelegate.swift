import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase is initialized from Dart with lib/firebase_options.dart.
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = self.registrar(forPlugin: "SaltoHandler") {
      SaltoHandler.register(with: registrar)
    }
    if let registrar = self.registrar(forPlugin: "VideoTrimHandler") {
      VideoTrimHandler.register(with: registrar)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

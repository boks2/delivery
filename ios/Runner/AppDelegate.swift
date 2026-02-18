import UIKit
import Flutter
import GoogleMaps

@main // Pinalitan ang @UIApplicationMain para sa compatibility sa Xcode 16+
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps API Key
    GMSServices.provideAPIKey("AIzaSyDx_rDflI4S8ylXtpeWhblQC1NEJvPZJIQ")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
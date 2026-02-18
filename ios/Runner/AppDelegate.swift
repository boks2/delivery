import UIKit
import Flutter
import GoogleMaps // Import ito

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // I-paste dito ang Google Maps API Key mo
    GMSServices.provideAPIKey("AIzaSyDx_rDflI4S8ylXtpeWhblQC1NEJvPZJIQ")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
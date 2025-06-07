import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
       let dict = NSDictionary(contentsOfFile: path),
       let key = dict["GMSApiKey"] as? String {
        GMSServices.provideAPIKey(key)
    } else {
        print("ERROR: No se pudo cargar la GMSApiKey desde GoogleService-Info.plist")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

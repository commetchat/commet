import UIKit
import Flutter
import Firebase
import FirebaseCore
import flutter_local_notifications
import flutter_background_service_ios

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
	if #available(iOS 10.0, *) {
	  UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
	}
	FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }
    SwiftFlutterBackgroundServicePlugin.taskIdentifier = "dev.flutter.background.refresh"
//    FirebaseApp.configure()
//    GeneratedPluginRegistrant.register(with: self)
    
	return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

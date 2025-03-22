import Cocoa
import FlutterMacOS
import OSLog
import UserNotifications

@main
class AppDelegate: FlutterAppDelegate {
    let channelName : String = "PushNotificationChannel"
    var deviceToken : String = ""
    

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    override func applicationDidFinishLaunching(_ aNotification: Notification) {
        let controller : FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
        let pushNotificationChannel : FlutterMethodChannel = FlutterMethodChannel.init(name: self.channelName, binaryMessenger: controller.engine.binaryMessenger)
        
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        
        pushNotificationChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
                case "requestNotificationPermissions":
                    self?.requestNotificationPermissions(result: result)
                case "registerForPushNotifications":
                self?.registerForPushNotifications(application: aNotification.object as! NSApplication, result: result)
                case "retrieveDeviceToken":
                    self?.getDeviceToken(result: result)
                default:
                    result(FlutterMethodNotImplemented)
            }
        }
    
        super.applicationDidFinishLaunching(aNotification)
    }

    override func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        let token = tokenParts.joined()
        let controller : FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
        let pushNotificationChannel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.engine.binaryMessenger)
        self.deviceToken = token

        let logger = Logger()
        logger.notice("Registered for remote notifications with token: \(tokenParts)")

        pushNotificationChannel.invokeMethod("didRegister", arguments: token)
    }

    private func requestNotificationPermissions(result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                result(FlutterError(code: "PERMISSION_ERROR", message: "Failed to request permissions", details: error.localizedDescription))
                return
            }
            result(granted)
        }
    }

    private func registerForPushNotifications(application: NSApplication, result: @escaping FlutterResult) {
        application.registerForRemoteNotifications()
        result("Device Token registration initiated")
    }

    private func getDeviceToken(result: @escaping FlutterResult) {
        if(deviceToken.isEmpty) {
            result(FlutterError(code: "UNAVAILABLE", message: "Device token not available", details: nil))
        } else {
            result(deviceToken)
        }
    }
    
    override func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : Any]) {
        let controller : FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
        let pushNotificationChannel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.engine.binaryMessenger)
        pushNotificationChannel.invokeMethod("onBackgroundNotification", arguments: userInfo)
    }
    
    func usernotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .list, .badge, .sound])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
        
    }
    
    func usernotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let controller : FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
        let pushNotificationChannel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.engine.binaryMessenger)
        pushNotificationChannel.invokeMethod("onPushNotification", arguments: response.notification.request.content.userInfo)
        completionHandler()
    }
}

//
//  NotificationService.swift
//  servicer
//
//  Created by Brian Quirt on 3/12/25.
//

import UserNotifications
import Flutter

let channelName : String = "PushServiceChannel"

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        var flutterEngine : FlutterEngine? = FlutterEngine(name: "notification_service_engine", project: nil, allowHeadlessExecution: true)
        let decodeChannel = FlutterMethodChannel(name: channelName, binaryMessenger: flutterEngine!.binaryMessenger)

        if let bestAttemptContent = bestAttemptContent {
            var displayRoom : String = ""
            let roomId = bestAttemptContent.userInfo["room_id"] as! String
            if roomId.contains(":") {
                let roomCode = roomId.lastIndex(of:":")!
                displayRoom = String(roomId[roomCode...])
            } else {
                displayRoom = roomId
            }
            let unreadCount = bestAttemptContent.userInfo["unread_count"] as! Int

            bestAttemptContent.title = "\(displayRoom)"
            bestAttemptContent.subtitle = "\(unreadCount) new message(s)"
            bestAttemptContent.body = "Tap on this message to be taken to the room where it happened™️"

//            do {
//                flutterEngine!.run(withEntrypoint: "notificationMutationService")
//                DispatchQueue.main.sync() {
//                
//                    decodeChannel.invokeMethod("notificationReceived", arguments: bestAttemptContent.userInfo, result:{(result) -> () in
//                        let result = result as! NSDictionary
//                        
//                        bestAttemptContent.title = result["title"] as! String
//                        bestAttemptContent.subtitle = result["subtitle"] as! String
//                        bestAttemptContent.body = result["body"] as! String
//                    })
//               
//                }
//            } catch let error {
//                bestAttemptContent.subtitle = "Error: \(error)"
//            }
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            bestAttemptContent.title = "New Matrix Message"
            bestAttemptContent.body = "Tap on this message to be taken to the room where it happened™️"
            contentHandler(bestAttemptContent)
        }
    }

}

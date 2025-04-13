//
//  NotificationService.swift
//  servicer
//
//  Created by Brian Quirt on 3/12/25.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

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

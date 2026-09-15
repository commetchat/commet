/*
 * Copyright 2025 LiveKit
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Combine
import Foundation

enum DarwinNotification: String {
    case broadcastStarted = "iOS_BroadcastStarted"
    case broadcastStopped = "iOS_BroadcastStopped"
    case broadcastRequestStop = "iOS_BroadcastRequestStop"
}

@available(iOS 13.0, *)
final class DarwinNotificationCenter: @unchecked Sendable {
    public static let shared = DarwinNotificationCenter()
    private let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()

    func postNotification(_ name: DarwinNotification) {
        CFNotificationCenterPostNotification(notificationCenter,
                                             CFNotificationName(rawValue: name.rawValue as CFString),
                                             nil,
                                             nil,
                                             true)
    }
}

@available(iOS 13.0, *)
extension DarwinNotificationCenter {
    /// Returns a publisher that emits events when broadcasting notifications matching the given name.
    func publisher(for name: DarwinNotification) -> Publisher {
        Publisher(notificationCenter, name)
    }

    /// A publisher that emits notifications.
    struct Publisher: Combine.Publisher {
        typealias Output = DarwinNotification
        typealias Failure = Never

        private let name: DarwinNotification
        private let center: CFNotificationCenter?

        fileprivate init(_ center: CFNotificationCenter?, _ name: DarwinNotification) {
            self.name = name
            self.center = center
        }

        func receive<S>(
            subscriber: S
        ) where S: Subscriber, Never == S.Failure, DarwinNotification == S.Input {
            subscriber.receive(subscription: Subscription(subscriber, center, name))
        }
    }

    private class SubscriptionBase {
        let name: DarwinNotification
        let center: CFNotificationCenter?

        init(_ center: CFNotificationCenter?, _ name: DarwinNotification) {
            self.name = name
            self.center = center
        }

        static var callback: CFNotificationCallback = { _, observer, _, _, _ in
            guard let observer else { return }
            Unmanaged<SubscriptionBase>
                .fromOpaque(observer)
                .takeUnretainedValue()
                .notifySubscriber()
        }

        func notifySubscriber() {
            // Overridden by generic subclass to call specific subscriber's
            // receive method. This allows forming a C function pointer to the callback.
        }
    }

    private class Subscription<S: Subscriber>: SubscriptionBase, Combine.Subscription where S.Input == DarwinNotification, S.Failure == Never {
        private var subscriber: S?

        init(_ subscriber: S, _ center: CFNotificationCenter?, _ name: DarwinNotification) {
            self.subscriber = subscriber
            super.init(center, name)
            addObserver()
        }

        func request(_: Subscribers.Demand) {}

        private var opaqueSelf: UnsafeRawPointer {
            UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
        }

        private func addObserver() {
            CFNotificationCenterAddObserver(center,
                                            opaqueSelf,
                                            Self.callback,
                                            name.rawValue as CFString,
                                            nil,
                                            .deliverImmediately)
        }

        private func removeObserver() {
            guard subscriber != nil else { return }
            CFNotificationCenterRemoveObserver(center,
                                               opaqueSelf,
                                               CFNotificationName(name.rawValue as CFString),
                                               nil)
            subscriber = nil
        }

        override func notifySubscriber() {
            _ = subscriber?.receive(name)
        }

        func cancel() {
            removeObserver()
        }

        deinit {
            removeObserver()
        }
    }
}

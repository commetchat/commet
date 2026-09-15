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

import Foundation

/// A property wrapper type that reflects a value from a bundle's info dictionary.
@propertyWrapper
struct BundleInfo<Value>: Sendable {
    private let key: String
    private let bundle: Bundle

    init(_ key: String, bundle: Bundle = .main) {
        self.key = key
        self.bundle = bundle
    }

    var wrappedValue: Value? {
        guard let value = bundle.infoDictionary?[key] as? Value else { return nil }
        return value
    }
}

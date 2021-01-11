//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

import Foundation
import XPC
import CodableXPC

public struct Message<T: Codable>: Codable {
    enum CodingKeys: String, CodingKey {
        case interfaceIdentifier = "__extra__identifier"
        case value = "__extra__value"
    }
    public let interfaceIdentifier: InterfaceIdentifier
    public let value: T
    public init<I: Interface>(interface: I.Type,
                              value: T) {
        interfaceIdentifier = interface.identifier
        self.value = value
    }
    public init(interfaceIdentifier: InterfaceIdentifier,
                value: T) {
        self.interfaceIdentifier = interfaceIdentifier
        self.value = value
    }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        interfaceIdentifier = try values.decode(InterfaceIdentifier.self,
                                                forKey: .interfaceIdentifier)
        value = try values.decode(T.self,
                                  forKey: .value)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(interfaceIdentifier,
                             forKey: .interfaceIdentifier)
        try container.encode(value,
                             forKey: .value)
    }
}

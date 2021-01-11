//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

import Foundation
import XPC
import CodableXPC

enum ExtraType {
    case activity(xpc_activity_t) // XPC_TYPE_ACTIVITY
    case array  // XPC_TYPE_ARRAY
    case bool(Bool) // XPC_TYPE_BOOL
    case connection(Connection) // XPC_TYPE_CONNECTION
    case data // XPC_TYPE_DATA
    case date(Date) // XPC_TYPE_DATE
    case dictionary //  // XPC_TYPE_DICTIONARY
    case double(Double) // XPC_TYPE_DOUBLE
    case endpoint(Endpoint) // XPC_TYPE_ENDPOINT
    case error(String) //  // XPC_TYPE_ERROR
    case fileHandle(FileHandle) // XPC_TYPE_FD
    case int(Int) // XPC_TYPE_INT64
    case null // XPC_TYPE_NULL
    case sharedMemory // XPC_TYPE_SHMEM
    case string(String) // XPC_TYPE_STRING
    case uint(UInt) // XPC_TYPE_UINT64
    case uuid(UUID) // XPC_TYPE_UUID

    case unknown
}

extension xpc_object_t {
    func integer(for key: String) -> Int64? {
        assert(xpc_get_type(self) == XPC_TYPE_DICTIONARY)
        return xpc_dictionary_get_int64(self,
                                        key)
    }
    func unsignedInteger(for key: String) -> UInt64? {
        assert(xpc_get_type(self) == XPC_TYPE_DICTIONARY)
        return xpc_dictionary_get_uint64(self,
                                         key)
    }
    func dictionary(for key: String) -> xpc_object_t? {
        assert(xpc_get_type(self) == XPC_TYPE_DICTIONARY)
        return xpc_dictionary_get_dictionary(self,
                                             key)
    }
    func data(for key: String) -> Data? {
        assert(xpc_get_type(self) == XPC_TYPE_DICTIONARY)
        var count: Int = 0
        guard let bytes = xpc_dictionary_get_data(self, key, &count) else {
            return nil
        }
        return Data(bytes: bytes,
                    count: count)
    }
    func bool(for key: String) -> Bool {
        assert(xpc_get_type(self) == XPC_TYPE_DICTIONARY)
        return xpc_dictionary_get_bool(self,
                                       key)
    }
    func uuid(for key: String) -> UUID? {
        guard let bytes = xpc_dictionary_get_uuid(self,
                                                  key) else {
            return nil
        }
        return NSUUID(uuidBytes: bytes) as UUID
    }
    func getType() throws -> ExtraType {
        let type = xpc_get_type(self)
        switch type {
        case XPC_TYPE_ACTIVITY:
            return .activity(self)
        case XPC_TYPE_ARRAY:
            return .array
        case XPC_TYPE_BOOL:
            return .bool(xpc_bool_get_value(self))
        case XPC_TYPE_CONNECTION:
            return .connection(Connection(connection: self))
        case XPC_TYPE_DATA:
            return .data
        case XPC_TYPE_DATE:
            return .date(Date(timeIntervalSince1970: TimeInterval(xpc_date_get_value(self)) / TimeInterval(NSEC_PER_SEC)))
        case XPC_TYPE_DICTIONARY:
            return .dictionary
        case XPC_TYPE_DOUBLE:
            return .double(xpc_double_get_value(self))
        case XPC_TYPE_ENDPOINT:
            return .endpoint(Endpoint(endpoint: self))
        case XPC_TYPE_ERROR:
            return .error(String(cString: xpc_copy_description(self),
                                 encoding: .utf8) ?? "description unavailable")
        case XPC_TYPE_FD:
            return .fileHandle(FileHandle(fileDescriptor: xpc_fd_dup(self),
                                          closeOnDealloc: true))
        case XPC_TYPE_INT64:
            return .int(Int(xpc_int64_get_value(self)))
        case XPC_TYPE_NULL:
            return .null
        case XPC_TYPE_SHMEM:
            return .sharedMemory
        case XPC_TYPE_STRING:
            guard let cString = xpc_string_get_string_ptr(self) else {
                fatalError()
            }
            return .string(String(cString: cString))
        case XPC_TYPE_UINT64:
            return .uint(UInt(xpc_uint64_get_value(self)))
        case XPC_TYPE_UUID:
            guard let bytes = xpc_uuid_get_bytes(self) else {
                fatalError()
            }
            return .uuid(NSUUID(uuidBytes: bytes) as UUID)
        default:
            return .unknown
        }
    }
    func fromXPC<T: Codable>(_ type: T.Type) throws -> T {
        try XPCDecoder.decode(type,
                              message: self)
    }
}

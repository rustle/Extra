//
//  Copyright © 2021 Doug Russell. All rights reserved.
//

@propertyWrapper
public struct Atomic<T> {
    private var storage: T
    private let lock = UnfairLock()
    public init(wrappedValue: T) {
        self.storage = wrappedValue
    }
    public var wrappedValue: T {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storage
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            storage = newValue
        }
    }
}

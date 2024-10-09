import Foundation

public typealias StoreListenerToken = String

public protocol Store: AnyObject {}

private var EventEmitterObjectKey: UInt8 = 0

extension Store {
    private var eventEmitter: EventEmitter {
        guard let eventEmitter = objc_getAssociatedObject(self, &EventEmitterObjectKey) as? EventEmitter else {
            let eventEmitter = DefaultEventEmitter()
            objc_setAssociatedObject(self, &EventEmitterObjectKey, eventEmitter, .OBJC_ASSOCIATION_RETAIN)
            return eventEmitter
        }
        return eventEmitter
    }

    public func subscribe(
        handler: @escaping () -> ()
    ) -> StoreListenerToken {
        eventEmitter.subscribe(
            store: self,
            handler: handler
        )
    }

    public func unsubscribe(
        listenerToken: StoreListenerToken
    ) {
        eventEmitter.unsubscribe(
            store: self,
            listenerToken: listenerToken
        )
    }

    public func unsubscribeAll() {
        eventEmitter.unsubscribe(store: self)
    }

    public func emitChange()  {
        eventEmitter.emitChange(store: self)
    }
}

public protocol EventEmitter {
    func subscribe(
        store: any Store,
        handler: @escaping () -> ()
    ) -> String
    func unsubscribe(
        store: any Store
    )
    func unsubscribe(
        store: any Store,
        listenerToken: StoreListenerToken
    )
    func emitChange(
        store: any Store
    )
}

public class DefaultEventEmitter: EventEmitter {
    private var eventListeners: [StoreListenerToken: EventListener] = [:]

    public init() {}

    deinit {
        eventListeners.removeAll()
    }

    public func subscribe(
        store: any Store,
        handler: @escaping () -> ()
    ) -> StoreListenerToken {
        let nextListenerToken = UUID().uuidString
        eventListeners[nextListenerToken] = EventListener(
            store: store,
            handler: handler
        )
        return nextListenerToken
    }

    public func unsubscribe(
        store: any Store
    ) {
        eventListeners.forEach { (token, listener) -> () in
            if (listener.store === store) {
                eventListeners.removeValue(forKey: token)
            }
        }
    }

    public func unsubscribe(
        store: any Store,
        listenerToken: StoreListenerToken
    ) {
        eventListeners.removeValue(forKey: listenerToken)
    }

    public func emitChange(
        store: any Store
    ) {
        eventListeners.forEach { (_, listener) -> () in
            if (listener.store === store) { listener.handler() }
        }
    }
}

struct EventListener {
    let store: any Store
    let handler: () -> ()
    
    init(store: any Store, handler: @escaping () -> ()) {
        self.store = store
        self.handler = handler
    }
}

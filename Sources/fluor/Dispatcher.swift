import Foundation

public typealias DispatchToken = String

public protocol Dispatcher {
    func dispatch<T: Action>(
        _ action: T,
        result: Result<T.Payload, T.Failure>
    )
    
    func register<T: Action>(
        _ type: T.Type,
        handler: @escaping (Result<T.Payload, T.Failure>) -> ()
    ) -> DispatchToken
        
    func unregister(_ dispatchToken: DispatchToken)
        
    func waitFor<T: Action>(
        dispatchTokens: [DispatchToken],
        type: T.Type,
        result: Result<T.Payload, T.Failure>
    )
}

public class DefaultDispatcher: Dispatcher {
    internal enum Status {
        case waiting
        case pending
        case handled
    }

    private var callbacks: [DispatchToken: AnyObject] = [:]

    public init() {}

    deinit {
        callbacks.removeAll()
    }

    public func dispatch<T: Action>(_ action: T, result: Result<T.Payload, T.Failure>) {
        dispatch(type(of: action), result: result)
    }
    
    public func register<T: Action>(_ type: T.Type, handler: @escaping (Result<T.Payload, T.Failure>) -> Void) -> DispatchToken {
        let nextDispatchToken = UUID().uuidString
        callbacks[nextDispatchToken] = DispatchCallback<T>(type: type, handler: handler)
        return nextDispatchToken
    }
    
    public func unregister(_ dispatchToken: DispatchToken) {
        callbacks.removeValue(forKey: dispatchToken)
    }
    
    public func waitFor<T: Action>(dispatchTokens: [DispatchToken], type: T.Type, result: Result<T.Payload, T.Failure>) {
        for dispatchToken in dispatchTokens {
            guard let callback = callbacks[dispatchToken] as? DispatchCallback<T> else { continue }
            switch callback.status {
            case .handled:
                continue
            case .pending:
                // Circular dependency detected while
                continue
            default:
                invokeCallback(dispatchToken, type: type, result: result)
            }
        }
    }
    
    private func dispatch<T: Action>(_ type: T.Type, result: Result<T.Payload, T.Failure>) {
        objc_sync_enter(self)
        
        startDispatching(type)
        for dispatchToken in callbacks.keys {
            invokeCallback(dispatchToken, type: type, result: result)
        }
        
        objc_sync_exit(self)
    }
    
    private func startDispatching<T: Action>(_ type: T.Type) {
        for (dispatchToken, _) in callbacks {
            guard let callback = callbacks[dispatchToken] as? DispatchCallback<T> else { continue }
            callback.status = .waiting
        }
    }
    
    private func invokeCallback<T: Action>(_ dispatchToken: DispatchToken, type: T.Type, result: Result<T.Payload, T.Failure>) {
        guard let callback = callbacks[dispatchToken] as? DispatchCallback<T> else { return }
        guard callback.status == .waiting else { return }
        
        callback.status = .pending
        callback.handler(result)
        callback.status = .handled
    }
}

private class DispatchCallback<T: Action> {
    let type: T.Type
    let handler: (Result<T.Payload, T.Failure>) -> ()
    var status = DefaultDispatcher.Status.waiting

    init(type: T.Type, handler: @escaping (Result<T.Payload, T.Failure>) -> ()) {
        self.type = type
        self.handler = handler
    }
}

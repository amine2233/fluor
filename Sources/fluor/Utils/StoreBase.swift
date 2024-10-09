import Foundation

public class StoreBase: Store {
    private var dispatchTokens: [DispatchToken] = []

    public init() {}

    public func register<T: Action>(_ type: T.Type, handler: @escaping (Result<T.Payload, T.Failure>) -> ()) -> DispatchToken {
        let dispatchToken = ActionCreator.dispatcher.register(type) { (result) -> () in
            handler(result)
        }
        dispatchTokens.append(dispatchToken)
        return dispatchToken
    }

    public func unregister() {
        dispatchTokens.forEach { (dispatchToken) -> () in
            ActionCreator.dispatcher.unregister(dispatchToken)
        }
    }
}

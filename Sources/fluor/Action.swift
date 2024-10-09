import Foundation

public protocol Action {
    associatedtype Payload
    associatedtype Failure: Error
    func invoke(dispatcher: Dispatcher)
}

public class ActionCreator {
    private static let internalDefaultDispatcher = DefaultDispatcher()
    
    public class var dispatcher: Dispatcher {
        return internalDefaultDispatcher
    }

    public class func invoke<T: Action>(action: T) {
        action.invoke(dispatcher: self.dispatcher)
    }
}

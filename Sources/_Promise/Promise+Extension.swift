import Foundation

extension PromiseDefault {

    @discardableResult
    public func done(
        on: DispatchQueue = DispatchQueue.global(),
        _ onSuccess: @escaping SuccessCompletion
    ) -> PromiseDefault {
        return PromiseDefault(operation: { resolver in
            self.execute(completion: { (result) in
                switch result {
                case .success(let value):
                    on.async {
                        onSuccess(value)
                    }
                case .failure:
                    break
                }
                resolver(result)
            })
        })
    }

    @discardableResult
    public func `catch`(
        on: DispatchQueue = DispatchQueue.global(),
        _ onFailure: @escaping FailureCompletion
    ) -> PromiseDefault {
        return PromiseDefault(operation: { resolver in
            self.execute(completion: { (result) in
                switch result {
                case .success:
                    break
                case .failure(let failure):
                    on.async {
                        onFailure(failure)
                    }
                }
                resolver(result)
            })
        })
    }

    /**
    Chain two depending futures providing a function that gets the erro of this future as parameter
    and then creates new one

    - Parameters:
    - transform: function that will generate a new `Future` by passing the value of this Future
    - value: the value of this Future

    - Returns: New chained Future
    */
    public func whenFailure<F: Error>(
        _ transform: @escaping (_ failure: E) -> PromiseDefault<T, F>
    ) -> PromiseDefault<T, F> {
        return PromiseDefault<T, F>(operation: { completion in
            self.execute(onSuccess: { value in
                completion(.success(value))
            }, onFailure: { error in
                transform(error).execute(completion: completion)
            })
        })
    }
}

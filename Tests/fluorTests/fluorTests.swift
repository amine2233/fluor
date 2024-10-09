import XCTest
@testable import Fluor
import _Promise

final class fluorTests: XCTestCase {
    struct Todo {
        let title: String
    }

    struct TodoAction {
        struct Create: Action {
            typealias Failure = Never
            typealias Payload = Todo
            func invoke(dispatcher: Dispatcher) {
                let todo = Todo(title: "New ToDo")
                dispatcher.dispatch(self, result: Result(value: todo))
            }
        }
        
        struct List: Action {
            typealias Failure = Never
            typealias Payload = [Todo]
            func invoke(dispatcher: Dispatcher) {
                let todos = [Todo(title: "any")]
                dispatcher.dispatch(self, result: Result(value: todos))
            }
        }
    }

    final class TodoStore: Store {
        private(set) var todos = [Todo]()
        var dispatcher: DispatchToken?

        init() {
            setup()
        }
        
        private func setup() {
            self.dispatcher = ActionCreator.dispatcher.register(TodoAction.List.self) {[weak self] (result) in
                guard let self else { return }
                switch result {
                case .success(let value):
                    self.todos.append(contentsOf: value)
                    self.emitChange()
                case .failure(let error):
                    NSLog("error \(error)")
                    break;
                }
            }
        }
    }
    
    func testExample() throws {
        let todoStore = TodoStore()
        let _ = todoStore.subscribe { () -> () in
            for todo in todoStore.todos {
                print(todo.title)
            }
        }
        ActionCreator.invoke(action: TodoAction.List())
    }
}

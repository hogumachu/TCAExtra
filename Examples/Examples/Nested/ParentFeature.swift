import Foundation
import TCAExtra

@FeatureReducer
struct ParentFeature {
  struct State: Equatable {
    @Presents var child: ChildFeature.State?
    var modelCount: Int { Int(text) ?? 0 }
    var models: IdentifiedArrayOf<Model> {
      .init(uniqueElements: (0..<modelCount).map { _ in Model(id: .init()) })
    }
    var text = "10"
  }
  
  struct Model: Equatable, Identifiable {
    let id: UUID
  }
  
  enum Action: BindableAction {
    enum Child {
      case child(PresentationAction<ChildFeature.Action>)
    }
    
    enum Local {
      case removeChild
    }
    
    enum View {
      case detailTapped(UUID)
    }
  }
  
  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(\.text):
        print("Text Updated: \(state.text)")
        return .none
        
      case let .child(action):
        return child(&state, action)
        
      case let .local(action):
        return local(&state, action)
        
      case let .view(action):
        return view(&state, action)
        
      default:
        return .none
      }
    }
    .ifLet(\.$child, action: \.child.child) {
      ChildFeature()
    }
  }
  
  func child(_ state: inout State, _ action: Action.Child) -> Effect<Action> {
    switch action {
    case let .child(action):
      guard case let .presented(.delegate(action)) = action else {
        return .none
      }
      switch action {
      case .closeTapped:
        return .send(.local(.removeChild))
      }
    }
  }
  
  func local(_ state: inout State, _ action: Action.Local) -> Effect<Action> {
    switch action {
    case .removeChild:
      state.child = nil
      return .none
    }
  }
  
  func view(_ state: inout State, _ action: Action.View) -> Effect<Action> {
    switch action {
    case let .detailTapped(id):
      state.child = .init(id: id)
      return .none
    }
  }
}

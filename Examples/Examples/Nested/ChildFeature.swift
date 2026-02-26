import Foundation
import TCAExtra

@FeatureReducer
struct ChildFeature {
  struct State: Equatable {
    let id: UUID
  }
  
  enum Action {
    enum Delegate {
      case closeTapped
    }
    
    enum View {
      case closeTapped
    }
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .view(.closeTapped):
        return .send(.delegate(.closeTapped))
        
      default:
        return .none
      }
    }
  }
}

import TCAExtra

@FeatureReducer
struct CounterFeature {
  struct State: Equatable {
    var count = 0
  }

  enum Action {
    enum View {
      case incrementTapped
      case decrementTapped
    }
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .view(.incrementTapped):
        state.count += 1
        return .none
      case .view(.decrementTapped):
        state.count -= 1
        return .none
      case .child, .delegate, .external, .local:
        return .none
      }
    }
  }
}

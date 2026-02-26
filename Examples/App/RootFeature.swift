import SwiftUI
import TCAExtra

enum Apps: String, CaseIterable, Equatable, Identifiable {
  case counter
  case nested
  
  var id: String { rawValue }
  var title: String {
    rawValue.prefix(1).capitalized + rawValue.dropFirst()
  }
}

@FeatureReducer
struct RootFeature {
  enum State: Equatable {
    case counter(CounterFeature.State)
    case nested(ParentFeature.State)
    
    init() {
      self = .counter(.init())
    }
  }
  
  enum Action {
    enum Child {
      case counter(CounterFeature.Action)
      case nested(ParentFeature.Action)
    }
    
    enum View {
      case appTapped(Apps)
    }
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .view(action):
        return view(&state, action)
        
      default:
        return .none
      }
    }
    .ifCaseLet(\.counter, action: \.child.counter) {
      CounterFeature()
    }
    .ifCaseLet(\.nested, action: \.child.nested) {
      ParentFeature()
    }
  }
  
  func view(_ state: inout State, _ action: Action.View) -> Effect<Action> {
    switch action {
    case let .appTapped(app):
      switch app {
      case .counter:
        state = .counter(.init())
        return .none
        
      case .nested:
        state = .nested(.init())
        return .none
      }
    }
  }
}

@ViewAction(for: RootFeature.self)
struct RootView: View {
  let store: StoreOf<RootFeature>
  
  var body: some View {
    WithPerceptionTracking {
      VStack(spacing: .zero) {
        ScrollView(.horizontal) {
          HStack {
            ForEach(Apps.allCases) { app in
              Button {
                send(.appTapped(app))
              } label: {
                Text(app.title)
                  .font(.caption)
              }
              .buttonStyle(.borderedProminent)
            }
          }
        }
        
        Group {
          switch store.state {
          case .counter:
            if let store = store.scope(state: \.counter, action: \.child.counter) {
              CounterView(store: store)
            }
            
          case .nested:
            if let store = store.scope(state: \.nested, action: \.child.nested) {
              ParentView(store: store)
            }
          }
        }
      }
    }
  }
}

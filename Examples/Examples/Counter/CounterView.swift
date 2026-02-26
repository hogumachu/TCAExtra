import SwiftUI
import TCAExtra

struct CounterView: View {
  let store: StoreOf<CounterFeature>
  
  var body: some View {
    WithPerceptionTracking {
      VStack {
        Text("\(store.count)")
          .font(.title)
          .monospacedDigit()
        
        HStack {
          Button("-") {
            store.send(.view(.decrementTapped))
          }
          .buttonStyle(.borderedProminent)
          
          Button("+") {
            store.send(.view(.incrementTapped))
          }
          .buttonStyle(.borderedProminent)
        }
      }
    }
  }
}

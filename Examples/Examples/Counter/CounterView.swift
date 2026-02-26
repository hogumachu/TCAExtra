import SwiftUI
import TCAExtra

@ViewAction(for: CounterFeature.self)
struct CounterView: View {
  let store: StoreOf<CounterFeature>
  
  var body: some View {
    WithPerceptionTracking {
      VStack {
        Spacer()
        
        Text("\(store.count)")
          .font(.title)
          .monospacedDigit()
        
        HStack {
          Button("-") {
            send(.decrementTapped)
          }
          .buttonStyle(.borderedProminent)
          
          Button("+") {
            send(.incrementTapped)
          }
          .buttonStyle(.borderedProminent)
        }
        
        Spacer()
      }
    }
  }
}

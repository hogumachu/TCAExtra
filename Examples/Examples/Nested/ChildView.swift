import SwiftUI
import TCAExtra

@ViewAction(for: ChildFeature.self)
struct ChildView: View {
  let store: StoreOf<ChildFeature>
  
  var body: some View {
    VStack {
      HStack {
        Button {
          send(.closeTapped)
        } label: {
          Image(systemName: "xmark")
        }
        
        Spacer()
      }
      
      Spacer()
      
      Text(store.id.uuidString)
        .font(.title)
      
      Spacer()
    }
  }
}

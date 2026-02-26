import SwiftUI
import TCAExtra

@ViewAction(for: ParentFeature.self)
struct ParentView: View {
  @Perception.Bindable var store: StoreOf<ParentFeature>
  
  var body: some View {
    WithPerceptionTracking {
      ScrollView {
        TextField("Model Count", text: $store.text)
        
        VStack {
          ForEach(store.models) { model in
            Button {
              send(.detailTapped(model.id))
            } label: {
              Text("Model\n\(model.id.uuidString)")
                .frame(maxWidth: .infinity)
                .padding()
                .lineLimit(2)
                .background {
                  RoundedRectangle(cornerRadius: 16)
                    .fill(.gray.opacity(0.3))
                }
            }
          }
        }
        .padding()
      }
      .fullScreenCover(
        item: $store.scope(state: \.child, action: \.child.child)
      ) {
        ChildView(store: $0)
      }
    }
  }
}

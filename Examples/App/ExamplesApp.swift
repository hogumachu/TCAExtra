import SwiftUI
import TCAExtra

@main
struct ExamplesApp: App {
  var body: some Scene {
    WindowGroup {
      CounterView(
        store: .init(initialState: CounterFeature.State()) {
          CounterFeature()
        }
      )
    }
  }
}

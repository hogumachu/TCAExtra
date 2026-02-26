import SwiftUI
import TCAExtra

@main
struct ExamplesApp: App {
  var body: some Scene {
    WindowGroup {
      RootView(
        store: .init(initialState: RootFeature.State()) {
          RootFeature()
        }
      )
    }
  }
}

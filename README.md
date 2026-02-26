# TCAExtra

TCAExtra is a small extension for [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) focused on one pain point: `Action` enums grow fast. Even when reducers are split into smaller units, action shapes often still become large and repetitive. TCAExtra provides a consistent `Action` taxonomy plus macros to reduce boilerplate.

## Why TCAExtra?

In real-world TCA features, actions are often split into recurring groups:

- `View`: user intent from UI interactions
- `Delegate`: upward communication to parent/coordinator
- `Local`: internal mutations/workflow events
- `External`: input from outside the feature boundary (system/deep link/push/etc.)
- `Child`: child feature routing/bridging actions

This structure improves readability, but writing it repeatedly across features is tedious. TCAExtra standardizes this pattern.

## Why `@FeatureReducer` is useful immediately

Yes, GitHub supports added/removed style blocks with `+`/`-` via fenced `diff` code blocks.

```diff
+ @FeatureReducer
  struct Feature {
-   enum State {}
-   enum Action {}
+   @CasePathable @dynamicMemberLookup @ObservableState
+   enum State {}
+   @FeatureAction
+   enum Action {}
+   @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
    var body: some ReducerOf<Self> {
      EmptyReducer()
    }
  }
+ extension Feature: ComposableArchitecture.Reducer {}
```

In short, `@FeatureReducer` removes repeated setup by auto-injecting reducer conformance and common state/action annotations.

## Why `@FeatureAction` is useful immediately

If you start with:

```swift
@FeatureAction
enum Action {
  enum View {
    case incrementTapped
    case decrementTapped
  }
}
```

it expands conceptually like this:

```diff
+ @FeatureAction
-  enum Action {
-   enum View {
-     case incrementTapped
-     case decrementTapped
-   }
+   // synthesized members:
+   // @CasePathable enum Child {}
+   // @CasePathable enum Delegate {}
+   // @CasePathable enum External {}
+   // @CasePathable enum Local {}
+   // @CasePathable enum View { case incrementTapped, case decrementTapped }
+   // case child(Child)
+   // case delegate(Delegate)
+   // case external(External)
+   // case local(Local)
+   // case view(View)
+   // struct AllCasePaths { child, delegate, external, local, view }
+   // static var allCasePaths: AllCasePaths
  }
+ // synthesized extension:
+ // extension Action: ViewAction, CasePathable, CasePathIterable {}
```

## Action Taxonomy

TCAExtra formalizes the above buckets so each feature can use the same mental model.

- `Action.View`: UI-triggered intents
- `Action.Delegate`: parent-facing outputs
- `Action.Local`: internal-only events and mutations
- `Action.External`: outside-driven events
- `Action.Child`: child feature action routing

## Core Idea: `FeatureAction`

[FeatureAction.swift](Sources/TCAExtra/FeatureAction.swift) defines the core protocol that models this action shape:

- `child(_:)`
- `delegate(_:)`
- `external(_:)`
- `local(_:)`
- `view(_:)`

The goal is consistency, discoverability, and cleaner reducer code organization.

## Macros

### `@FeatureAction`

Attach to an `Action` enum to synthesize the standard action cases and nested domains.

High-level behavior:

- Adds cases: `.child`, `.delegate`, `.external`, `.local`, `.view`
- Adds missing nested enums: `Child`, `Delegate`, `External`, `Local`, `View`
- If `Action` conforms to `BindableAction`, also adds `.binding(BindingAction<State>)`
- Adds conformances used by TCA/case paths (`ViewAction`, `CasePathable`, `CasePathIterable`)
- Adds case-path helpers for ergonomic routing

### `@FeatureReducer`

Attach to a feature `struct` to reduce repeated reducer setup.

High-level behavior:

- Adds `Reducer` conformance when needed
- Adds common attributes for nested `State`/`Action`
- Automatically applies `@ObservableState` to nested `State` declarations
- Applies `@FeatureAction` to `Action` when appropriate
- Adds `@ReducerBuilder` to `body` when needed
- Synthesizes `extension Feature: Reducer` when missing

## Installation

Add TCAExtra as a Swift Package dependency:

```swift
// Package.swift
.dependencies: [
  .package(url: "https://github.com/hogumachu/TCAExtra.git", from: "0.1.0")
]
```

Then include the product in your target dependencies:

```swift
.target(
  name: "YourFeature",
  dependencies: [
    .product(name: "TCAExtra", package: "TCAExtra")
  ]
)
```

## Usage

### Before (manual, repetitive)

```swift
import ComposableArchitecture

@Reducer
struct CounterFeature {
  @ObservableState
  struct State: Equatable {
    var count = 0
  }

  enum Action: ViewAction {
    enum View {
      case incrementTapped
      case decrementTapped
    }
    enum Delegate {}
    enum Local {}
    enum External {}
    enum Child {}

    case view(View)
    case delegate(Delegate)
    case local(Local)
    case external(External)
    case child(Child)
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
```

### After (with macros)

```swift
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
```

### BindableAction support

`@FeatureAction` detects `BindableAction` and synthesizes `.binding` automatically:

```swift
import TCAExtra

@FeatureReducer
struct ProfileFeature {
  struct State: Equatable {
    var name = ""
  }

  enum Action: BindableAction {
    enum View {
      case saveTapped
    }
  }

  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(\.name):
        return .none
      case .view(.saveTapped):
        return .none
      case .child, .delegate, .external, .local:
        return .none
      }
    }
  }
}
```

## Example: Parent/Child flow

A common pattern is a child sending a delegate action upward, and the parent converting it into local work:

```swift
// ChildFeature
case .view(.closeTapped):
  return .send(.delegate(.closeTapped))

// ParentFeature
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
```

See working examples in:

- `Examples/Examples/Counter/CounterFeature.swift`
- `Examples/Examples/Nested/ParentFeature.swift`
- `Examples/Examples/Nested/ChildFeature.swift`

## What gets generated (high level)

- Standard action cases for the five domains
- Optional `.binding` action when `Action: BindableAction`
- Missing nested action enums
- Relevant protocol conformances for routing and case-path usage
- Reducer-related annotations/conformance conveniences via `@FeatureReducer`
- Automatic `@ObservableState` application to nested `State`

## License

MIT. See [LICENSE](LICENSE).

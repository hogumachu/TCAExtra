#if canImport(MacroTesting)
  import MacroTesting
  import SwiftSyntaxMacros
  import TCAExtraMacros
  import XCTest

  final class FeatureReducerMacroTests: XCTestCase {
    override func invokeTest() {
      withMacroTesting(
        macros: [FeatureReducerMacro.self]
      ) {
        super.invokeTest()
      }
    }

    func testStructReducerBasics() {
      assertMacro {
        """
        @FeatureReducer
        struct Feature {
          enum State {}
          enum Action {}
          var body: some ReducerOf<Self> {
            EmptyReducer()
          }
        }
        """
      } expansion: {
        """
        struct Feature {
          @CasePathable @dynamicMemberLookup @ObservableState
          enum State {}
          @FeatureAction
          enum Action {}
          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
            EmptyReducer()
          }
        }

        extension Feature: ComposableArchitecture.Reducer {
        }
        """
      }
    }

    func testKeepsExistingFeatureActionOnAction() {
      assertMacro {
        """
        @FeatureReducer
        struct Feature {
          enum State {}
          @FeatureAction
          enum Action {}
          var body: some ReducerOf<Self> {
            EmptyReducer()
          }
        }
        """
      } expansion: {
        """
        struct Feature {
          @CasePathable @dynamicMemberLookup @ObservableState
          enum State {}
          @FeatureAction
          enum Action {}
          @ComposableArchitecture.ReducerBuilder<Self.State, Self.Action>
          var body: some ReducerOf<Self> {
            EmptyReducer()
          }
        }

        extension Feature: ComposableArchitecture.Reducer {
        }
        """
      }
    }

    func testNoDuplicateConformanceOrAttributes() {
      assertMacro {
        """
        @FeatureReducer
        struct Feature: Reducer {
          @CasePathable
          @dynamicMemberLookup
          @ObservableState
          enum State {}
          @FeatureAction
          enum Action {}
          @ReducerBuilder<State, Action>
          var body: some ReducerOf<Self> {
            EmptyReducer()
          }
        }
        """
      } expansion: {
        """
        struct Feature: Reducer {
          @CasePathable
          @dynamicMemberLookup
          @ObservableState
          enum State {}
          @FeatureAction
          enum Action {}
          @ReducerBuilder<State, Action>
          var body: some ReducerOf<Self> {
            EmptyReducer()
          }
        }
        """
      }
    }

    func testAddsFeatureActionToBindableActionEnum() {
      assertMacro {
        """
        @FeatureReducer
        struct Feature {
          struct State {}
          enum Action: BindableAction {}
        }
        """
      } expansion: {
        """
        struct Feature {
          @ObservableState
          struct State {}
          @FeatureAction
          enum Action: BindableAction {}
        }

        extension Feature: ComposableArchitecture.Reducer {
        }
        """
      }
    }

    func testRequiresStruct() {
      assertMacro {
        """
        @FeatureReducer
        enum Destination {}
        """
      } diagnostics: {
        """
        @FeatureReducer
        ╰─ 🛑 '@FeatureReducer' can only be applied to struct types
        enum Destination {}
        """
      }
    }
  }
#endif

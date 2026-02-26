#if canImport(MacroTesting)
  import MacroTesting
  import SwiftSyntaxMacros
  import TCAExtraMacros
  import XCTest

  final class FeatureActionMacroTests: XCTestCase {
    override func invokeTest() {
      withMacroTesting(
        macros: [FeatureActionMacro.self]
      ) {
        super.invokeTest()
      }
    }

    func testEmptyActionEnum() {
      assertMacro {
        """
        @FeatureAction
        public enum Action {}
        """
      } expansion: {
        #"""
        public enum Action {

            case child(Child)

            case delegate(Delegate)

            case external(External)

            case local(Local)

            case view(View)

            public enum Child {
            }

            public enum Delegate {
            }

            public enum External {
            }

            public enum Local {
            }

            public enum View {
            }

            public struct AllCasePaths: Swift.Sequence {
              public var child: CasePaths.AnyCasePath<Action, Child> {
                ._$embed(Action.child) {
                  guard case let .child(value) = $0 else {
                      return nil
                  }
                  return value
                }
              }
              public var delegate: CasePaths.AnyCasePath<Action, Delegate> {
                ._$embed(Action.delegate) {
                  guard case let .delegate(value) = $0 else {
                      return nil
                  }
                  return value
                }
              }
              public var external: CasePaths.AnyCasePath<Action, External> {
                ._$embed(Action.external) {
                  guard case let .external(value) = $0 else {
                      return nil
                  }
                  return value
                }
              }
              public var local: CasePaths.AnyCasePath<Action, Local> {
                ._$embed(Action.local) {
                  guard case let .local(value) = $0 else {
                      return nil
                  }
                  return value
                }
              }
              public var view: CasePaths.AnyCasePath<Action, View> {
                ._$embed(Action.view) {
                  guard case let .view(value) = $0 else {
                      return nil
                  }
                  return value
                }
              }

              public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Action>]> {
                [
                  \Action.Cases.child,
                  \Action.Cases.delegate,
                  \Action.Cases.external,
                  \Action.Cases.local,
                  \Action.Cases.view,
                ].makeIterator()
              }
            }

            public static var allCasePaths: AllCasePaths {
                AllCasePaths()
            }
        }

        extension Action: ComposableArchitecture.ViewAction, CasePaths.CasePathable, CasePaths.CasePathIterable {
        }
        """#
      }
    }

    func testCustomViewEnum() {
      assertMacro {
        """
        @FeatureAction
        public enum Action {
          public enum View {
            case buttonTapped
          }
        }
        """
      } expansion: {
        #"""
        public enum Action {
          @CasePathable
          public enum View {
            case buttonTapped
          }

          case child(Child)

          case delegate(Delegate)

          case external(External)

          case local(Local)

          case view(View)

          public enum Child {
          }

          public enum Delegate {
          }

          public enum External {
          }

          public enum Local {
          }

          public struct AllCasePaths: Swift.Sequence {
            public var child: CasePaths.AnyCasePath<Action, Child> {
              ._$embed(Action.child) {
                guard case let .child(value) = $0 else {
                  return nil
                }
                return value
              }
            }
            public var delegate: CasePaths.AnyCasePath<Action, Delegate> {
              ._$embed(Action.delegate) {
                guard case let .delegate(value) = $0 else {
                  return nil
                }
                return value
              }
            }
            public var external: CasePaths.AnyCasePath<Action, External> {
              ._$embed(Action.external) {
                guard case let .external(value) = $0 else {
                  return nil
                }
                return value
              }
            }
            public var local: CasePaths.AnyCasePath<Action, Local> {
              ._$embed(Action.local) {
                guard case let .local(value) = $0 else {
                  return nil
                }
                return value
              }
            }
            public var view: CasePaths.AnyCasePath<Action, View> {
              ._$embed(Action.view) {
                guard case let .view(value) = $0 else {
                  return nil
                }
                return value
              }
            }

            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Action>]> {
              [
                \Action.Cases.child,
                \Action.Cases.delegate,
                \Action.Cases.external,
                \Action.Cases.local,
                \Action.Cases.view,
              ].makeIterator()
            }
          }

          public static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        extension Action: ComposableArchitecture.ViewAction, CasePaths.CasePathable, CasePaths.CasePathIterable {
        }
        """#
      }
    }

    func testMultipleCustomNestedEnums() {
      assertMacro {
        """
        @FeatureAction
        public enum Action {
          public enum Child {
            case routeChanged
          }

          public enum View {
            case buttonTapped
          }
        }
        """
      } expansion: {
        #"""
        public enum Action {
          @CasePathable
          public enum Child {
            case routeChanged
          }
          @CasePathable

          public enum View {
            case buttonTapped
          }

          case child(Child)

          case delegate(Delegate)

          case external(External)

          case local(Local)

          case view(View)

          public enum Delegate {
          }

          public enum External {
          }

          public enum Local {
          }

          public struct AllCasePaths: Swift.Sequence {
            public var child: CasePaths.AnyCasePath<Action, Child> {
              ._$embed(Action.child) {
                guard case let .child(value) = $0 else {
                  return nil
                }
                return value
              }
            }
            public var delegate: CasePaths.AnyCasePath<Action, Delegate> {
              ._$embed(Action.delegate) {
                guard case let .delegate(value) = $0 else {
                  return nil
                }
                return value
              }
            }
            public var external: CasePaths.AnyCasePath<Action, External> {
              ._$embed(Action.external) {
                guard case let .external(value) = $0 else {
                  return nil
                }
                return value
              }
            }
            public var local: CasePaths.AnyCasePath<Action, Local> {
              ._$embed(Action.local) {
                guard case let .local(value) = $0 else {
                  return nil
                }
                return value
              }
            }
            public var view: CasePaths.AnyCasePath<Action, View> {
              ._$embed(Action.view) {
                guard case let .view(value) = $0 else {
                  return nil
                }
                return value
              }
            }

            public func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<Action>]> {
              [
                \Action.Cases.child,
                \Action.Cases.delegate,
                \Action.Cases.external,
                \Action.Cases.local,
                \Action.Cases.view,
              ].makeIterator()
            }
          }

          public static var allCasePaths: AllCasePaths {
            AllCasePaths()
          }
        }

        extension Action: ComposableArchitecture.ViewAction, CasePaths.CasePathable, CasePaths.CasePathIterable {
        }
        """#
      }
    }

    func testRequiresEnum() {
      assertMacro {
        """
        @FeatureAction
        public struct Action {}
        """
      } diagnostics: {
        """
        @FeatureAction
        ╰─ 🛑 '@FeatureAction' can only be applied to enum types
        public struct Action {}
        """
      }
    }

    func testCustomCasesAreRejected() {
      assertMacro {
        """
        @FeatureAction
        public enum Action {
          case somethingElse
        }
        """
      } diagnostics: {
        """
        @FeatureAction
        public enum Action {
          case somethingElse
               ┬────────────
               ╰─ 🛑 '@FeatureAction' does not allow custom enum cases ('somethingElse'); add behavior in nested action enums instead
        }
        """
      }
    }

    func testDuplicateConformanceRejected() {
      assertMacro {
        """
        @FeatureAction
        public enum Action: ViewAction {}
        """
      } diagnostics: {
        """
        @FeatureAction
        public enum Action: ViewAction {}
                    ┬─────
                    ╰─ 🛑 '@FeatureAction' already adds 'ViewAction' conformance; remove it from the enum inheritance list
        """
      }
    }

    func testReducerConflictDiagnostic() {
      assertMacro {
        """
        @Reducer
        struct Feature {
          @FeatureAction
          enum Action {}
        }
        """
      } diagnostics: {
        """
        @Reducer
        struct Feature {
          @FeatureAction
          enum Action {}
               ┬─────
               ╰─ 🛑 '@FeatureAction' conflicts with '@Reducer' auto-generated case paths; use '@FeatureReducer' on the enclosing type instead
        }
        """
      }
    }
  }
#endif

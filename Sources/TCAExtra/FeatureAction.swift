import ComposableArchitecture
import Foundation

public protocol FeatureAction<
  ChildAction,
  DelegateAction,
  ExternalAction,
  LocalAction,
  ViewAction
>: ViewAction {
  associatedtype ChildAction
  associatedtype DelegateAction
  associatedtype ExternalAction
  associatedtype LocalAction
  associatedtype ViewAction
  
  static func child(_ action: ChildAction) -> Self
  static func delegate(_ action: DelegateAction) -> Self
  static func external(_ action: ExternalAction) -> Self
  static func local(_ action: LocalAction) -> Self
  static func view(_ action: ViewAction) -> Self
}

import Foundation


@attached(
  member,
  names:
    named(Child),
  named(Delegate),
  named(External),
  named(Local),
  named(View),
  named(AllCasePaths),
  named(allCasePaths),
  named(child),
  named(binding),
  named(delegate),
  named(external),
  named(local),
  named(view)
)
@attached(memberAttribute)
@attached(extension, conformances: ViewAction, CasePathable, CasePathIterable)
public macro FeatureAction() = #externalMacro(
  module: "TCAExtraMacros",
  type: "FeatureActionMacro"
)

@attached(memberAttribute)
@attached(extension, conformances: Reducer)
public macro FeatureReducer() = #externalMacro(
  module: "TCAExtraMacros",
  type: "FeatureReducerMacro"
)

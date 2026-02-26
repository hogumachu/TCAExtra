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

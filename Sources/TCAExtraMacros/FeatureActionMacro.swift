import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct FeatureActionMacro {}

private enum FeatureActionRole: String, CaseIterable {
  case child = "Child"
  case delegate = "Delegate"
  case external = "External"
  case local = "Local"
  case view = "View"
  
  var caseName: String {
    switch self {
    case .child: return "child"
    case .delegate: return "delegate"
    case .external: return "external"
    case .local: return "local"
    case .view: return "view"
    }
  }

  static var baseRoles: [FeatureActionRole] {
    [.child, .delegate, .external, .local, .view]
  }
}

extension FeatureActionMacro: MemberMacro {
#if canImport(SwiftSyntax602)
#else
  public static func expansion<D: DeclGroupSyntax, C: MacroExpansionContext>(
    of node: AttributeSyntax,
    providingMembersOf declaration: D,
    in context: C
  ) throws -> [DeclSyntax] {
    try expansion(of: node, providingMembersOf: declaration, conformingTo: [], in: context)
  }
#endif
  
  public static func expansion(
    of _: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo _: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      throw DiagnosticsError(
        diagnostics: [FeatureActionMacroDiagnostic.notEnum.diagnose(at: declaration)]
      )
    }
    let isActionEnum = enumDecl.name.text == "Action"
    let shouldSynthesizeBindable =
      isActionEnum
      && hasEnclosingFeatureReducerDeclaration(for: enumDecl, in: context)
      && enumDecl.inheritsType(named: "BindableAction")
    if enumDecl.name.text == "Action", hasEnclosingReducerDeclaration(for: enumDecl, in: context) {
      throw DiagnosticsError(
        diagnostics: [FeatureActionMacroDiagnostic.reducerConflict.diagnose(at: enumDecl.name)]
      )
    }
    
    let enumCaseDecls = enumDecl.memberBlock.members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }
    if let firstCase = enumCaseDecls.first?.elements.first {
      throw DiagnosticsError(
        diagnostics: [FeatureActionMacroDiagnostic.customCaseNotAllowed(firstCase.name.text).diagnose(at: firstCase)]
      )
    }
    
    let existingNestedEnums = Set(
      enumDecl.memberBlock.members.compactMap { $0.decl.as(EnumDeclSyntax.self)?.name.text }
    )
    let accessPrefix = enumDecl.modifiers.accessPrefix
    let enumName = enumDecl.name.trimmedDescription
    
    let roles = FeatureActionRole.baseRoles
    var decls: [DeclSyntax] = roles.map { role in
      "case \(raw: role.caseName)(\(raw: role.rawValue))"
    }
    if shouldSynthesizeBindable {
      decls.append(
        "case binding(ComposableArchitecture.BindingAction<State>)"
      )
    }
    
    for role in roles where !existingNestedEnums.contains(role.rawValue) {
      decls.append(
        """
        \(raw: accessPrefix)enum \(raw: role.rawValue) {}
        """
      )
    }

    let bindingCasePath = shouldSynthesizeBindable
      ? """
        \(accessPrefix)var binding: CasePaths.AnyCasePath<\(enumName), ComposableArchitecture.BindingAction<State>> {
          ._$embed(\(enumName).binding) {
            guard case let .binding(value) = $0 else {
                return nil
            }
            return value
          }
        }
      """
      : nil
    let iteratorCaseNames =
      ["child"] + (shouldSynthesizeBindable ? ["binding"] : []) + ["delegate", "external", "local", "view"]
    let iteratorLines = iteratorCaseNames
      .map { "      \\\(enumName).Cases.\($0)," }
      .joined(separator: "\n")
    
    decls.append(
      """
      \(raw: accessPrefix)struct AllCasePaths: Swift.Sequence {
        \(raw: accessPrefix)var child: CasePaths.AnyCasePath<\(raw: enumName), Child> {
          ._$embed(\(raw: enumName).child) {
            guard case let .child(value) = $0 else {
                return nil
            }
            return value
          }
        }
        \(raw: accessPrefix)var delegate: CasePaths.AnyCasePath<\(raw: enumName), Delegate> {
          ._$embed(\(raw: enumName).delegate) {
            guard case let .delegate(value) = $0 else {
                return nil
            }
            return value
          }
        }
        \(raw: accessPrefix)var external: CasePaths.AnyCasePath<\(raw: enumName), External> {
          ._$embed(\(raw: enumName).external) {
            guard case let .external(value) = $0 else {
                return nil
            }
            return value
          }
        }
        \(raw: accessPrefix)var local: CasePaths.AnyCasePath<\(raw: enumName), Local> {
          ._$embed(\(raw: enumName).local) {
            guard case let .local(value) = $0 else {
                return nil
            }
            return value
          }
        }
        \(raw: accessPrefix)var view: CasePaths.AnyCasePath<\(raw: enumName), View> {
          ._$embed(\(raw: enumName).view) {
            guard case let .view(value) = $0 else {
                return nil
            }
            return value
          }
        }
        \(raw: bindingCasePath ?? "")
      
        \(raw: accessPrefix)func makeIterator() -> Swift.IndexingIterator<[CasePaths.PartialCaseKeyPath<\(raw: enumName)>]> {
          [
      \(raw: iteratorLines)
          ].makeIterator()
        }
      }
      """
    )
    
    decls.append(
      """
      \(raw: accessPrefix)static var allCasePaths: AllCasePaths { AllCasePaths() }
      """
    )
    return decls
  }
}

extension FeatureActionMacro: MemberAttributeMacro {
  public static func expansion<D: DeclGroupSyntax, M: DeclSyntaxProtocol, C: MacroExpansionContext>(
    of _: AttributeSyntax,
    attachedTo declaration: D,
    providingAttributesFor member: M,
    in _: C
  ) throws -> [AttributeSyntax] {
    guard let nestedEnum = member.as(EnumDeclSyntax.self) else { return [] }
    let roleNames = Set(FeatureActionRole.baseRoles.map(\.rawValue))
    guard roleNames.contains(nestedEnum.name.text) else { return [] }

    guard !nestedEnum.hasCasePathableAttribute else { return [] }
    return ["@CasePathable"]
  }
}

extension FeatureActionMacro: ExtensionMacro {
  public static func expansion<D: DeclGroupSyntax, T: TypeSyntaxProtocol, C: MacroExpansionContext>(
    of _: AttributeSyntax,
    attachedTo declaration: D,
    providingExtensionsOf type: T,
    conformingTo _: [TypeSyntax],
    in context: C
  ) throws -> [ExtensionDeclSyntax] {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      return []
    }
    let inheritedTypeNames = Set(
      (enumDecl.inheritanceClause?.inheritedTypes ?? []).map {
        $0.type.trimmedDescription.split(separator: ".").last.map(String.init) ?? $0.type.trimmedDescription
      }
    )
    let duplicated = ["ViewAction", "CasePathable", "CasePathIterable"]
      .filter(inheritedTypeNames.contains)
    if let duplicate = duplicated.first {
      throw DiagnosticsError(
        diagnostics: [FeatureActionMacroDiagnostic.duplicateConformance(duplicate).diagnose(at: enumDecl.name)]
      )
    }
    return [
      DeclSyntax(
        """
        \(declaration.attributes.availability)extension \(type.trimmed): \
        ComposableArchitecture.ViewAction, CasePaths.CasePathable, CasePaths.CasePathIterable {}
        """
      ).cast(ExtensionDeclSyntax.self)
    ]
  }
}

private func hasEnclosingReducerDeclaration(
  for declaration: some DeclGroupSyntax,
  in context: some MacroExpansionContext
) -> Bool {
  for lexical in context.lexicalContext {
    if let enclosingDecl = lexical.as(StructDeclSyntax.self), enclosingDecl.hasAttribute(named: "Reducer") {
      return true
    }
    if let enclosingDecl = lexical.as(ClassDeclSyntax.self), enclosingDecl.hasAttribute(named: "Reducer") {
      return true
    }
    if let enclosingDecl = lexical.as(ActorDeclSyntax.self), enclosingDecl.hasAttribute(named: "Reducer") {
      return true
    }
    if let enclosingDecl = lexical.as(EnumDeclSyntax.self), enclosingDecl.hasAttribute(named: "Reducer") {
      return true
    }
  }

  var current = declaration.parent
  while let node = current {
    if let enclosingDecl = node.as(StructDeclSyntax.self), enclosingDecl.hasAttribute(named: "Reducer") {
      return true
    }
    if let enclosingDecl = node.as(ClassDeclSyntax.self), enclosingDecl.hasAttribute(named: "Reducer") {
      return true
    }
    if let enclosingDecl = node.as(ActorDeclSyntax.self), enclosingDecl.hasAttribute(named: "Reducer") {
      return true
    }
    if let enclosingDecl = node.as(EnumDeclSyntax.self), enclosingDecl.hasAttribute(named: "Reducer") {
      return true
    }
    current = node.parent
  }
  return false
}

private func hasEnclosingFeatureReducerDeclaration(
  for declaration: some DeclGroupSyntax,
  in context: some MacroExpansionContext
) -> Bool {
  for lexical in context.lexicalContext {
    if let enclosingDecl = lexical.as(StructDeclSyntax.self), enclosingDecl.hasAttribute(named: "FeatureReducer") {
      return true
    }
    if let enclosingDecl = lexical.as(ClassDeclSyntax.self), enclosingDecl.hasAttribute(named: "FeatureReducer") {
      return true
    }
    if let enclosingDecl = lexical.as(ActorDeclSyntax.self), enclosingDecl.hasAttribute(named: "FeatureReducer") {
      return true
    }
    if let enclosingDecl = lexical.as(EnumDeclSyntax.self), enclosingDecl.hasAttribute(named: "FeatureReducer") {
      return true
    }
  }

  var current = declaration.parent
  while let node = current {
    if let enclosingDecl = node.as(StructDeclSyntax.self), enclosingDecl.hasAttribute(named: "FeatureReducer") {
      return true
    }
    if let enclosingDecl = node.as(ClassDeclSyntax.self), enclosingDecl.hasAttribute(named: "FeatureReducer") {
      return true
    }
    if let enclosingDecl = node.as(ActorDeclSyntax.self), enclosingDecl.hasAttribute(named: "FeatureReducer") {
      return true
    }
    if let enclosingDecl = node.as(EnumDeclSyntax.self), enclosingDecl.hasAttribute(named: "FeatureReducer") {
      return true
    }
    current = node.parent
  }
  return false
}

private enum FeatureActionMacroDiagnostic {
  case notEnum
  case customCaseNotAllowed(String)
  case duplicateConformance(String)
  case reducerConflict
  
  func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
    Diagnostic(node: Syntax(node), message: self)
  }
}

extension FeatureActionMacroDiagnostic: DiagnosticMessage {
  var message: String {
    switch self {
    case .notEnum:
      return "'@FeatureAction' can only be applied to enum types"
    case let .customCaseNotAllowed(caseName):
      return "'@FeatureAction' does not allow custom enum cases ('\(caseName)'); add behavior in nested action enums instead"
    case let .duplicateConformance(conformance):
      return "'@FeatureAction' already adds '\(conformance)' conformance; remove it from the enum inheritance list"
    case .reducerConflict:
      return "'@FeatureAction' conflicts with '@Reducer' auto-generated case paths; use '@FeatureReducer' on the enclosing type instead"
    }
  }
  
  var diagnosticID: MessageID {
    switch self {
    case .notEnum:
      return MessageID(domain: "FeatureActionMacro", id: "notEnum")
    case .customCaseNotAllowed:
      return MessageID(domain: "FeatureActionMacro", id: "customCaseNotAllowed")
    case .duplicateConformance:
      return MessageID(domain: "FeatureActionMacro", id: "duplicateConformance")
    case .reducerConflict:
      return MessageID(domain: "FeatureActionMacro", id: "reducerConflict")
    }
  }
  
  var severity: DiagnosticSeverity { .error }
}

private extension DeclModifierListSyntax {
  var accessPrefix: String {
    for modifier in self {
      switch modifier.name.tokenKind {
      case .keyword(.public):
        return "public "
      case .keyword(.package):
        return "package "
      default:
        continue
      }
    }
    return ""
  }
}

private extension EnumDeclSyntax {
  var hasCasePathableAttribute: Bool {
    let attributes = self.attributes
    for element in attributes {
      guard
        let attribute = element.as(AttributeSyntax.self),
        let name = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text
          ?? attribute.attributeName.as(MemberTypeSyntax.self)?.name.text
      else { continue }
      if name == "CasePathable" {
        return true
      }
    }
    return false
  }

  func inheritsType(named name: String) -> Bool {
    guard let inheritanceClause = inheritanceClause else { return false }
    return inheritanceClause.inheritedTypes.contains { inherited in
      let trimmed = inherited.type.trimmedDescription
      let simple = trimmed.split(separator: ".").last.map(String.init) ?? trimmed
      return simple == name
    }
  }
}

private extension DeclGroupSyntax {
  func hasAttribute(named name: String) -> Bool {
    self.attributes.contains { element in
      guard
        let attribute = element.as(AttributeSyntax.self),
        let attributeName = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text
          ?? attribute.attributeName.as(MemberTypeSyntax.self)?.name.text
      else { return false }
      return attributeName == name
    }
  }
}

private extension AttributeListSyntax {
  var availability: AttributeListSyntax? {
    let availabilityAttributes = compactMap { element -> AttributeListSyntax.Element? in
      guard
        let attribute = element.as(AttributeSyntax.self),
        let identifier = attribute.attributeName.as(IdentifierTypeSyntax.self)?.name.text,
        identifier == "available"
      else { return nil }
      return element
    }
    return availabilityAttributes.isEmpty ? nil : AttributeListSyntax(availabilityAttributes)
  }
}

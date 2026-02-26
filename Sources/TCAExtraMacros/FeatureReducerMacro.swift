import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct FeatureReducerMacro {}

extension FeatureReducerMacro: ExtensionMacro {
  public static func expansion<D: DeclGroupSyntax, T: TypeSyntaxProtocol, C: MacroExpansionContext>(
    of _: AttributeSyntax,
    attachedTo declaration: D,
    providingExtensionsOf type: T,
    conformingTo _: [TypeSyntax],
    in _: C
  ) throws -> [ExtensionDeclSyntax] {
    guard declaration.is(StructDeclSyntax.self) else {
      throw DiagnosticsError(
        diagnostics: [FeatureReducerMacroDiagnostic.notStruct.diagnose(at: declaration)]
      )
    }

    if let inheritanceClause = declaration.inheritanceClause,
      inheritanceClause.inheritedTypes.contains(
        where: {
          ["Reducer"].withQualified.contains($0.type.trimmedDescription)
        }
      )
    {
      return []
    }

    return [
      DeclSyntax(
        """
        \(declaration.attributes.availability)extension \(type.trimmed): ComposableArchitecture.Reducer {}
        """
      ).cast(ExtensionDeclSyntax.self)
    ]
  }
}

extension FeatureReducerMacro: MemberAttributeMacro {
  public static func expansion<D: DeclGroupSyntax, M: DeclSyntaxProtocol, C: MacroExpansionContext>(
    of _: AttributeSyntax,
    attachedTo declaration: D,
    providingAttributesFor member: M,
    in _: C
  ) throws -> [AttributeSyntax] {
    guard declaration.is(StructDeclSyntax.self) else {
      return []
    }

    if let structDecl = member.as(StructDeclSyntax.self), structDecl.name.text == "State" {
      return collectMissingAttributes(
        desired: ["ObservableState"],
        existingAttributes: structDecl.attributes
      )
    }

    if let enumDecl = member.as(EnumDeclSyntax.self) {
      var attributes: [String] = []
      switch enumDecl.name.text {
      case "State":
        attributes = ["CasePathable", "dynamicMemberLookup", "ObservableState"]
      case "Action":
        attributes = ["FeatureAction"]
      default:
        break
      }

      if let inheritanceClause = enumDecl.inheritanceClause,
        inheritanceClause.inheritedTypes.contains(
          where: {
            ["CasePathable"].withCasePathsQualified.contains($0.type.trimmedDescription)
          }
        )
      {
        attributes.removeAll(where: { $0 == "CasePathable" })
      }
      return collectMissingAttributes(
        desired: attributes,
        existingAttributes: enumDecl.attributes
      )
    }

    if let property = member.as(VariableDeclSyntax.self),
      property.bindingSpecifier.text == "var",
      property.bindings.count == 1,
      let binding = property.bindings.first,
      let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
      identifier.text == "body",
      case .getter = binding.accessorBlock?.accessors,
      let genericArguments = binding.typeAnnotation?
        .type.as(SomeOrAnyTypeSyntax.self)?
        .constraint.as(IdentifierTypeSyntax.self)?
        .genericArgumentClause?
        .arguments
    {
      for attribute in property.attributes {
        guard
          case .attribute(let attribute) = attribute,
          let attributeName = attribute.attributeSimpleName
        else { continue }
        guard
          !attributeName.starts(with: "ReducerBuilder"),
          !attributeName.starts(with: "ComposableArchitecture.ReducerBuilder")
        else { return [] }
      }

      let genericArguments =
        genericArguments.count == 1
        ? "\(genericArguments.description).State, \(genericArguments.description).Action"
        : "\(genericArguments)"

      return [
        AttributeSyntax(
          attributeName: IdentifierTypeSyntax(
            name: .identifier("ComposableArchitecture.ReducerBuilder<\(genericArguments)>")
          )
        )
      ]
    }

    return []
  }
}

private enum FeatureReducerMacroDiagnostic {
  case notStruct

  func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
    Diagnostic(node: Syntax(node), message: self)
  }
}

extension FeatureReducerMacroDiagnostic: DiagnosticMessage {
  var message: String {
    switch self {
    case .notStruct:
      return "'@FeatureReducer' can only be applied to struct types"
    }
  }

  var diagnosticID: MessageID {
    switch self {
    case .notStruct:
      return MessageID(domain: "FeatureReducerMacro", id: "notStruct")
    }
  }

  var severity: DiagnosticSeverity { .error }
}

private extension AttributeSyntax {
  var attributeSimpleName: String? {
    if let identifier = attributeName.as(IdentifierTypeSyntax.self)?.name.text {
      return identifier
    }
    if let member = attributeName.as(MemberTypeSyntax.self)?.name.text {
      return member
    }
    return nil
  }
}

private func collectMissingAttributes(
  desired: [String],
  existingAttributes: AttributeListSyntax
) -> [AttributeSyntax] {
  let existing: Set<String> = Set(existingAttributes.compactMap { element in
    guard
      case .attribute(let attribute) = element,
      let name = attribute.attributeSimpleName
    else { return nil }
    return name
  })

  return desired
    .filter { !existing.contains($0) }
    .map { AttributeSyntax(attributeName: IdentifierTypeSyntax(name: .identifier($0))) }
}

private extension Array where Element == String {
  var withQualified: [String] {
    self + self.map { "ComposableArchitecture.\($0)" }
  }

  var withCasePathsQualified: [String] {
    self + self.map { "CasePaths.\($0)" }
  }
}

private extension AttributeListSyntax {
  var availability: AttributeListSyntax? {
    let availabilityAttributes = compactMap { element -> AttributeListSyntax.Element? in
      guard
        let attribute = element.as(AttributeSyntax.self),
        attribute.attributeSimpleName == "available"
      else { return nil }
      return element
    }
    return availabilityAttributes.isEmpty ? nil : AttributeListSyntax(availabilityAttributes)
  }
}

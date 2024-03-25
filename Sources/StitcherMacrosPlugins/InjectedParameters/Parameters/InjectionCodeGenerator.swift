//
//  InjectionCodeGenerator.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 24/3/24.
//

struct InjectionCodeGenerator {
    
    enum Names: String {
        case stitcherByType
        case stitcherByName
    }
    
    static let parameterNamePlaceholder = "{{PARAMETER_NAME}}"
    static let parameterTypePlaceholder = "{{PARAMETER_TYPE}}"
    
    private let template: String
    
    init(template: String) {
        self.template = template
    }
    
    init() {
        self.init(template: "try! DependencyGraph.inject(byType: \(Self.parameterTypePlaceholder).self)")
    }
    
    func generateInjectionExpression(
        parameterName: String?,
        parameterTypeName: String
    ) -> String {
        
        return template
            .replacingOccurrences(of: Self.parameterNamePlaceholder, with: parameterName ?? "nil")
            .replacingOccurrences(of: Self.parameterTypePlaceholder, with: parameterTypeName)
    }
    
    static let defaultGenerator = InjectionCodeGenerator(
        template: "try! DependencyGraph.inject(byType: \(Self.parameterTypePlaceholder).self)"
    )
    
    static func named(_ name: String) -> InjectionCodeGenerator? {
        
        guard let name = Names(rawValue: name) else {
            return nil
        }
        
        let namedGenerators: [Names : InjectionCodeGenerator] = [
            .stitcherByType : .defaultGenerator,
            .stitcherByName : InjectionCodeGenerator(
                template: "try! DependencyGraph.inject(byName: \(Self.parameterNamePlaceholder).self)"
            )
        ]
        
       return namedGenerators[name]
    }
}

//
//  InjectionCodeGenerator.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 24/3/24.
//

struct InjectionCodeGenerator {
    
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
    
    static func named(_ name: String) -> InjectionCodeGenerator? {
        guard name == "stitcher" else {
            return nil
        }
        
        return InjectionCodeGenerator()
    }
}

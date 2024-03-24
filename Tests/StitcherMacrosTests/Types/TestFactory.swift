//
//  TestFactory.swift
//
//
//  Created by Αθανάσιος Κεφαλάς on 24/3/24.
//

import Foundation

enum TestFactory {
    
    static let generator = "TestFactory.provide(type: {{PARAMETER_TYPE}}.self)"
    
    struct Failure: Error {}
    
    struct Entry: Identifiable {
        
        let id: UUID
        let type: String
        let provider: () -> Any
        
        init<T>(provider: @escaping () -> T) {
            self.id = UUID()
            self.type = "\(T.self)"
            self.provider = {
                provider()
            }
        }
    }
    
    static var entries: [Entry] = []
    
    static func add<T>(
        _ provider: @escaping @autoclosure () -> T
    ) -> Entry {
        let entry = Entry(provider: provider)
        entries.append(entry)
        
        return entry
    }
    
    static func remove(entry: Entry) {
        entries.removeAll(where: { $0.id == entry.id })
    }
    
    static func provide<T>(type: T.Type) throws -> T {
        let type = "\(type)"
        
        guard let entry = entries.first(where: { $0.type == type }),
              let instance = entry.provider() as? T else {
            
            throw Failure()
        }
        
        return instance
    }
}

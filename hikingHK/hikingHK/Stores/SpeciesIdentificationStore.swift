//
//  SpeciesIdentificationStore.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

@MainActor
final class SpeciesIdentificationStore {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func saveIdentification(_ record: SpeciesIdentificationRecord) throws {
        context.insert(record)
        try context.save()
    }
    
    func loadAllIdentifications() throws -> [SpeciesIdentificationRecord] {
        var descriptor = FetchDescriptor<SpeciesIdentificationRecord>(
            sortBy: [SortDescriptor(\.identifiedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    func loadIdentificationsByCategory(_ category: String) throws -> [SpeciesIdentificationRecord] {
        var descriptor = FetchDescriptor<SpeciesIdentificationRecord>(
            predicate: #Predicate { $0.category == category },
            sortBy: [SortDescriptor(\.identifiedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    func deleteIdentification(_ record: SpeciesIdentificationRecord) throws {
        context.delete(record)
        try context.save()
    }
}


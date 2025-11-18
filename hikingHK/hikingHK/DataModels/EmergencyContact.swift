//
//  EmergencyContact.swift
//  hikingHK
//
//  Created by assistant on 17/11/2025.
//

import Foundation
import SwiftData

@Model
final class EmergencyContact {
    var id: UUID
    var name: String
    var phoneNumber: String
    var email: String?
    var isPrimary: Bool
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, phoneNumber: String, email: String? = nil, isPrimary: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.isPrimary = isPrimary
        self.createdAt = createdAt
    }
}


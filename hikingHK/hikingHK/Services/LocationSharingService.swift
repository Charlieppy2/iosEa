//
//  LocationSharingService.swift
//  hikingHK
//
//  Created by user on 17/11/2025.
//

import Foundation
import CoreLocation
import MessageUI

/// Abstraction for sharing the user's location via links, messages and email.
protocol LocationSharingServiceProtocol {
    func generateShareLink(location: CLLocationCoordinate2D) -> String
    func sendLocationViaMessage(contacts: [EmergencyContact], location: CLLocationCoordinate2D, message: String) async throws
    func sendLocationViaEmail(contacts: [EmergencyContact], location: CLLocationCoordinate2D, subject: String, message: String) async throws
    func sendEmergencySOS(contacts: [EmergencyContact], location: CLLocationCoordinate2D, message: String) async throws
}

final class LocationSharingService: LocationSharingServiceProtocol {
    
    func generateShareLink(location: CLLocationCoordinate2D) -> String {
        // Generate a Google Maps share link for the given coordinate.
        let url = "https://www.google.com/maps?q=\(location.latitude),\(location.longitude)"
        return url
    }
    
    func sendLocationViaMessage(contacts: [EmergencyContact], location: CLLocationCoordinate2D, message: String) async throws {
        // In a real app, this would use MessageUI or a third‑party service to send SMS.
        // This is currently a simulated implementation.
        let locationText = "Location: \(location.latitude), \(location.longitude)\nMap: \(generateShareLink(location: location))"
        let fullMessage = "\(message)\n\n\(locationText)"
        
        print("Sending SMS to: \(contacts.map { $0.name }.joined(separator: ", "))")
        print("Content: \(fullMessage)")
        
        // In a production implementation, you might use:
        // - MessageUI framework (requires user confirmation)
        // - Third‑party SMS service APIs
        // - Push notification services
    }
    
    func sendLocationViaEmail(contacts: [EmergencyContact], location: CLLocationCoordinate2D, subject: String, message: String) async throws {
        // In a real app, this would use MessageUI or an email service to send emails.
        let locationText = "Location: \(location.latitude), \(location.longitude)\nMap: \(generateShareLink(location: location))"
        let fullMessage = "\(message)\n\n\(locationText)"
        
        print("Sending email to: \(contacts.map { $0.email ?? $0.phoneNumber }.joined(separator: ", "))")
        print("Subject: \(subject)")
        print("Content: \(fullMessage)")
        
        // In a production implementation, you might use:
        // - MessageUI framework (requires user confirmation)
        // - Email service APIs (e.g. SendGrid, Mailgun)
    }
    
    func sendEmergencySOS(contacts: [EmergencyContact], location: CLLocationCoordinate2D, message: String) async throws {
        let sosMessage = "🆘 Emergency SOS!\n\n\(message)\n\nMy Location:\nLatitude: \(location.latitude)\nLongitude: \(location.longitude)\nMap: \(generateShareLink(location: location))\n\nPlease assist immediately!"
        
        // Send to all emergency contacts
        for contact in contacts {
            // Prefer SMS first (typically faster and more reliable)
            if !contact.phoneNumber.isEmpty {
                try await sendLocationViaMessage(contacts: [contact], location: location, message: sosMessage)
            }
            // If an email is available, also send an email copy
            if let email = contact.email, !email.isEmpty {
                try await sendLocationViaEmail(contacts: [contact], location: location, subject: "Emergency SOS - Immediate Assistance Needed", message: sosMessage)
            }
        }
        
        // In a production app, you might also:
        // - Trigger an emergency call (e.g. 999)
        // - Send push notifications
        // - Log the event to a monitoring / logging service
    }
}


//
//  HikeRecordFileStore.swift
//  hikingHK
//
//  Uses FileManager + JSON to persist hike records, avoiding SwiftData synchronization issues.
//  Uses the unified BaseFileStore architecture.
//

import Foundation
import CoreLocation

/// DTO for JSON persistence of a hike record.
struct PersistedHikeRecord: FileStoreDTO {
    struct PersistedTrackPoint: Codable {
        var id: UUID
        var latitude: Double
        var longitude: Double
        var altitude: Double
        var speed: Double
        var timestamp: Date
        var horizontalAccuracy: Double
        var verticalAccuracy: Double
    }
    
    var id: UUID
    var trailId: UUID?
    var trailName: String?
    var startTime: Date
    var endTime: Date?
    var isCompleted: Bool
    var totalDistance: Double
    var totalDuration: TimeInterval
    var averageSpeed: Double
    var maxSpeed: Double
    var elevationGain: Double
    var elevationLoss: Double
    var minAltitude: Double
    var maxAltitude: Double
    var notes: String?
    var trackPoints: [PersistedTrackPoint]
    
    // MARK: - FileStoreDTO Implementation
    
    /// Returns the ID of the hike record for identification.
    var modelId: UUID { id }
}

/// Manages saving and loading hike records using the file system.
/// Uses the unified BaseFileStore architecture.
@MainActor
final class HikeRecordFileStore: BaseFileStore<HikeRecord, PersistedHikeRecord> {
    
    init() {
        super.init(fileName: "hike_records.json")
    }
    
    // MARK: - Custom Loading (with sorting)
    
    /// Loads all hike records sorted by start time (most recent first).
    override func loadAll() throws -> [HikeRecord] {
        let all = try super.loadAll()
        return all.sorted { $0.startTime > $1.startTime }
    }
}

// MARK: - DTO <-> Model Conversion

extension PersistedHikeRecord {
    init(from model: HikeRecord) {
        self.id = model.id
        self.trailId = model.trailId
        self.trailName = model.trailName
        self.startTime = model.startTime
        self.endTime = model.endTime
        self.isCompleted = model.isCompleted
        self.totalDistance = model.totalDistance
        self.totalDuration = model.totalDuration
        self.averageSpeed = model.averageSpeed
        self.maxSpeed = model.maxSpeed
        self.elevationGain = model.elevationGain
        self.elevationLoss = model.elevationLoss
        self.minAltitude = model.minAltitude
        self.maxAltitude = model.maxAltitude
        self.notes = model.notes
        self.trackPoints = model.trackPoints.map {
            PersistedTrackPoint(
                id: $0.id,
                latitude: $0.latitude,
                longitude: $0.longitude,
                altitude: $0.altitude,
                speed: $0.speed,
                timestamp: $0.timestamp,
                horizontalAccuracy: $0.horizontalAccuracy,
                verticalAccuracy: $0.verticalAccuracy
            )
        }
    }
    
    func toModel() -> HikeRecord {
        let record = HikeRecord(
            id: id,
            trailId: trailId,
            trailName: trailName,
            startTime: startTime,
            endTime: endTime,
            isCompleted: isCompleted,
            totalDistance: totalDistance,
            totalDuration: totalDuration,
            averageSpeed: averageSpeed,
            maxSpeed: maxSpeed,
            elevationGain: elevationGain,
            elevationLoss: elevationLoss,
            minAltitude: minAltitude,
            maxAltitude: maxAltitude,
            notes: notes
        )
        
        // Restore track points and link them back to the record.
        let restoredTrackPoints: [HikeTrackPoint] = trackPoints.map {
            HikeTrackPoint(
                id: $0.id,
                latitude: $0.latitude,
                longitude: $0.longitude,
                altitude: $0.altitude,
                speed: $0.speed,
                timestamp: $0.timestamp,
                horizontalAccuracy: $0.horizontalAccuracy,
                verticalAccuracy: $0.verticalAccuracy
            )
        }
        record.trackPoints = restoredTrackPoints.sorted { $0.timestamp < $1.timestamp }
        
        return record
    }
}


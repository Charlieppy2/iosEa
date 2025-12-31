//
//  BaseFileStore.swift
//  hikingHK
//
//  Base implementation for FileManager + JSON persistence stores.
//

import Foundation

/// Base class that provides common file operations for JSON-based persistence.
/// Subclasses should implement the DTO conversion logic.
/// 
/// Requirements:
/// - Model must have an `id` property of type UUID (or conform to Identifiable with UUID id)
/// - DTO must implement FileStoreDTO protocol
@MainActor
class BaseFileStore<Model, DTO: FileStoreDTO>: FileStoreProtocol where DTO.Model == Model {
    
    /// The file URL where the JSON data is stored.
    private let fileURL: URL
    
    /// The JSON encoder used for writing data.
    private let encoder: JSONEncoder
    
    /// The JSON decoder used for reading data.
    private let decoder: JSONDecoder
    
    /// Creates a new file store with the specified file name.
    /// - Parameters:
    ///   - fileName: The name of the JSON file (default: based on model type name).
    ///   - directory: Optional custom directory. If nil, uses Documents directory.
    init(fileName: String? = nil, directory: URL? = nil) {
        let baseDirectory = directory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        
        let defaultFileName = fileName ?? "\(String(describing: Model.self).lowercased()).json"
        self.fileURL = baseDirectory.appendingPathComponent(defaultFileName)
        
        // Configure encoder
        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
        
        // Configure decoder
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - FileStoreProtocol Implementation
    
    func loadAll() throws -> [Model] {
        let persisted = try loadPersistedDTOs()
        return persisted.map { $0.toModel() }
    }
    
    func saveOrUpdate(_ item: Model) throws {
        var persisted = try loadPersistedDTOs()
        let dto = DTO(from: item)
        let itemId = dto.modelId
        
        if let index = persisted.firstIndex(where: { $0.modelId == itemId }) {
            persisted[index] = dto
        } else {
            persisted.append(dto)
        }
        
        try persist(dtos: persisted)
    }
    
    func delete(_ item: Model) throws {
        var persisted = try loadPersistedDTOs()
        let dto = DTO(from: item)
        let itemId = dto.modelId
        persisted.removeAll { $0.modelId == itemId }
        try persist(dtos: persisted)
    }
    
    func saveAll(_ items: [Model]) throws {
        let dtos = items.map { DTO(from: $0) }
        try persist(dtos: dtos)
    }
    
    func deleteAll() throws {
        try persist(dtos: [])
    }
    
    // MARK: - Protected Methods (for subclasses to override if needed)
    
    /// Loads all persisted DTOs from the file.
    /// Subclasses can override this to add custom sorting or filtering.
    func loadPersistedDTOs() throws -> [DTO] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: fileURL)
        guard !data.isEmpty else {
            return []
        }
        
        do {
            return try decoder.decode([DTO].self, from: data)
        } catch {
            // If decoding fails, the file might be corrupted
            // Try to recover by backing up the corrupted file and starting fresh
            print("⚠️ BaseFileStore: Failed to decode data from \(fileURL.path)")
            print("   Error: \(error.localizedDescription)")
            
            // Backup corrupted file
            let backupURL = fileURL.appendingPathExtension("corrupted.\(Date().timeIntervalSince1970)")
            do {
                try FileManager.default.moveItem(at: fileURL, to: backupURL)
                print("✅ BaseFileStore: Backed up corrupted file to \(backupURL.path)")
            } catch {
                print("⚠️ BaseFileStore: Failed to backup corrupted file: \(error)")
                // If backup fails, try to delete the corrupted file
                try? FileManager.default.removeItem(at: fileURL)
            }
            
            // Return empty array to start fresh
            print("✅ BaseFileStore: Starting with empty data")
            return []
        }
    }
    
    /// Persists DTOs to the file.
    /// Subclasses can override this to add custom validation or transformation.
    func persist(dtos: [DTO]) throws {
        do {
            let data = try encoder.encode(dtos)
            
            // Ensure the directory exists
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            
            // Write atomically to prevent corruption
            try data.write(to: fileURL, options: .atomic)
        } catch let error as EncodingError {
            throw FileStoreError.encodingFailed(error)
        } catch {
            throw FileStoreError.writeFailed(error)
        }
    }
    
    // MARK: - Utility Methods
    
    /// Returns the file path for debugging purposes.
    var filePath: String {
        fileURL.path
    }
    
    /// Checks if the file exists.
    var fileExists: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    /// Returns the file size in bytes, or nil if the file doesn't exist.
    var fileSize: Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }
        return size
    }
}


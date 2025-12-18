//
//  FileStoreProtocol.swift
//  hikingHK
//
//  Unified protocol for FileManager + JSON persistence layer.
//

import Foundation

/// Protocol that defines the contract for converting between domain models and JSON DTOs.
protocol FileStoreDTO: Codable {
    associatedtype Model
    
    /// Creates a DTO from a domain model.
    init(from model: Model)
    
    /// Converts the DTO back to a domain model.
    func toModel() -> Model
    
    /// Returns the ID of the model represented by this DTO.
    /// Used for comparison and identification.
    var modelId: UUID { get }
}

/// Protocol for all file-based stores that persist data as JSON.
/// Model must have an `id` property for identification.
protocol FileStoreProtocol {
    associatedtype Model
    associatedtype DTO: FileStoreDTO where DTO.Model == Model
    
    /// Loads all items from the JSON file.
    /// - Returns: An array of domain models.
    /// - Throws: FileStoreError if loading fails.
    func loadAll() throws -> [Model]
    
    /// Saves or updates an item in the JSON file.
    /// - Parameter item: The domain model to save or update.
    /// - Throws: FileStoreError if saving fails.
    func saveOrUpdate(_ item: Model) throws
    
    /// Deletes an item from the JSON file.
    /// - Parameter item: The domain model to delete.
    /// - Throws: FileStoreError if deletion fails.
    func delete(_ item: Model) throws
    
    /// Saves multiple items at once (batch operation).
    /// - Parameter items: Array of domain models to save.
    /// - Throws: FileStoreError if saving fails.
    func saveAll(_ items: [Model]) throws
    
    /// Deletes all items from the JSON file.
    /// - Throws: FileStoreError if deletion fails.
    func deleteAll() throws
}

/// Errors that can occur during file store operations.
enum FileStoreError: LocalizedError {
    case fileNotFound
    case invalidData
    case encodingFailed(Error)
    case decodingFailed(Error)
    case writeFailed(Error)
    case readFailed(Error)
    case directoryCreationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "File not found"
        case .invalidData:
            return "Invalid data format"
        case .encodingFailed(let error):
            return "Failed to encode data: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .writeFailed(let error):
            return "Failed to write file: \(error.localizedDescription)"
        case .readFailed(let error):
            return "Failed to read file: \(error.localizedDescription)"
        case .directoryCreationFailed(let error):
            return "Failed to create directory: \(error.localizedDescription)"
        }
    }
}


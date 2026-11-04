//
//  AppErrors.swift
//  Spellbreak
//
//  Error types and handling for the application.
//

import Foundation

// MARK: - App Error Types
/// Centralized error definitions for better error handling

// MARK: - Audio Errors
enum AudioError: LocalizedError {
    case fileNotFound(String)
    case loadFailed(Error)
    case playbackFailed
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Audio file not found: \(filename)"
        case .loadFailed(let error):
            return "Failed to load audio: \(error.localizedDescription)"
        case .playbackFailed:
            return "Audio playback failed"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .fileNotFound:
            return "Check that the audio file is included in the app bundle"
        case .loadFailed:
            return "The audio file may be corrupted or in an unsupported format"
        case .playbackFailed:
            return "Check audio output device settings"
        }
    }
}
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
    case volumeUpdateFailed
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Audio file not found: \(filename)"
        case .loadFailed(let error):
            return "Failed to load audio: \(error.localizedDescription)"
        case .playbackFailed:
            return "Audio playback failed"
        case .volumeUpdateFailed:
            return "Failed to update audio volume"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .fileNotFound:
            return "Check that the audio file is included in the app bundle"
        case .loadFailed:
            return "The audio file may be corrupted or in an unsupported format"
        case .playbackFailed:
            return "Check your audio output device settings"
        case .volumeUpdateFailed:
            return "Try adjusting the volume in preferences"
        }
    }
}

// MARK: - Window Errors
enum WindowError: LocalizedError {
    case creationFailed
    case displayFailed
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .creationFailed:
            return "Failed to create window"
        case .displayFailed:
            return "Failed to display window"
        case .invalidConfiguration:
            return "Invalid window configuration"
        }
    }
}

// MARK: - Notification Errors
enum NotificationError: LocalizedError {
    case authorizationDenied
    case authorizationFailed(Error)
    case schedulingFailed
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Notification permission was denied"
        case .authorizationFailed(let error):
            return "Failed to request notification permission: \(error.localizedDescription)"
        case .schedulingFailed:
            return "Failed to schedule notification"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authorizationDenied:
            return "Enable notifications in System Preferences > Notifications"
        case .authorizationFailed:
            return "Try restarting the app and granting permission again"
        case .schedulingFailed:
            return "Check that notification permissions are granted"
        }
    }
}

// MARK: - Timer Errors
enum TimerError: LocalizedError {
    case creationFailed
    case invalidInterval
    
    var errorDescription: String? {
        switch self {
        case .creationFailed:
            return "Failed to create timer"
        case .invalidInterval:
            return "Invalid timer interval"
        }
    }
}
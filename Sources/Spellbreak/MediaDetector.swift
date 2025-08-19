//
//  MediaDetector.swift
//  Spellbreak
//
//  Simple detection of camera and microphone usage to avoid
//  interrupting video calls, audio calls, or recordings.
//

import AVFoundation
import CoreAudio

class MediaDetector {
    
    static func isCameraInUse() -> Bool {
        let videoDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified
        ).devices
        
        for device in videoDevices {
            if device.isInUseByAnotherApplication {
                return true
            }
        }
        
        return false
    }
    
    static func isMicrophoneInUse() -> Bool {
        var propertySize: UInt32 = 0
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        // Get the size of the device list
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize
        ) == noErr else {
            return false
        }
        
        // Get all audio devices
        let deviceCount = Int(propertySize) / MemoryLayout<AudioObjectID>.size
        var audioDevices = Array(repeating: AudioObjectID(), count: deviceCount)
        
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &audioDevices
        ) == noErr else {
            return false
        }
        
        // Check each device to see if it's an input device that's running
        for deviceID in audioDevices {
            // Check if this is an input device
            var streamAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: kAudioDevicePropertyScopeInput,
                mElement: kAudioObjectPropertyElementMain
            )
            
            var streamSize: UInt32 = 0
            guard AudioObjectGetPropertyDataSize(
                deviceID,
                &streamAddress,
                0,
                nil,
                &streamSize
            ) == noErr else {
                continue
            }
            
            // If it has input streams, check if it's running
            if streamSize > 0 {
                var isRunningAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMain
                )
                
                var isRunning: UInt32 = 0
                var propertySize = UInt32(MemoryLayout<UInt32>.size)
                
                if AudioObjectGetPropertyData(
                    deviceID,
                    &isRunningAddress,
                    0,
                    nil,
                    &propertySize,
                    &isRunning
                ) == noErr && isRunning != 0 {
                    return true
                }
            }
        }
        
        return false
    }
    
    static func isInCall() -> Bool {
        return isCameraInUse() || isMicrophoneInUse()
    }
}
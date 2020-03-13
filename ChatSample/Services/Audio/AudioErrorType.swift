//
//  AudioErrorType.swift
//  ChatSample
//
//  Created by admin on 12.03.2020.
//  Copyright © 2020 admin. All rights reserved.
//

import Foundation

enum AudioErrorType: Error {
    case fileNotAvailiable
    
    case alreadyRecording
    case alreadyPlaying
    case notCurrentlyPlaying
    case audioFileWrongPath
    case recordFailed
    case playFailed
    case recordPermissionNotGranted
    case internalError
    
    case assetExportFailed
    case assetExportCancelled
    case assetExportUnknown
    case assetExportWaiting
    case assetExportExporting
}

extension AudioErrorType: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "The application is currently recording sounds"
        case .alreadyPlaying:
            return "The application is already playing a sound"
        case .notCurrentlyPlaying:
            return "The application is not currently playing"
        case .audioFileWrongPath:
            return "Invalid path for audio file"
        case .recordFailed:
            return "Unable to record sound at the moment, please try again"
        case .playFailed:
            return "Unable to play sound at the moment, please try again"
        case .recordPermissionNotGranted:
            return "Unable to record sound because the permission has not been granted. This can be changed in your settings."
        case .internalError:
            return "An error occured while trying to process audio command, please try again"
        case .assetExportFailed:
            return "Asset export manager tried to concatinate audio files. Status: Failed"
        case .assetExportCancelled:
            return "Asset export manager tried to concatinate audio files. Status: Cancelled"
        case .assetExportUnknown:
            return "Asset export manager tried to concatinate audio files. Status: Unknown"
        case .assetExportWaiting:
            return "Asset export manager tried to concatinate audio files. Status: Waiting"
        case .assetExportExporting:
            return "Asset export manager tried to concatinate audio files. Status: Exporting"
        case .fileNotAvailiable:
            return "Audio at URL is not availiable"
        }
    }
}

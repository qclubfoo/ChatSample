//
//  AudioRecorderManager.swift
//  ChatSample
//
//  Created by admin on 12.03.2020.
//  Copyright © 2020 admin. All rights reserved.
//

import Foundation
import AVFoundation

let audioPercentageUserInfoKey = "percentage"

final class AudioRecorderManager: NSObject {
    let audioFileNamePrefix = "org.cocoapods.audioRecordAndTrim-"
    let encoderBitRate: Int = 320000
    let numberOfChannels: Int = 2
    let sampleRate: Double = 44100.0

    static let shared = AudioRecorderManager()

    var isPermissionGranted = false
    var isRunning: Bool {
        guard let recorder = self.recorder, recorder.isRecording else {
            return false
        }
        return true
    }

    var currentRecordPath: URL?

    private var recorder: AVAudioRecorder?
    private var audioMeteringLevelTimer: Timer?

    private override init() {
        super.init()
    }
    
    func askPermission(completion: ((Bool) -> Void)? = nil) {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            self?.isPermissionGranted = granted
            completion?(granted)
            print("Audio Recorder did not grant permission")
        }
    }

    func startRecording(with audioVisualizationTimeInterval: TimeInterval = 0.05, completion: @escaping (URL?, Error?) -> Void) {
        func startRecordingReturn() {
            do {
                completion(try internalStartRecording(with: audioVisualizationTimeInterval), nil)
            } catch {
                completion(nil, error)
            }
        }
        
        if !self.isPermissionGranted {
            self.askPermission { granted in
                startRecordingReturn()
            }
        } else {
            startRecordingReturn()
        }
    }
    
    fileprivate func internalStartRecording(with audioVisualizationTimeInterval: TimeInterval) throws -> URL {
        if self.isRunning {
            throw AudioErrorType.alreadyPlaying
        }
        
        let recordSettings = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey : self.encoderBitRate,
            AVNumberOfChannelsKey: self.numberOfChannels,
            AVSampleRateKey : self.sampleRate
        ] as [String : Any]
        
        let path = getDocumentURL(withAppendingPathComponent: self.audioFileNamePrefix + NSUUID().uuidString + ".m4a")

        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try AVAudioSession.sharedInstance().setActive(true)
        
        self.recorder = try AVAudioRecorder(url: path, settings: recordSettings)
        self.recorder!.delegate = self
        self.recorder!.isMeteringEnabled = true
        
        if !self.recorder!.prepareToRecord() {
            print("Audio Recorder prepare failed")
            throw AudioErrorType.recordFailed
        }
        
        if !self.recorder!.record() {
            print("Audio Recorder start failed")
            throw AudioErrorType.recordFailed
        }
        
        self.audioMeteringLevelTimer = Timer.scheduledTimer(timeInterval: audioVisualizationTimeInterval, target: self,
            selector: #selector(AudioRecorderManager.timerDidUpdateMeter), userInfo: nil, repeats: true)
        
        print("Audio Recorder did start - creating file at index: \(path.absoluteString)")
        
        self.currentRecordPath = path
        return path
    }

    func stopRecording() throws {
        self.audioMeteringLevelTimer?.invalidate()
        self.audioMeteringLevelTimer = nil
        
        if !self.isRunning {
            print("Audio Recorder did fail to stop")
            throw AudioErrorType.notCurrentlyPlaying
        }
        
        self.recorder!.stop()
        print("Audio Recorder did stop successfully")
    }

    func reset() throws {
        if self.isRunning {
            print("Audio Recorder tried to remove recording before stopping it")
            throw AudioErrorType.alreadyRecording
        }
        
        self.recorder?.deleteRecording()
        self.recorder = nil
        self.currentRecordPath = nil
        
        print("Audio Recorder did remove current record successfully")
    }
    
    func concatenate(firstAudioUrl: URL, secondAudioUrl: URL, completion: @escaping () -> Void) throws {
        if self.isRunning {
            print("Audio Recorder tried to concatenate recording before stopping it")
            throw AudioErrorType.alreadyRecording
        }
        
        let mutableComposition = AVMutableComposition()
        let audioFilesUrls: [URL] = [firstAudioUrl, secondAudioUrl]
        for i in 0 ..< audioFilesUrls.count {
            let compositionAudioTrack: AVMutableCompositionTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                                                      preferredTrackID: CMPersistentTrackID()
                )!
            let asset = AVURLAsset(url: audioFilesUrls[i], options: nil)
            let track = asset.tracks(withMediaType: AVMediaType.audio).first
            let timeRange = CMTimeRange(start: CMTimeMake(value: 0,
                                                          timescale: 600),
                                        duration: (track?.timeRange.duration)!)
            try! compositionAudioTrack.insertTimeRange(timeRange,
                                                       of: track!,
                                                       at: mutableComposition.duration)
        }
        
        let mergeUrl = getDocumentURL(withAppendingPathComponent: self.audioFileNamePrefix + ".merge." + NSUUID().uuidString + ".m4a")
        
        var throwError: AudioErrorType?
        let assetExport = AVAssetExportSession(asset: mutableComposition, presetName: AVAssetExportPresetAppleM4A)
        assetExport?.outputURL = mergeUrl
        assetExport?.outputFileType = .m4a
        assetExport?.exportAsynchronously(completionHandler:
            {
                switch assetExport!.status
                {
                case .failed:
                    print("Asset export manager tried to concatinate audio files. Status: Failed")
                    throwError = .assetExportFailed
                    break
                case .cancelled:
                    print("Asset export manager tried to concatinate audio files. Status: Cancelled")
                    throwError = .assetExportCancelled
                    break
                case .unknown:
                    print("Asset export manager tried to concatinate audio files. Status: Unknown")
                    throwError = .assetExportUnknown
                    break
                case .waiting:
                    print("Asset export manager tried to concatinate audio files. Status: Waiting")
                    throwError = .assetExportWaiting
                    break
                case .exporting:
                    print("Asset export manager tried to concatinate audio files. Status: Exporting")
                    throwError = .assetExportExporting
                    break
                default:
                    DispatchQueue.main.async {
                        if self.isFileAvaliable(url: firstAudioUrl) {
                            do {
                                try FileManager.default.removeItem(at: firstAudioUrl)
                            } catch {
                                throwError = AudioErrorType.fileNotAvailiable
                            }
                            if self.isFileAvaliable(url: secondAudioUrl) {
                                do {
                                    try FileManager.default.removeItem(at: secondAudioUrl)
                                } catch {
                                    throwError = AudioErrorType.fileNotAvailiable
                                }
                            }
                        }
                        if throwError == nil {
                            do {
                                try FileManager.default.moveItem(at: mergeUrl, to: firstAudioUrl)
                                
                            } catch {
                                throwError = .assetExportFailed
                            }
                        }
                    }
                    print("Audio Concatenation Complete")
                    completion()
                }
        })
        
        if throwError != nil {
            throw throwError!
        }
        
    }
    
    private func isFileAvaliable(url: URL) -> Bool {
        do {
            if try url.checkResourceIsReachable() {
                return true
            }
        } catch {
            print(error.localizedDescription)
        }
        return false
    }

    @objc func timerDidUpdateMeter() {
        if self.isRunning {
            self.recorder!.updateMeters()
            let averagePower = recorder!.averagePower(forChannel: 0)
            let percentage: Float = pow(10, (0.05 * averagePower))
            NotificationCenter.default.post(name: .audioRecorderManagerMeteringLevelDidUpdateNotification, object: self, userInfo: [audioPercentageUserInfoKey: percentage])
        }
    }
}

extension AudioRecorderManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        NotificationCenter.default.post(name: .audioRecorderManagerMeteringLevelDidFinishNotification, object: self)
        print("Audio Recorder finished successfully")
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        NotificationCenter.default.post(name: .audioRecorderManagerMeteringLevelDidFailNotification, object: self)
        print("Audio Recorder error")
    }
}

extension Notification.Name {
    static let audioRecorderManagerMeteringLevelDidUpdateNotification = Notification.Name("AudioRecorderManagerMeteringLevelDidUpdateNotification")
    static let audioRecorderManagerMeteringLevelDidFinishNotification = Notification.Name("AudioRecorderManagerMeteringLevelDidFinishNotification")
    static let audioRecorderManagerMeteringLevelDidFailNotification = Notification.Name("AudioRecorderManagerMeteringLevelDidFailNotification")
}

extension AudioRecorderManager {
    fileprivate func getDocumentURL(withAppendingPathComponent: String) -> URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(withAppendingPathComponent)
        return url
    }
}


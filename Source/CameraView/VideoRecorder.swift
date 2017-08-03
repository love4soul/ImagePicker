//
//  VideoRecorder.swift
//  ImagePicker
//
//  Created by Igors Nemenonoks on 02/01/17.
//  Copyright © 2017 Hyper Interaktiv AS. All rights reserved.
//

import Foundation
import AVFoundation
import AssetsLibrary

class VideoRecorder: NSObject {

  lazy var micDevice: AVCaptureDevice? = {
    return AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
  }()

  lazy var movieOutput = AVCaptureMovieFileOutput()

  private var tempVideoFilePath: URL = {
    let tempPath = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tempMovie")?.appendingPathExtension("mp4").absoluteString
    VideoRecorder.tryToDeleteFileAt(path: tempPath)
    return URL(string: tempPath!)!
  }()

  internal var library = ALAssetsLibrary()
  internal var videoCompletion: (() -> Void)?
  var videoProcessing: (() -> Void)?

  internal var recordTimer: Timer?
  internal var startTimerDate: Date?
  var recordProgress: ((TimeInterval) -> Void)?

  deinit {
    if recordTimer != nil {
      recordTimer?.invalidate()
    }
  }

  func startRecording() {
    movieOutput.startRecording(toOutputFileURL: tempVideoFilePath, recordingDelegate: self)
    print("START recording")
  }

  func stopRecording() {
    movieOutput.stopRecording()
  }

  static func tryToDeleteFileAt(path: String?) {
    guard let path = path else { return }

    if FileManager.default.fileExists(atPath: path) {
      do {
        try FileManager.default.removeItem(atPath: path)
      } catch { }
    }
  }
}

extension VideoRecorder: AVCaptureFileOutputRecordingDelegate {
  func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
    print("didStartRecordingToOutputFileAt ", fileURL)
    if self.recordTimer != nil {
      self.recordTimer?.invalidate()
      self.recordTimer = nil
    }
    self.recordTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self,
                                            selector: #selector(updateTimer),
                                            userInfo: nil,
                                            repeats: true)
    self.startTimerDate = Date()
  }

  func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
    if error != nil {
      print("Video recording error ", error)
    } else {
      videoProcessing?()
      self.recordTimer?.invalidate()
      self.recordTimer = nil
      recordProgress?(0)
      library.writeVideoAtPath(toSavedPhotosAlbum: outputFileURL, completionBlock: {[weak self] (_, error) in
        if error != nil {
          print("Unable to save video to the iPhone \(error!.localizedDescription)")
        } else {
          print("Video saved")
          VideoRecorder.tryToDeleteFileAt(path: outputFileURL.path)
          self?.videoCompletion?()
        }
      })
    }
  }

  @objc private func updateTimer() {
    if let date = self.startTimerDate {
      recordProgress?(date.timeIntervalSinceNow * -1)
    }
  }
}

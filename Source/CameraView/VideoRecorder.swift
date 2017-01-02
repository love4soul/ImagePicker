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
    if FileManager.default.fileExists(atPath: tempPath!) {
      do {
        try FileManager.default.removeItem(atPath: tempPath!)
      } catch { }
    }
    return URL(string: tempPath!)!
  }()

  internal var library = ALAssetsLibrary()
  internal var videoCompletion: (() -> Void)?
  var videoProcessing: (() -> Void)?

  func startRecording() {
    movieOutput.startRecording(toOutputFileURL: tempVideoFilePath, recordingDelegate: self)
    print("START recording")
  }

  func stopRecording() {
    movieOutput.stopRecording()
  }
}

extension VideoRecorder: AVCaptureFileOutputRecordingDelegate {
  func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
    print("didStartRecordingToOutputFileAt ", fileURL)
  }

  func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
    if error != nil {
      print("Video recording error ", error)
    } else {
      videoProcessing?()
      library.writeVideoAtPath(toSavedPhotosAlbum: outputFileURL, completionBlock: {[weak self] (assetUrl, error) in
        if error != nil {
          print("Unable to save video to the iPhone \(error!.localizedDescription)")
        } else {
          print("Video saved")
          self?.videoCompletion?()
        }
      })
    }
  }
}

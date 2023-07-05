//
//  SampleHandler.swift
//  BroadcastUploadExtension
//
//  Created by lihaozhen on 2023/7/5.
//

// import CCHDarwinNotificationCenter
import Photos
import ReplayKit

class SampleHandler: RPBroadcastSampleHandler {
  var writter: AVAssetWriter?
  var videoInput: AVAssetWriterInput!
  var microInput: AVAssetWriterInput!
  let appGroup = "group.hojin.replay"
  let fileManager = FileManager.default
  var sessionBeginAtSourceTime: CMTime!
  var isRecording = false
  var outputFileURL: URL!

//  NSNotification.Name(rawValue: "cn.hojin.record.broadcast.finished")
  let notificaitonName = "cn.hojin.record.broadcast.finished"

  override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
    // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
    print(#function)
    setupAssetWritter()
    writter?.startWriting()
  }

  override func broadcastPaused() {
    // User has requested to pause the broadcast. Samples will stop being delivered.
    print(#function)
  }

  override func broadcastResumed() {
    // User has requested to resume the broadcast. Samples delivery will resume.
    print(#function)
  }

  override func broadcastFinished() {
    // User has requested to finish the broadcast.
    print(#function)
    onFinishRecording()
  }

  override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
    guard canWrite() else {
      return
    }

    if sessionBeginAtSourceTime == nil {
      sessionBeginAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
      writter!.startSession(atSourceTime: sessionBeginAtSourceTime)
    }

    switch sampleBufferType {
    case RPSampleBufferType.video:
      // Handle video sample buffer

      if videoInput.isReadyForMoreMediaData {
        videoInput.append(sampleBuffer)
      }
    case RPSampleBufferType.audioApp:
      // Handle audio sample buffer for app audio
      break
    case RPSampleBufferType.audioMic:
      // Handle audio sample buffer for mic audio
      if microInput.isReadyForMoreMediaData {
        microInput.append(sampleBuffer)
      }
      break
    @unknown default:
      // Handle other sample buffer types
      fatalError("Unknown type of sample buffer")
    }
  }

  deinit {
    print("\(self) - \(#function)")
  }

  // MARK: - Methods

  func canWrite() -> Bool {
    return writter?.status == .writing
  }

  func setupAssetWritter() {
    outputFileURL = videoFileLocation()
    print("\(self).\(#function) output file at: \(outputFileURL)")
    guard let writter = try? AVAssetWriter(url: outputFileURL, fileType: .mp4) else {
      return
    }

    self.writter = writter

    let width = UIScreen.main.bounds.width * 2
    let height = UIScreen.main.bounds.height * 2

    let videoCompressionPropertys = [
      AVVideoAverageBitRateKey: width * height * 10.1
    ]

    let videoSettings: [String: Any] = [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: width,
      AVVideoHeightKey: height,
      AVVideoCompressionPropertiesKey: videoCompressionPropertys
    ]

    videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
    videoInput.expectsMediaDataInRealTime = true

    // Add the microphone input
    var acl = AudioChannelLayout()
    memset(&acl, 0, MemoryLayout<AudioChannelLayout>.size)
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono
    let audioOutputSettings: [String: Any] =
      [AVFormatIDKey: kAudioFormatMPEG4AAC,
       AVSampleRateKey: 44100,
       AVNumberOfChannelsKey: 1,
       AVEncoderBitRateKey: 64000,
       AVChannelLayoutKey: Data(bytes: &acl, count: MemoryLayout<AudioChannelLayout>.size)]

    microInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
    microInput.expectsMediaDataInRealTime = true

    if writter.canAdd(videoInput) {
      writter.add(videoInput)
    }

    if writter.canAdd(microInput) {
      writter.add(microInput)
    }
  }

  func onFinishRecording() {
    print("\(self).\(#function)")
    sessionBeginAtSourceTime = nil

    let dispatchGroup = DispatchGroup()
    dispatchGroup.enter()

    if fileManager.fileExists(atPath: outputFileURL.path()) {
      print(try? fileManager.attributesOfItem(atPath: outputFileURL.path()))
    }

    videoInput.markAsFinished()
    microInput.markAsFinished()

    writter!.finishWriting { [weak self] in
      print("writter finish writing")

      guard let self = self else {
        return
      }
      self.postNotification()
      print("\(self).\(#function) check photo authorization")
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        if status == .authorized || status == .limited {
          PHPhotoLibrary.shared().performChanges {
//            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: )
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.outputFileURL)
          } completionHandler: { saved, error in
            print("save video to album: \(saved ? "success" : "failed"), error: \(error?.localizedDescription)")
            dispatchGroup.leave()
          }
        } else {
          // 无存储权限
          print("未授予相册存储权限")
          dispatchGroup.leave()
        }
      }
    }

    dispatchGroup.wait()
  }

  func videoFileLocation() -> URL {
    let documentsPath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup)!
    let videoOutputUrl = documentsPath
      .appendingPathComponent("Library/Caches/mobile")
      .appendingPathExtension("mp4")

    do {
      if fileManager.fileExists(atPath: videoOutputUrl.path()) {
        try fileManager.removeItem(at: videoOutputUrl)
      }
    } catch {
      print(error)
    }

    return videoOutputUrl
  }

  fileprivate func postNotification() {
//    CCHDarwinNotificationCenter.postNotification(withIdentifier: notificaitonName)
    print("\(self).\(#function) ")
    
    ExHelper.shared.postNotification(name: notificaitonName)
  }
}

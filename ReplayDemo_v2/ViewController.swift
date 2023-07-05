//
//  ViewController.swift
//  ReplayDemo_v2
//
//  Created by lihaozhen on 2023/7/5.
//

import ReplayKit
import UIKit

class ViewController: UIViewController {
  let appGroup = "group.hojin.replay"
  let fileManager = FileManager.default
  let notificationNameRaw = "cn.hojin.record.broadcast.finished"
  let notificaitonName = NSNotification.Name(rawValue: "cn.hojin.record.broadcast.finished")

  deinit {
    removeNotificationObserver()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupNotification()
    // Do any additional setup after loading the view.

    let picker = RPSystemBroadcastPickerView(frame: CGRect(x: 20, y: 88, width: 44, height: 44))
    picker.preferredExtension = "cn.hojin.ReplayDemo-v2.Broadcast"

    picker.center = view.center
    view.addSubview(picker)
  }

  func setupNotification() {
//    let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
//    CFNotificationCenterAddObserver(
//      notificationCenter,
//      Unmanaged.passUnretained(self).toOpaque(),
//      { nc, observer, name, object, userInfo in
//        print("nc: \(nc)")
//        print("observer: \(observer)")
//        print("name: \(name)")
//        print("object: \(object)")
//        print("userInfo: \(userInfo)")
//
//        (observer as ViewController)?.getRecordFile()
//      },
//      notificaitonName.rawValue,
//      nil,
//      .deliverImmediately)
//
    print("\(self).\(#function) ")

    ExHelper.shared.addObserver(
      self,
      selector: #selector(Self.handleNotification(_:)),
      name: notificationNameRaw)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(Self.handleNotification(_:)),
      name: notificaitonName,
      object: nil)
  }

  func removeNotificationObserver() {
//    CCHDarwinNotificationCenter.stopForwardingDarwinNotifications(withIdentifier: notificationNameRaw)
    ExHelper.shared.removeObserver(self, name: notificationNameRaw)
//    CFNotificationCenterRemoveObserver(
//      CFNotificationCenterGetDarwinNotifyCenter(),
//      Unmanaged.passUnretained(self).toOpaque(),
//      notificaitonName,
//      nil)

    print("\(self).\(#function)")
  }

  @objc func handleNotification(_ notification: NSNotification) {
    print("\(self).\(#function) \(notification)")

    getRecordFile()
  }

  func videoFileLocation() -> URL {
    let documentsPath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup)!
    let videoOutputUrl = documentsPath
      .appendingPathComponent("Library/Caches/mobile")
      .appendingPathExtension("mp4")

    return videoOutputUrl
  }

  func getRecordFile() {
    let path = videoFileLocation()
    let exists = fileManager.fileExists(atPath: path.path())

    print("\(self).\(#function) file exists: \(exists)")
  }
}

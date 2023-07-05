#  ReplayKit2 系统级屏幕录制小结

1. 实现 Extention 录制结束后，将录制结果形成视频，存储到相册中
2. 使用 CFNotificationCenter 实现进程间通信，在录制结束后，App扩展发送通知，主App接受通知
3. 使用 AppGroup 存储文件，并在主App中获取到该视频文件

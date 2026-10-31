import ActivityKit
import CoreMotion
import Flutter
import UIKit
import UniformTypeIdentifiers
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let liveActivity = LiveActivityBridge()
  private let sleep = SleepBridge()
  private let files = FilesBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HaloLiveActivity") {
      liveActivity.attach(to: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HaloFiles") {
      files.attach(to: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HaloWidget") {
      FlutterMethodChannel(name: "halo/widget", binaryMessenger: registrar.messenger())
        .setMethodCallHandler { call, result in
          guard call.method == "update", let values = call.arguments as? [String: Any] else {
            result(FlutterMethodNotImplemented)
            return
          }
          // Shared with the widget extension through the App Group.
          let suite = UserDefaults(suiteName: "group.com.halo.halo")
          for (key, value) in values {
            if let number = value as? NSNumber { suite?.set(number.doubleValue, forKey: key) }
          }
          suite?.set(Date().timeIntervalSince1970 * 1000, forKey: "updatedAt")
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "HaloActivity")
          }
          result(nil)
        }
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HaloSleep") {
      sleep.attach(to: registrar.messenger())
    }
  }
}

// MARK: - Live Activity

/// The workout in progress on the lock screen and in the Dynamic Island.
///
/// The widget extension (ios/HaloWidgets) declares the same type under the
/// same name; ActivityKit matches the two by name and encoding.
struct WorkoutActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    /// When the workout would have started had it never paused, so the
    /// time can run on the lock screen without updates.
    var timerStart: Date
    /// Set while paused: the time to show standing still.
    var pausedClock: String?
    var energy: String
    var distance: String?
    var pace: String?
    var progress: Double?
  }

  var title: String
  var symbol: String
  var goal: String?
}

/// `halo/live_activity` on iOS: start, update and end the Live Activity.
final class LiveActivityBridge {
  private var activity: Any?

  func attach(to messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "halo/live_activity", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.2, *) else {
      result(nil)
      return
    }
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "start":
      start(args)
      result(nil)
    case "update":
      update(args)
      result(nil)
    case "end":
      end()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @available(iOS 16.2, *)
  private func state(_ args: [String: Any]) -> WorkoutActivityAttributes.ContentState {
    let elapsed = (args["elapsedMs"] as? NSNumber)?.doubleValue ?? 0
    let paused = args["paused"] as? Bool ?? false
    return WorkoutActivityAttributes.ContentState(
      timerStart: Date().addingTimeInterval(-elapsed / 1000),
      pausedClock: paused ? args["clock"] as? String : nil,
      energy: args["energy"] as? String ?? "",
      distance: args["distance"] as? String,
      pace: args["pace"] as? String,
      progress: (args["progress"] as? NSNumber)?.doubleValue
    )
  }

  @available(iOS 16.2, *)
  private func start(_ args: [String: Any]) {
    end()
    // Turned off in Settings: iOS records in the background without it.
    if args["quiet"] as? Bool ?? false { return }
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    let attributes = WorkoutActivityAttributes(
      title: args["title"] as? String ?? "Workout",
      symbol: args["symbol"] as? String ?? "figure.mixed.cardio",
      goal: args["goal"] as? String
    )
    activity = try? Activity.request(
      attributes: attributes,
      content: ActivityContent(state: state(args), staleDate: nil),
      pushType: nil
    )
  }

  @available(iOS 16.2, *)
  private func update(_ args: [String: Any]) {
    guard let activity = activity as? Activity<WorkoutActivityAttributes> else {
      start(args)
      return
    }
    let content = ActivityContent(state: state(args), staleDate: nil)
    Task { await activity.update(content) }
  }

  @available(iOS 16.2, *)
  private func end() {
    guard let activity = activity as? Activity<WorkoutActivityAttributes> else { return }
    self.activity = nil
    Task { await activity.end(nil, dismissalPolicy: .immediate) }
  }
}

// MARK: - Sleep

/// `halo/sleep` and `halo/sleep/minutes` on iOS: the bed's movement, minute by
/// minute, from the accelerometer.
///
/// iOS does not let an app read the accelerometer once it is in the
/// background, so on iPhone the night is tracked while Halo stays open on the
/// bedside, ideally on its charger. The counting matches Android's.
final class SleepBridge: NSObject, FlutterStreamHandler {
  private let motion = CMMotionManager()
  private let queue = OperationQueue()
  private var sink: FlutterEventSink?
  private var pending: [[String: Int]] = []

  private var start = Date()
  private var minute = -1
  private var movingSeconds = 0
  private var lastSecond = -1
  private var secondMoved = false
  private var gravity: (Double, Double, Double)?

  private static let threshold = 0.12 / 9.81  // in g, as CoreMotion reports
  private static let alpha = 0.9

  func attach(to messenger: FlutterBinaryMessenger) {
    let methods = FlutterMethodChannel(name: "halo/sleep", binaryMessenger: messenger)
    methods.setMethodCallHandler { [weak self] call, result in
      guard let self else { return }
      switch call.method {
      case "start":
        let args = call.arguments as? [String: Any]
        let ms = (args?["startMs"] as? NSNumber)?.doubleValue
        self.begin(at: ms.map { Date(timeIntervalSince1970: $0 / 1000) } ?? Date())
        result(true)
      case "stop":
        self.end()
        result(nil)
      case "isRunning":
        result(self.motion.isAccelerometerActive)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    FlutterEventChannel(name: "halo/sleep/minutes", binaryMessenger: messenger)
      .setStreamHandler(self)
  }

  private func begin(at date: Date) {
    guard motion.isAccelerometerAvailable, !motion.isAccelerometerActive else { return }
    start = date
    minute = -1
    gravity = nil
    queue.maxConcurrentOperationCount = 1
    motion.accelerometerUpdateInterval = 0.1
    UIApplication.shared.isIdleTimerDisabled = true
    motion.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
      guard let self, let a = data?.acceleration else { return }
      self.sample(a.x, a.y, a.z)
    }
  }

  private func end() {
    motion.stopAccelerometerUpdates()
    UIApplication.shared.isIdleTimerDisabled = false
    // On the sensor queue, after any sample still in flight.
    queue.addOperation { [weak self] in
      guard let self else { return }
      if self.minute >= 0 {
        self.emit(self.minute, self.movingSeconds + (self.secondMoved ? 1 : 0))
      }
      self.minute = -1
    }
  }

  private func sample(_ x: Double, _ y: Double, _ z: Double) {
    guard let g = gravity else {
      gravity = (x, y, z)
      return
    }
    let a = Self.alpha
    let next = (a * g.0 + (1 - a) * x, a * g.1 + (1 - a) * y, a * g.2 + (1 - a) * z)
    gravity = next
    let lx = x - next.0, ly = y - next.1, lz = z - next.2
    let moved = (lx * lx + ly * ly + lz * lz).squareRoot() > Self.threshold

    let elapsed = Date().timeIntervalSince(start)
    let second = Int(elapsed)
    if second != lastSecond {
      if secondMoved { movingSeconds += 1 }
      secondMoved = false
      lastSecond = second
    }
    if moved { secondMoved = true }

    let m = Int(elapsed / 60)
    if m != minute {
      if minute >= 0 { emit(minute, movingSeconds) }
      minute = m
      movingSeconds = 0
    }
  }

  private func emit(_ minute: Int, _ count: Int) {
    let event = ["minute": minute, "count": count]
    DispatchQueue.main.async {
      if let sink = self.sink { sink(event) } else { self.pending.append(event) }
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    sink = events
    pending.forEach { events($0) }
    pending.removeAll()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }
}

// MARK: - Files

/// `halo/files` on iOS: export writes a folder of CSV files and offers it to
/// the Files app; import opens CSV files the user picks.
final class FilesBridge: NSObject, UIDocumentPickerDelegate {
  private var pending: FlutterResult?
  private var exporting = false

  func attach(to messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "halo/files", binaryMessenger: messenger)
      .setMethodCallHandler { [weak self] call, result in
        guard let self else { return }
        guard self.pending == nil else {
          result(FlutterError(code: "busy", message: "A file picker is open.", details: nil))
          return
        }
        switch call.method {
        case "export":
          let args = call.arguments as? [String: Any] ?? [:]
          let folder = args["folder"] as? String ?? "Halo Export"
          let files = args["files"] as? [String: String] ?? [:]
          self.export(folder: folder, files: files, result: result)
        case "import":
          self.pick(result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
  }

  private func presenter() -> UIViewController? {
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
    var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
    while let next = top?.presentedViewController { top = next }
    return top
  }

  private func export(folder: String, files: [String: String], result: @escaping FlutterResult) {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(folder)
    do {
      try? FileManager.default.removeItem(at: dir)
      try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
      for (name, content) in files {
        try content.write(to: dir.appendingPathComponent(name), atomically: true, encoding: .utf8)
      }
    } catch {
      result(FlutterError(code: "io", message: error.localizedDescription, details: nil))
      return
    }
    let picker = UIDocumentPickerViewController(forExporting: [dir], asCopy: true)
    picker.delegate = self
    pending = result
    exporting = true
    presenter()?.present(picker, animated: true)
  }

  private func pick(result: @escaping FlutterResult) {
    let picker = UIDocumentPickerViewController(
      forOpeningContentTypes: [.commaSeparatedText, .plainText], asCopy: true)
    picker.allowsMultipleSelection = true
    picker.delegate = self
    pending = result
    exporting = false
    presenter()?.present(picker, animated: true)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let result = pending else { return }
    pending = nil
    if exporting {
      result(true)
      return
    }
    var out: [String: String] = [:]
    for url in urls {
      if let text = try? String(contentsOf: url, encoding: .utf8) {
        out[url.lastPathComponent] = text
      }
    }
    result(out)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    guard let result = pending else { return }
    pending = nil
    result(exporting ? false : nil)
  }
}

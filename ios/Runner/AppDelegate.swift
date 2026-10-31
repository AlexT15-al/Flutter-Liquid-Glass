import ActivityKit
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let liveActivity = LiveActivityBridge()

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

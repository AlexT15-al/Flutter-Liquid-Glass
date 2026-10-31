import ActivityKit
import SwiftUI
import WidgetKit

/// Must match the declaration in Runner/AppDelegate.swift exactly: ActivityKit
/// pairs the app's activity with this widget by the type's name and encoding.
struct WorkoutActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var timerStart: Date
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

/// Apple Fitness green, Halo's accent.
private let accent = Color(red: 0xA6 / 255, green: 1, blue: 0)

/// The time: running on its own, or standing still while paused.
private struct WorkoutTime: View {
  let state: WorkoutActivityAttributes.ContentState

  var body: some View {
    if let paused = state.pausedClock {
      Text(paused)
    } else {
      Text(timerInterval: state.timerStart...Date.distantFuture, countsDown: false)
    }
  }
}

private struct Metrics: View {
  let state: WorkoutActivityAttributes.ContentState

  var body: some View {
    HStack(spacing: 14) {
      if let distance = state.distance { Text(distance) }
      Text(state.energy)
      if let pace = state.pace { Text(pace) }
    }
    .font(.subheadline.weight(.semibold))
    .monospacedDigit()
    .foregroundStyle(.secondary)
  }
}

struct WorkoutLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
      // Lock screen and notification banner.
      VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .center, spacing: 12) {
          Image(systemName: context.attributes.symbol)
            .font(.title2.weight(.semibold))
            .foregroundStyle(.black)
            .frame(width: 44, height: 44)
            .background(Circle().fill(accent))
          VStack(alignment: .leading, spacing: 2) {
            Text(context.state.pausedClock == nil ? context.attributes.title : "Paused")
              .font(.headline)
            Metrics(state: context.state)
          }
          Spacer(minLength: 8)
          WorkoutTime(state: context.state)
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(accent)
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: 120, alignment: .trailing)
        }
        if let progress = context.state.progress {
          ProgressView(value: progress)
            .tint(accent)
        }
      }
      .padding(16)
      .activityBackgroundTint(Color.black.opacity(0.85))
      .activitySystemActionForegroundColor(accent)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label {
            Text(context.attributes.title).font(.headline)
          } icon: {
            Image(systemName: context.attributes.symbol).foregroundStyle(accent)
          }
        }
        DynamicIslandExpandedRegion(.trailing) {
          WorkoutTime(state: context.state)
            .font(.title2.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(accent)
            .frame(maxWidth: 100, alignment: .trailing)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(spacing: 8) {
            Metrics(state: context.state)
            if let progress = context.state.progress {
              ProgressView(value: progress).tint(accent)
            }
          }
        }
      } compactLeading: {
        Image(systemName: context.attributes.symbol)
          .foregroundStyle(accent)
      } compactTrailing: {
        WorkoutTime(state: context.state)
          .monospacedDigit()
          .foregroundStyle(accent)
          .frame(maxWidth: 52)
      } minimal: {
        Image(systemName: context.attributes.symbol)
          .foregroundStyle(accent)
      }
      .keylineTint(accent)
    }
  }
}

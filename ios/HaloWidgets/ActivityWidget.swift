import SwiftUI
import WidgetKit

/// Shared with the app through the App Group (see README).
private let suite = UserDefaults(suiteName: "group.com.halo.halo")

struct ActivityEntry: TimelineEntry {
  let date: Date
  let move: Double, moveGoal: Double
  let exercise: Double, exerciseGoal: Double
  let hours: Double, hoursGoal: Double
  let steps: Double

  static let placeholder = ActivityEntry(
    date: .now, move: 276, moveGoal: 400, exercise: 22, exerciseGoal: 30,
    hours: 7, hoursGoal: 10, steps: 6_420)

  /// Today's snapshot as the app left it; an earlier day reads as empty.
  static func current() -> ActivityEntry {
    let d = suite
    let updated = Date(timeIntervalSince1970: (d?.double(forKey: "updatedAt") ?? 0) / 1000)
    let today = Calendar.current.isDateInToday(updated)
    func value(_ key: String) -> Double { today ? (d?.double(forKey: key) ?? 0) : 0 }
    func goal(_ key: String, _ fallback: Double) -> Double {
      max(1, d?.object(forKey: key) == nil ? fallback : d!.double(forKey: key))
    }
    return ActivityEntry(
      date: .now,
      move: value("move"), moveGoal: goal("moveGoal", 400),
      exercise: value("exercise"), exerciseGoal: goal("exerciseGoal", 30),
      hours: value("activeHours"), hoursGoal: goal("activeHoursGoal", 10),
      steps: value("steps"))
  }
}

struct ActivityProvider: TimelineProvider {
  func placeholder(in context: Context) -> ActivityEntry { .placeholder }

  func getSnapshot(in context: Context, completion: @escaping (ActivityEntry) -> Void) {
    completion(context.isPreview ? .placeholder : .current())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ActivityEntry>) -> Void) {
    // The app reloads the timeline when the day changes; midnight empties it.
    let midnight = Calendar.current.startOfDay(for: .now).addingTimeInterval(86_400)
    completion(Timeline(entries: [.current()], policy: .after(midnight)))
  }
}

private struct Rings: View {
  let entry: ActivityEntry
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let dark = scheme == .dark
    let colors: [Color] = [
      Color(red: 0.98, green: 0.07, blue: 0.31),
      dark ? Color(red: 0.65, green: 1, blue: 0) : Color(red: 0.29, green: 0.56, blue: 0),
      dark ? Color(red: 0.12, green: 0.92, blue: 0.94) : Color(red: 0, green: 0.58, blue: 0.66),
    ]
    let values = [
      entry.move / entry.moveGoal, entry.exercise / entry.exerciseGoal,
      entry.hours / entry.hoursGoal,
    ]
    GeometryReader { geo in
      let size = min(geo.size.width, geo.size.height)
      let stroke = size * 0.11
      ZStack {
        ForEach(0..<3) { i in
          let inset = stroke / 2 + CGFloat(i) * (stroke + size * 0.02)
          Circle()
            .stroke(colors[i].opacity(0.22), lineWidth: stroke)
            .padding(inset)
          Circle()
            .trim(from: 0, to: min(1, values[i]))
            .stroke(colors[i], style: StrokeStyle(lineWidth: stroke, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .padding(inset)
        }
      }
      .frame(width: size, height: size)
    }
  }
}

struct ActivityWidgetView: View {
  let entry: ActivityEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    switch family {
    case .systemSmall:
      VStack(spacing: 8) {
        Rings(entry: entry)
        Text("\(Int(entry.steps)) steps")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
      }
      .containerBackground(.background, for: .widget)
    default:
      HStack(spacing: 16) {
        Rings(entry: entry).frame(width: 112, height: 112)
        VStack(alignment: .leading, spacing: 2) {
          row("Move", "\(Int(entry.move))/\(Int(entry.moveGoal)) KCAL")
          row("Exercise", "\(Int(entry.exercise))/\(Int(entry.exerciseGoal)) MIN")
          row("Active Hours", "\(Int(entry.hours))/\(Int(entry.hoursGoal)) HRS")
          Text("\(Int(entry.steps)) steps")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.top, 2)
        }
        Spacer(minLength: 0)
      }
      .containerBackground(.background, for: .widget)
    }
  }

  private func row(_ title: String, _ value: String) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
      Text(value).font(.headline).monospacedDigit()
    }
  }
}

struct ActivityWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "HaloActivity", provider: ActivityProvider()) { entry in
      ActivityWidgetView(entry: entry)
    }
    .configurationDisplayName("Activity")
    .description("Today's rings and steps.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

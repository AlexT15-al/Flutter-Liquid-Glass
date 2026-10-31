# HaloWidgets: the home screen widget and the workout Live Activity on iOS

The app side is already in place (`Runner/AppDelegate.swift`, `NSSupportsLiveActivities`).
The lock screen and Dynamic Island views live in a widget extension, which is a separate
Xcode target. Xcode has to create the target once:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. File › New › Target… › **Widget Extension**. Name it `HaloWidgets`, untick
   *Include Configuration App Intent*, tick *Include Live Activity*. When asked, activate the scheme.
3. Xcode creates a `HaloWidgets` folder with sample files. Delete those sample files, then drag
   in the four files from this folder (`HaloWidgetsBundle.swift`, `ActivityWidget.swift`,
   `WorkoutLiveActivity.swift`, `Info.plist`) with only the **HaloWidgets** target ticked.
4. Set the extension's deployment target to iOS 17 or later.
5. For the home screen widget, add the **App Groups** capability to both the
   Runner and the HaloWidgets targets, with the group `group.com.halo.halo`:
   the app writes today's numbers there and the widget reads them.

`WorkoutActivityAttributes` is declared in both targets on purpose; keep the two identical.

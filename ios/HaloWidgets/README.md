# HaloWidgets: the workout Live Activity on iOS

The app side is already in place (`Runner/AppDelegate.swift`, `NSSupportsLiveActivities`).
The lock screen and Dynamic Island views live in a widget extension, which is a separate
Xcode target. Xcode has to create the target once:

1. Open `ios/Runner.xcworkspace` in Xcode.
2. File › New › Target… › **Widget Extension**. Name it `HaloWidgets`, untick
   *Include Configuration App Intent*, tick *Include Live Activity*. When asked, activate the scheme.
3. Xcode creates a `HaloWidgets` folder with sample files. Delete those sample files, then drag
   in the three files from this folder (`HaloWidgetsBundle.swift`, `WorkoutLiveActivity.swift`,
   `Info.plist`) with only the **HaloWidgets** target ticked.
4. Set the extension's deployment target to iOS 16.2 or later.

`WorkoutActivityAttributes` is declared in both targets on purpose; keep the two identical.

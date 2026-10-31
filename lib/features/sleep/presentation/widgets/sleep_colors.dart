import 'package:flutter/cupertino.dart';

import '../../../../app/theme/halo_colors.dart';
import '../../../../domain/sleep.dart';

/// The colour of each stage, resolved for the current appearance.
Color stageColor(BuildContext context, SleepStage stage) => switch (stage) {
  SleepStage.awake => HaloColors.sleepAwake,
  SleepStage.rem => HaloColors.sleepRem,
  SleepStage.light => HaloColors.sleepLight,
  SleepStage.deep => HaloColors.sleepDeep,
}.resolveFrom(context);

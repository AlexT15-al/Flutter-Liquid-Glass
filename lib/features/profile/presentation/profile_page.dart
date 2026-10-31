import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../app/halo_scope.dart';
import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_glass.dart';
import '../../../app/theme/halo_metrics.dart';
import '../../../data/preferences/halo_preferences.dart';
import '../../../domain/avatar_preset.dart';
import '../../../domain/body_profile.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/grouped_list.dart';
import '../../../shared/widgets/halo_page.dart';
import '../../../shared/widgets/profile_avatar.dart';
import 'avatar_sheet.dart';

/// Health Details: who the user is, as far as the numbers need to know.
///
/// Every value is edited in place, the way iOS edits a date in Calendar: tap
/// the row and its wheel unfolds beneath it. Each change is written as it is
/// made, so there is no Edit mode and nothing to save.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static Route<void> route() =>
      CupertinoPageRoute<void>(builder: (_) => const ProfilePage());

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Stream<BodyProfile>? _profile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profile ??= HaloScope.preferencesOf(context).watchProfile();
  }

  @override
  Widget build(BuildContext context) {
    final preferences = HaloScope.preferencesOf(context);

    return HaloPage(
      appBar: haloBar(context, title: 'Profile'),
      body: StreamBuilder<BodyProfile>(
        stream: _profile,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          if (profile == null) return const SizedBox.shrink();
          void save(BodyProfile next) => preferences.setProfile(next);

          return ListView(
            padding: EdgeInsets.fromLTRB(
              HaloMetrics.cardPadding,
              HaloMetrics.topInset(context),
              HaloMetrics.cardPadding,
              HaloMetrics.bottomInset(context),
            ),
            children: [
              _Header(profile: profile, preferences: preferences),
              const SizedBox(height: 28),
              const GroupCaption('Health Details'),
              GroupedCard(
                children: [
                  GroupedRow(
                    title: 'Date of Birth',
                    value: profile.birthDate == null
                        ? 'Not Set'
                        : '${profile.birthDate!.day} '
                            '${Format.monthName(profile.birthDate!)} '
                            '${profile.birthDate!.year}',
                    editor: _BirthDateEditor(
                      initial: profile.birthDate,
                      onChanged: (date) =>
                          save(profile.copyWith(birthDate: date)),
                    ),
                  ),
                  GroupedRow(
                    title: 'Sex',
                    value: switch (profile.sex) {
                      BiologicalSex.female => 'Female',
                      BiologicalSex.male => 'Male',
                      BiologicalSex.unspecified => 'Not Set',
                    },
                    editor: _SexEditor(
                      value: profile.sex,
                      onChanged: (sex) => save(profile.copyWith(sex: sex)),
                    ),
                  ),
                  GroupedRow(
                    title: 'Height',
                    value: '${profile.heightCm.round()} cm',
                    editor: _HeightEditor(
                      initial: profile.heightCm.round(),
                      onChanged: (cm) =>
                          save(profile.copyWith(heightCm: cm.toDouble())),
                    ),
                  ),
                  GroupedRow(
                    title: 'Weight',
                    value: '${profile.weightKg.toStringAsFixed(1)} kg',
                    editor: _WeightEditor(
                      initial: profile.weightKg,
                      onChanged: (kg) => save(profile.copyWith(weightKg: kg)),
                    ),
                  ),
                ],
              ),
              const GroupCaption(
                'Halo uses these to estimate distance and energy from your '
                'steps, and later your heart-rate zones.',
                footer: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The avatar and the name.
class _Header extends StatefulWidget {
  const _Header({required this.profile, required this.preferences});

  final BodyProfile profile;
  final HaloPreferences preferences;

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  late final TextEditingController _name =
      TextEditingController(text: widget.profile.name ?? '');
  Timer? _save;

  @override
  void dispose() {
    // Whatever was typed last is kept even if the page closes mid-word.
    if (_save?.isActive ?? false) {
      _save!.cancel();
      _write();
    }
    _name.dispose();
    super.dispose();
  }

  /// Written a moment after typing stops rather than per keystroke.
  void _changed(String _) {
    _save?.cancel();
    _save = Timer(const Duration(milliseconds: 500), _write);
    setState(() {});
  }

  void _write() =>
      widget.preferences.setProfile(widget.profile.withName(_name.text));

  Future<void> _chooseAvatar() async {
    final chosen = await showAvatarSheet(
      context,
      name: _name.text,
      current: widget.profile.avatar,
    );
    if (chosen == null || !mounted) return;
    await widget.preferences.setProfile(
      widget.profile.withAvatar(chosen.isEmpty ? null : chosen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _chooseAvatar,
          child: Column(
            children: [
              ProfileAvatar(
                name: _name.text,
                preset: AvatarPreset.byName(widget.profile.avatar),
                size: 92,
              ),
              const SizedBox(height: 8),
              // iOS Contacts' cue under the photo: the avatar is editable.
              Text(
                'Edit',
                style: TextStyle(
                  color: HaloColors.accent.resolveFrom(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: _name,
          onChanged: _changed,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.words,
          placeholder: 'Your Name',
          decoration: null,
          style: TextStyle(
            color: HaloColors.labelOf(context),
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          placeholderStyle: TextStyle(
            color: HaloColors.tertiaryLabelOf(context),
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

class _BirthDateEditor extends StatelessWidget {
  const _BirthDateEditor({required this.initial, required this.onChanged});

  final DateTime? initial;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return RowWheel(
      child: CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: initial ?? DateTime(now.year - 30, 1, 1),
        minimumYear: 1900,
        maximumDate: now,
        onDateTimeChanged: onChanged,
      ),
    );
  }
}

class _SexEditor extends StatelessWidget {
  const _SexEditor({required this.value, required this.onChanged});

  final BiologicalSex value;
  final ValueChanged<BiologicalSex> onChanged;

  static const _order = [
    BiologicalSex.female,
    BiologicalSex.male,
    BiologicalSex.unspecified,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
      child: GlassSegmentedControl(
        segments: const [
          GlassSegment(label: 'Female'),
          GlassSegment(label: 'Male'),
          GlassSegment(label: 'Not Set'),
        ],
        selectedIndex: _order.indexOf(value),
        onSegmentSelected: (index) => onChanged(_order[index]),
        height: 38,
        borderRadius: 19,
        settings: HaloGlass.of(context),
        quality: HaloGlass.quality,
        useOwnLayer: true,
        // The control replaces the ambient text style, so it is handed the
        // app's own, font family included.
        selectedTextStyle: DefaultTextStyle.of(context).style.copyWith(
          color: HaloColors.labelOf(context),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        unselectedTextStyle: DefaultTextStyle.of(context).style.copyWith(
          color: HaloColors.secondaryLabelOf(context),
          fontSize: 15,
        ),
      ),
    );
  }
}

class _HeightEditor extends StatefulWidget {
  const _HeightEditor({required this.initial, required this.onChanged});

  final int initial;
  final ValueChanged<int> onChanged;

  @override
  State<_HeightEditor> createState() => _HeightEditorState();
}

class _HeightEditorState extends State<_HeightEditor> {
  static const _min = 100;
  static const _max = 230;

  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(
    initialItem: (widget.initial - _min).clamp(0, _max - _min),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RowWheel(
      child: CupertinoPicker(
        scrollController: _controller,
        itemExtent: 34,
        onSelectedItemChanged: (index) => widget.onChanged(_min + index),
        children: [
          for (var cm = _min; cm <= _max; cm++) Center(child: Text('$cm cm')),
        ],
      ),
    );
  }
}

/// Two wheels, kilograms and tenths, as Health edits weight.
class _WeightEditor extends StatefulWidget {
  const _WeightEditor({required this.initial, required this.onChanged});

  final double initial;
  final ValueChanged<double> onChanged;

  @override
  State<_WeightEditor> createState() => _WeightEditorState();
}

class _WeightEditorState extends State<_WeightEditor> {
  static const _min = 30;
  static const _max = 250;

  late int _whole = widget.initial.floor().clamp(_min, _max);
  late int _tenth = ((widget.initial - widget.initial.floor()) * 10).round() % 10;

  late final _wholeController =
      FixedExtentScrollController(initialItem: _whole - _min);
  late final _tenthController = FixedExtentScrollController(initialItem: _tenth);

  @override
  void dispose() {
    _wholeController.dispose();
    _tenthController.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(_whole + _tenth / 10);

  @override
  Widget build(BuildContext context) {
    return RowWheel(
      child: Row(
        children: [
          Expanded(
            child: CupertinoPicker(
              scrollController: _wholeController,
              itemExtent: 34,
              onSelectedItemChanged: (index) {
                _whole = _min + index;
                _emit();
              },
              children: [
                for (var kg = _min; kg <= _max; kg++)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text('$kg'),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: CupertinoPicker(
              scrollController: _tenthController,
              itemExtent: 34,
              onSelectedItemChanged: (index) {
                _tenth = index;
                _emit();
              },
              children: [
                for (var t = 0; t < 10; t++)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text('.$t kg'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

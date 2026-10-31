/// What the app knows about the user's body: enough to turn steps into
/// distance and energy.
///
/// Every field has a default, so the activity numbers are sensible from the
/// first launch and only get more accurate once the Profile page is filled in.
class BodyProfile {
  const BodyProfile({
    this.heightCm = 170,
    this.weightKg = 70,
    this.birthYear,
    this.sex = BiologicalSex.unspecified,
  });

  final double heightCm;
  final double weightKg;
  final int? birthYear;
  final BiologicalSex sex;

  /// The profile the app starts with.
  static const fallback = BodyProfile();

  /// Walking step length from height: the standard 0.415 × height for men and
  /// 0.413 for women, which is close enough to use 0.414 when unknown.
  double get walkingStrideMeters {
    final factor = switch (sex) {
      BiologicalSex.male => 0.415,
      BiologicalSex.female => 0.413,
      BiologicalSex.unspecified => 0.414,
    };
    return heightCm / 100 * factor;
  }

  Map<String, Object?> toJson() => {
        'heightCm': heightCm,
        'weightKg': weightKg,
        'birthYear': birthYear,
        'sex': sex.name,
      };

  factory BodyProfile.fromJson(Map<String, Object?> json) => BodyProfile(
        heightCm: (json['heightCm'] as num?)?.toDouble() ?? fallback.heightCm,
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? fallback.weightKg,
        birthYear: (json['birthYear'] as num?)?.toInt(),
        sex: BiologicalSex.values.asNameMap()[json['sex']] ??
            BiologicalSex.unspecified,
      );
}

enum BiologicalSex { female, male, unspecified }

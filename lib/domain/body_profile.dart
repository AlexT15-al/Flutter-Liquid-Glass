/// What the app knows about the user's body: enough to turn steps into
/// distance and energy.
///
/// Every field has a default, so the activity numbers are sensible from the
/// first launch and only get more accurate once the Profile page is filled in.
class BodyProfile {
  const BodyProfile({
    this.name,
    this.avatar,
    this.heightCm = 170,
    this.weightKg = 70,
    this.birthDate,
    this.sex = BiologicalSex.unspecified,
  });

  /// What the app calls the user. Optional; the account button shows initials
  /// when there is one.
  final String? name;

  /// The chosen avatar preset, by name. Null shows the initials.
  final String? avatar;

  final double heightCm;
  final double weightKg;
  final DateTime? birthDate;
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

  /// Body mass index: kilograms over metres squared.
  double get bmi => Bmi.of(weightKg, heightCm);

  /// Age in whole years on [today], or null without a birth date.
  int? ageOn(DateTime today) {
    final born = birthDate;
    if (born == null) return null;
    final hadBirthday =
        today.month > born.month ||
        (today.month == born.month && today.day >= born.day);
    return today.year - born.year - (hadBirthday ? 0 : 1);
  }

  /// Replaces the avatar; null goes back to the initials. Separate from
  /// [copyWith], which cannot tell "set to null" from "leave alone".
  BodyProfile withAvatar(String? avatar) => BodyProfile(
    name: name,
    avatar: avatar,
    heightCm: heightCm,
    weightKg: weightKg,
    birthDate: birthDate,
    sex: sex,
  );

  /// Replaces the name; null or blank clears it.
  BodyProfile withName(String? name) => BodyProfile(
    name: (name == null || name.trim().isEmpty) ? null : name.trim(),
    avatar: avatar,
    heightCm: heightCm,
    weightKg: weightKg,
    birthDate: birthDate,
    sex: sex,
  );

  BodyProfile copyWith({
    String? name,
    double? heightCm,
    double? weightKg,
    DateTime? birthDate,
    BiologicalSex? sex,
  }) => BodyProfile(
    name: name ?? this.name,
    avatar: avatar,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    birthDate: birthDate ?? this.birthDate,
    sex: sex ?? this.sex,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'avatar': avatar,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'birthDate': birthDate?.toIso8601String(),
    'sex': sex.name,
  };

  factory BodyProfile.fromJson(Map<String, Object?> json) => BodyProfile(
    name: json['name'] as String?,
    avatar: json['avatar'] as String?,
    heightCm: (json['heightCm'] as num?)?.toDouble() ?? fallback.heightCm,
    weightKg: (json['weightKg'] as num?)?.toDouble() ?? fallback.weightKg,
    birthDate: DateTime.tryParse(json['birthDate'] as String? ?? ''),
    sex:
        BiologicalSex.values.asNameMap()[json['sex']] ??
        BiologicalSex.unspecified,
  );
}

enum BiologicalSex { female, male, unspecified }

/// The WHO's adult bands of body mass index.
enum BmiCategory {
  underweight('Underweight', 0, 18.5),
  healthy('Healthy Weight', 18.5, 25),
  overweight('Overweight', 25, 30),
  obese('Obesity', 30, double.infinity);

  const BmiCategory(this.title, this.from, this.to);

  final String title;
  final double from;
  final double to;
}

/// Body mass index, and what it says and does not.
///
/// A screening number from height and weight alone: it cannot tell muscle
/// from fat, so a strong, lean person can read as overweight. A guide to a
/// sensible target weight, not a verdict.
abstract final class Bmi {
  static double of(double kg, double heightCm) {
    final m = heightCm / 100;
    return m <= 0 ? 0 : kg / (m * m);
  }

  static BmiCategory category(double bmi) =>
      BmiCategory.values.lastWhere((c) => bmi >= c.from);

  /// The weights in the healthy band for a height, rounded inwards to the
  /// kilogram.
  static (int, int) healthyRange(double heightCm) {
    final m2 = (heightCm / 100) * (heightCm / 100);
    return (
      (BmiCategory.healthy.from * m2).ceil(),
      (BmiCategory.healthy.to * m2 - 0.05).floor(),
    );
  }
}

import 'package:flutter/foundation.dart';

import 'package:smartbudget/core/money/money.dart';

/// Time-horizon "compartment" a project is filed under.
enum ProjectHorizon { near, mid, long }

extension ProjectHorizonX on ProjectHorizon {
  /// Planning horizon (months) used when a project has no explicit target date,
  /// so the funding math still has a sensible timeframe.
  int get defaultMonths => switch (this) {
        ProjectHorizon.near => 9, // ≤ 1 year
        ProjectHorizon.mid => 24, // 1–3 years
        ProjectHorizon.long => 48, // > 3 years
      };
}

/// A funded project inside the investment/projects portfolio.
///
/// Like [Goal], `saved` is DERIVED — it grows only through explicit
/// contributions, never a free-typed seed. User inputs: name, target, horizon,
/// optional target date and note.
@immutable
class Project {
  const Project({
    required this.id,
    required this.name,
    required this.target,
    required this.saved,
    required this.horizon,
    this.targetDate,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String name;
  final Money target;
  final Money saved;
  final ProjectHorizon horizon;
  final DateTime? targetDate;
  final String? note;
  final DateTime createdAt;

  Project copyWith({
    String? name,
    Money? target,
    Money? saved,
    ProjectHorizon? horizon,
    DateTime? targetDate,
    bool clearTargetDate = false,
    String? note,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      target: target ?? this.target,
      saved: saved ?? this.saved,
      horizon: horizon ?? this.horizon,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'targetMinor': target.minorUnits,
        'savedMinor': saved.minorUnits,
        'currency': target.currencyCode,
        'horizon': horizon.name,
        'targetDate': targetDate?.toIso8601String(),
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Project.fromJson(Map<String, dynamic> json) {
    final String currency = (json['currency'] as String?) ?? 'USD';
    return Project(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      target: Money((json['targetMinor'] as num?)?.toInt() ?? 0, currency),
      saved: Money((json['savedMinor'] as num?)?.toInt() ?? 0, currency),
      horizon: ProjectHorizon.values.firstWhere(
        (ProjectHorizon h) => h.name == json['horizon'],
        orElse: () => ProjectHorizon.mid,
      ),
      targetDate: (json['targetDate'] as String?) == null
          ? null
          : DateTime.tryParse(json['targetDate'] as String),
      note: json['note'] as String?,
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
              DateTime.now(),
    );
  }
}

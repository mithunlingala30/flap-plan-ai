/// Mirrors src/lib/types.ts from the original web app.

enum Sex { male, female }

enum YesNo { yes, no }

enum SurgicalProcedure { flapSurgery, gtr, laserSurgery, openDebridement }

enum HealingOutcome { poor, fair, good, excellent }

extension SexX on Sex {
  String get label => this == Sex.male ? 'Male' : 'Female';
  static Sex fromLabel(String s) => s == 'Male' ? Sex.male : Sex.female;
}

extension YesNoX on YesNo {
  String get label => this == YesNo.yes ? 'Yes' : 'No';
  static YesNo fromLabel(String s) => s == 'Yes' ? YesNo.yes : YesNo.no;
}

extension SurgicalProcedureX on SurgicalProcedure {
  String get label {
    switch (this) {
      case SurgicalProcedure.flapSurgery:
        return 'Flap Surgery';
      case SurgicalProcedure.gtr:
        return 'GTR';
      case SurgicalProcedure.laserSurgery:
        return 'Laser Surgery';
      case SurgicalProcedure.openDebridement:
        return 'Open Debridement';
    }
  }

  static SurgicalProcedure fromLabel(String s) {
    return SurgicalProcedure.values.firstWhere(
      (p) => p.label == s,
      orElse: () => SurgicalProcedure.flapSurgery,
    );
  }
}

extension HealingOutcomeX on HealingOutcome {
  String get label {
    switch (this) {
      case HealingOutcome.poor:
        return 'Poor';
      case HealingOutcome.fair:
        return 'Fair';
      case HealingOutcome.good:
        return 'Good';
      case HealingOutcome.excellent:
        return 'Excellent';
    }
  }

  static HealingOutcome fromLabel(String s) {
    switch (s) {
      case 'Poor':
        return HealingOutcome.poor;
      case 'Fair':
        return HealingOutcome.fair;
      case 'Good':
        return HealingOutcome.good;
      case 'Excellent':
        return HealingOutcome.excellent;
      default:
        return HealingOutcome.fair;
    }
  }
}

const List<SurgicalProcedure> kProcedures = [
  SurgicalProcedure.flapSurgery,
  SurgicalProcedure.gtr,
  SurgicalProcedure.laserSurgery,
  SurgicalProcedure.openDebridement,
];

const List<HealingOutcome> kOutcomes = [
  HealingOutcome.poor,
  HealingOutcome.fair,
  HealingOutcome.good,
  HealingOutcome.excellent,
];

class PatientCase {
  final int age;
  final Sex sex;
  final YesNo diabetes;
  final double probingDepth; // mm
  final double clinicalAttachmentLoss; // mm
  final double gingivalIndex; // 0..3
  final double plaqueIndex; // 0..3
  final YesNo bleedingOnProbing;
  final SurgicalProcedure procedure;

  const PatientCase({
    required this.age,
    required this.sex,
    required this.diabetes,
    required this.probingDepth,
    required this.clinicalAttachmentLoss,
    required this.gingivalIndex,
    required this.plaqueIndex,
    required this.bleedingOnProbing,
    required this.procedure,
  });

  static const defaultCase = PatientCase(
    age: 52,
    sex: Sex.female,
    diabetes: YesNo.no,
    probingDepth: 4.5,
    clinicalAttachmentLoss: 2.5,
    gingivalIndex: 1.0,
    plaqueIndex: 1.0,
    bleedingOnProbing: YesNo.no,
    procedure: SurgicalProcedure.flapSurgery,
  );

  PatientCase copyWith({
    int? age,
    Sex? sex,
    YesNo? diabetes,
    double? probingDepth,
    double? clinicalAttachmentLoss,
    double? gingivalIndex,
    double? plaqueIndex,
    YesNo? bleedingOnProbing,
    SurgicalProcedure? procedure,
  }) {
    return PatientCase(
      age: age ?? this.age,
      sex: sex ?? this.sex,
      diabetes: diabetes ?? this.diabetes,
      probingDepth: probingDepth ?? this.probingDepth,
      clinicalAttachmentLoss:
          clinicalAttachmentLoss ?? this.clinicalAttachmentLoss,
      gingivalIndex: gingivalIndex ?? this.gingivalIndex,
      plaqueIndex: plaqueIndex ?? this.plaqueIndex,
      bleedingOnProbing: bleedingOnProbing ?? this.bleedingOnProbing,
      procedure: procedure ?? this.procedure,
    );
  }

  /// JSON body sent to the prediction backend. Adjust key names here if your
  /// FastAPI/Flask model expects a different schema.
  Map<String, dynamic> toApiJson() => {
        'age': age,
        'sex': sex.label,
        'diabetes': diabetes.label,
        'probing_depth': probingDepth,
        'clinical_attachment_loss': clinicalAttachmentLoss,
        'gingival_index': gingivalIndex,
        'plaque_index': plaqueIndex,
        'bleeding_on_probing': bleedingOnProbing.label,
        'procedure': procedure.label,
      };

  Map<String, dynamic> toFirestoreJson() => {
        'age': age,
        'sex': sex.label,
        'diabetes': diabetes.label,
        'probingDepth': probingDepth,
        'clinicalAttachmentLoss': clinicalAttachmentLoss,
        'gingivalIndex': gingivalIndex,
        'plaqueIndex': plaqueIndex,
        'bleedingOnProbing': bleedingOnProbing.label,
        'procedure': procedure.label,
      };

  factory PatientCase.fromFirestoreJson(Map<String, dynamic> j) {
    return PatientCase(
      age: (j['age'] as num).toInt(),
      sex: SexX.fromLabel(j['sex'] as String),
      diabetes: YesNoX.fromLabel(j['diabetes'] as String),
      probingDepth: (j['probingDepth'] as num).toDouble(),
      clinicalAttachmentLoss: (j['clinicalAttachmentLoss'] as num).toDouble(),
      gingivalIndex: (j['gingivalIndex'] as num).toDouble(),
      plaqueIndex: (j['plaqueIndex'] as num).toDouble(),
      bleedingOnProbing: YesNoX.fromLabel(j['bleedingOnProbing'] as String),
      procedure: SurgicalProcedureX.fromLabel(j['procedure'] as String),
    );
  }
}

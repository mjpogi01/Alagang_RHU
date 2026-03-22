/// Sex / gender for demographic data.
enum Sex {
  male('Lalaki'),
  female('Babae'),
  other('Iba pa');

  const Sex(this.label);
  final String label;
}

/// Common comorbidities; can be extended.
const List<String> kComorbidityOptions = [
  'Alta-presyon',
  'Diyabetes',
  'Hika',
  'Tuberkulosis',
  'Sakit sa puso',
  'Sakit sa bato',
  'Wala',
];

/// A family member with demographic data for profile management.
class FamilyMember {
  FamilyMember({
    required this.id,
    this.name,
    required this.dateOfBirth,
    required this.sex,
    this.relation,
    this.pregnancyStatus,
    List<String>? comorbidities,
  }) : comorbidities = comorbidities ?? [];

  final String id;
  final String? name;
  final DateTime dateOfBirth;
  final Sex sex;
  /// Relationship in the family (anak, apo, asawa, etc.).
  final String? relation;
  final bool?
  pregnancyStatus; // true = pregnant, false = not, null = not applicable (e.g. male)
  final List<String> comorbidities;

  /// Age from date of birth (whole years).
  int get age {
    final now = DateTime.now();
    int a = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      a--;
    }
    return a;
  }

  FamilyMember copyWith({
    String? id,
    String? name,
    DateTime? dateOfBirth,
    Sex? sex,
    String? relation,
    bool? pregnancyStatus,
    List<String>? comorbidities,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      relation: relation ?? this.relation,
      pregnancyStatus: pregnancyStatus ?? this.pregnancyStatus,
      comorbidities: comorbidities ?? List<String>.from(this.comorbidities),
    );
  }
}

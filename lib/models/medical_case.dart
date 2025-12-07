class MedicalCase {
  final int? id;
  final String patientName;
  final DateTime date;
  final String audioPath;
  final String transcript;
  final String subjective;
  final String objective;
  final String assessment;
  final String plan;

  MedicalCase({
    this.id,
    required this.patientName,
    required this.date,
    required this.audioPath,
    required this.transcript,
    required this.subjective,
    required this.objective,
    required this.assessment,
    required this.plan,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientName': patientName,
      'date': date.toIso8601String(),
      'audioPath': audioPath,
      'transcript': transcript,
      'subjective': subjective,
      'objective': objective,
      'assessment': assessment,
      'plan': plan,
    };
  }

  factory MedicalCase.fromMap(Map<String, dynamic> map) {
    return MedicalCase(
      id: map['id'],
      patientName: map['patientName'] ?? 'Unknown',
      date: DateTime.parse(map['date']),
      audioPath: map['audioPath'] ?? '',
      transcript: map['transcript'] ?? '',
      subjective: map['subjective'] ?? '',
      objective: map['objective'] ?? '',
      assessment: map['assessment'] ?? '',
      plan: map['plan'] ?? '',
    );
  }
}

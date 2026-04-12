class HistoryModel {
  final String plant;
  final String disease;
  final double confidence;
  final String chemical;
  final String dosage;
  final String date;

  HistoryModel({
    required this.plant,
    required this.disease,
    required this.confidence,
    required this.chemical,
    required this.dosage,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        "plant": plant,
        "disease": disease,
        "confidence": confidence,
        "chemical": chemical,
        "dosage": dosage,
        "date": date,
      };

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      plant: json["plant"],
      disease: json["disease"],
      confidence: json["confidence"],
      chemical: json["chemical"],
      dosage: json["dosage"],
      date: json["date"],
    );
  }
}
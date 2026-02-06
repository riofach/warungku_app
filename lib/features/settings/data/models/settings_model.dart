class SettingsModel {
  final String key;
  final String? value;
  final DateTime updatedAt;

  SettingsModel({
    required this.key,
    this.value,
    required this.updatedAt,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      key: json['key'] as String,
      value: json['value'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

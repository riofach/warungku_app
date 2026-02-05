class SettingsModel {
  final String id;
  final String key;
  final String? value;
  final DateTime updatedAt;

  SettingsModel({
    required this.id,
    required this.key,
    this.value,
    required this.updatedAt,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      id: json['id'] as String,
      key: json['key'] as String,
      value: json['value'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

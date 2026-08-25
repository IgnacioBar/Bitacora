class SharedCapturePoint {
  const SharedCapturePoint({
    required this.latitude,
    required this.longitude,
    required this.speciesName,
    required this.locationName,
    required this.caughtAt,
    this.weightKg,
    this.lengthCm,
    this.baitOrLure,
    this.technique,
    this.notes,
    this.photoPath,
    this.photoExtension,
  });

  final double latitude;
  final double longitude;
  final String speciesName;
  final String locationName;
  final DateTime caughtAt;
  final double? weightKg;
  final double? lengthCm;
  final String? baitOrLure;
  final String? technique;
  final String? notes;
  final String? photoPath;
  final String? photoExtension;

  Map<String, dynamic> toJson() => {
    'lat': latitude,
    'lng': longitude,
    'species': speciesName,
    'place': locationName,
    'caughtAt': caughtAt.toIso8601String(),
    'weightKg': weightKg,
    'lengthCm': lengthCm,
    'baitOrLure': baitOrLure,
    'technique': technique,
    'notes': notes,
    'photoPath': photoPath,
    'photoExtension': photoExtension,
  };

  factory SharedCapturePoint.fromJson(Map<String, dynamic> json) =>
      SharedCapturePoint(
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lng'] as num).toDouble(),
        speciesName: (json['species'] as String?)?.trim().isNotEmpty == true
            ? json['species'] as String
            : 'Captura',
        locationName: (json['place'] as String?)?.trim().isNotEmpty == true
            ? json['place'] as String
            : 'Lugar sin nombre',
        caughtAt:
            DateTime.tryParse(json['caughtAt'] as String? ?? '') ??
            DateTime.now(),
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        lengthCm: (json['lengthCm'] as num?)?.toDouble(),
        baitOrLure: json['baitOrLure'] as String?,
        technique: json['technique'] as String?,
        notes: json['notes'] as String?,
        photoPath: json['photoPath'] as String?,
        photoExtension: json['photoExtension'] as String?,
      );

  SharedCapturePoint copyWith({String? photoPath, String? photoExtension}) =>
      SharedCapturePoint(
        latitude: latitude,
        longitude: longitude,
        speciesName: speciesName,
        locationName: locationName,
        caughtAt: caughtAt,
        weightKg: weightKg,
        lengthCm: lengthCm,
        baitOrLure: baitOrLure,
        technique: technique,
        notes: notes,
        photoPath: photoPath ?? this.photoPath,
        photoExtension: photoExtension ?? this.photoExtension,
      );
}

class SharedCaptureMap {
  const SharedCaptureMap({
    required this.id,
    required this.ownerName,
    required this.colorValue,
    required this.importedAt,
    required this.points,
  });

  final String id;
  final String ownerName;
  final int colorValue;
  final DateTime importedAt;
  final List<SharedCapturePoint> points;

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerName': ownerName,
    'colorValue': colorValue,
    'importedAt': importedAt.toIso8601String(),
    'points': points.map((point) => point.toJson()).toList(),
  };

  factory SharedCaptureMap.fromJson(Map<String, dynamic> json) =>
      SharedCaptureMap(
        id: json['id'] as String,
        ownerName: json['ownerName'] as String,
        colorValue: json['colorValue'] as int,
        importedAt:
            DateTime.tryParse(json['importedAt'] as String? ?? '') ??
            DateTime.now(),
        points: (json['points'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(SharedCapturePoint.fromJson)
            .toList(),
      );
}

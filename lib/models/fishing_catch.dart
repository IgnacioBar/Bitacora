/// Registro inmutable de una captura. Las unidades son siempre kg y cm.
class FishingCatch {
  const FishingCatch({
    required this.id,
    required this.countryId,
    required this.waterTypeId,
    required this.speciesId,
    required this.caughtAt,
    required this.createdAt,
    this.photoPath,
    this.weightKg,
    this.lengthCm,
    this.latitude,
    this.longitude,
    this.locationName,
    this.baitOrLure,
    this.technique,
    this.notes,
  });

  final String id;
  final String countryId; // Por ahora: es
  final String waterTypeId; // freshwater | saltwater
  final String speciesId;
  final String? photoPath; // Ruta local; no guardar la imagen como BLOB.
  final double? weightKg;
  final double? lengthCm;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? baitOrLure;
  final String? technique;
  final DateTime caughtAt;
  final String? notes;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'country_id': countryId,
    'water_type_id': waterTypeId,
    'species_id': speciesId,
    'photo_path': photoPath,
    'weight_kg': weightKg,
    'length_cm': lengthCm,
    'latitude': latitude,
    'longitude': longitude,
    'location_name': locationName,
    'bait_or_lure': baitOrLure,
    'technique': technique,
    'caught_at': caughtAt.toUtc().toIso8601String(),
    'notes': notes,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  factory FishingCatch.fromMap(Map<String, Object?> map) => FishingCatch(
    id: map['id']! as String,
    countryId: map['country_id']! as String,
    waterTypeId: map['water_type_id']! as String,
    speciesId: map['species_id']! as String,
    photoPath: map['photo_path'] as String?,
    weightKg: (map['weight_kg'] as num?)?.toDouble(),
    lengthCm: (map['length_cm'] as num?)?.toDouble(),
    latitude: (map['latitude'] as num?)?.toDouble(),
    longitude: (map['longitude'] as num?)?.toDouble(),
    locationName: map['location_name'] as String?,
    baitOrLure: map['bait_or_lure'] as String?,
    technique: map['technique'] as String?,
    caughtAt: DateTime.parse(map['caught_at']! as String).toLocal(),
    notes: map['notes'] as String?,
    createdAt: DateTime.parse(map['created_at']! as String).toLocal(),
  );
}

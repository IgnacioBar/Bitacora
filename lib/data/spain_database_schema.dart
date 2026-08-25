/// Sentencias de creación para sqflite. Ejecutarlas en `onCreate`.
const spainDatabaseSchema = <String>[
  '''
  CREATE TABLE catches (
    id TEXT PRIMARY KEY,
    country_id TEXT NOT NULL DEFAULT 'es',
    water_type_id TEXT NOT NULL CHECK (water_type_id IN ('freshwater', 'saltwater')),
    species_id TEXT NOT NULL,
    photo_path TEXT,
    weight_kg REAL CHECK (weight_kg IS NULL OR weight_kg >= 0),
    length_cm REAL CHECK (length_cm IS NULL OR length_cm >= 0),
    latitude REAL CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    longitude REAL CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
    location_name TEXT,
    bait_or_lure TEXT,
    technique TEXT,
    caught_at TEXT NOT NULL,
    notes TEXT,
    created_at TEXT NOT NULL
  )
  ''',
  'CREATE INDEX IF NOT EXISTS idx_catches_date ON catches(caught_at DESC)',
  'CREATE INDEX IF NOT EXISTS idx_catches_species ON catches(species_id)',
  'CREATE INDEX IF NOT EXISTS idx_catches_water_type ON catches(water_type_id)',
  'CREATE INDEX IF NOT EXISTS idx_catches_location ON catches(latitude, longitude)',
];

class FishingSpecies {
  const FishingSpecies({
    required this.id,
    required this.commonName,
    required this.scientificName,
  });

  final String id;
  final String commonName;
  final String scientificName;
}

class WaterType {
  const WaterType({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.species,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final List<FishingSpecies> species;
}

const spainWaterTypes = <WaterType>[
  WaterType(
    id: 'freshwater',
    name: 'Agua dulce',
    description: 'Ríos, embalses y lagos',
    icon: '🏞️',
    species: [
      FishingSpecies(
        id: 'black_bass',
        commonName: 'Black Bass',
        scientificName: 'Micropterus salmoides',
      ),
      FishingSpecies(
        id: 'carp',
        commonName: 'Carpa',
        scientificName: 'Cyprinus carpio',
      ),
      FishingSpecies(
        id: 'pike',
        commonName: 'Lucio',
        scientificName: 'Esox lucius',
      ),
      FishingSpecies(
        id: 'brown_trout',
        commonName: 'Trucha común',
        scientificName: 'Salmo trutta',
      ),
      FishingSpecies(
        id: 'wels_catfish',
        commonName: 'Siluro',
        scientificName: 'Silurus glanis',
      ),
      FishingSpecies(
        id: 'barbel',
        commonName: 'Barbo',
        scientificName: 'Luciobarbus spp.',
      ),
    ],
  ),
  WaterType(
    id: 'saltwater',
    name: 'Agua salada',
    description: 'Costa, playa, puerto y mar abierto',
    icon: '🌊',
    species: [
      FishingSpecies(
        id: 'european_seabass',
        commonName: 'Lubina',
        scientificName: 'Dicentrarchus labrax',
      ),
      FishingSpecies(
        id: 'gilthead_bream',
        commonName: 'Dorada',
        scientificName: 'Sparus aurata',
      ),
      FishingSpecies(
        id: 'white_seabream',
        commonName: 'Sargo',
        scientificName: 'Diplodus sargus',
      ),
      FishingSpecies(
        id: 'atlantic_bluefin_tuna',
        commonName: 'Atún rojo',
        scientificName: 'Thunnus thynnus',
      ),
      FishingSpecies(
        id: 'common_dentex',
        commonName: 'Dentón',
        scientificName: 'Dentex dentex',
      ),
      FishingSpecies(
        id: 'cuttlefish_squid',
        commonName: 'Sepia / Calamar',
        scientificName: 'Sepia officinalis / Loligo vulgaris',
      ),
    ],
  ),
];

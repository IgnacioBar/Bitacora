# Módulo de datos: España

La aplicación parte de un catálogo local, `assets/data/spain_catalog.json`, y una tabla local de capturas. Esta separación permite añadir países después sin mezclar especies de referencia con los registros del usuario.

## Entidades

| Entidad | Finalidad | Identificador |
| --- | --- | --- |
| País | Contexto geográfico de la pesca | `es` |
| Tipo de agua | Agrupa el catálogo | `freshwater`, `saltwater` |
| Especie | Opción seleccionada en el diario | por ejemplo, `black_bass` |
| Captura | Registro creado por el pescador | UUID generado en el dispositivo |

## SQLite

La tabla `catches` está definida en `lib/data/spain_database_schema.dart`. Las fechas se guardan en ISO-8601 UTC para evitar ambigüedades; se convierten a la zona local al mostrarlas. La foto se conserva en el almacenamiento de la aplicación y la base de datos guarda sólo `photo_path`.

## Flujo de navegación previsto

`España` → `Agua dulce / Agua salada` → `Especie` → `Nueva captura`.

El registro de captura guarda los identificadores de país, tipo de agua y especie: por ello seguirá siendo consistente aunque el catálogo se amplíe más adelante.

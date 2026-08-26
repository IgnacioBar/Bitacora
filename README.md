# Bitácora

Diario de pesca digital para Android creado con Flutter.

## Qué permite hacer

- Registrar capturas de pesca en España.
- Guardar foto, peso, longitud, fecha, hora, cebo, técnica, notas y ubicación GPS.
- Ver biblioteca de capturas con filtros.
- Abrir cada captura en detalle.
- Ver foto y mapa en pantalla completa.
- Ver todas las capturas en un mapa.
- Compartir ubicaciones mediante código BIDI/código copiable.
- Importar ubicaciones de otras personas en el mapa con color propio.
- Hacer copia de seguridad y restaurarla.

## Privacidad

Bitácora guarda los datos en el dispositivo. Al compartir ubicaciones solo se envían puntos del mapa: coordenadas, especie, lugar y fecha.

## Estado actual

Versión actual: 1.1.0.

Esta versión está pensada para uso personal en Android.

## Desarrollo

Proyecto Flutter.

Comandos útiles:

```bash
flutter analyze
flutter test
flutter build apk --release --split-per-abi
```

## Control de versiones

El desarrollo se mantiene en la rama `develop`.

Las versiones publicadas se etiquetan con formato `vX.Y.Z`:

- `v1.0.1`: correcciones y mantenimiento.
- `v1.1.0`: mejoras o funciones nuevas.
- `v2.0.0`: cambios grandes de estructura, diseño o funcionamiento.

Antes de publicar una versión se revisa `docs/RELEASE_PROCESS.md`.

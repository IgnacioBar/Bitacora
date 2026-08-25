# Proceso de release de Bitácora

Este documento sirve para mantener controladas las versiones de Bitácora y evitar confusiones entre desarrollo, pruebas y publicaciones.

## Regla de nombres

Bitácora usa versionado semántico:

- `vX.Y.Z` para tags de GitHub.
- `X.Y.Z+N` en `pubspec.yaml`, donde `N` es el número interno de compilación Android.

Ejemplos:

- `v1.0.1`: corrección o mantenimiento.
- `v1.1.0`: mejora o función nueva.
- `v2.0.0`: cambio grande de diseño, datos o arquitectura.

## Ramas

- `develop`: trabajo diario, pruebas y nuevas versiones.
- `main`: versiones publicadas o listas para publicar.

## Antes de crear una release

1. Decidir el número de versión y comunicarlo.
2. Actualizar `pubspec.yaml`.
3. Actualizar `_appVersionLabel` en `lib/main.dart`.
4. Actualizar `README.md`.
5. Añadir cambios en `docs/VERSION_HISTORY.md`.
6. Ejecutar comprobaciones:
   - `flutter analyze`
   - `flutter test`
   - `flutter build apk --debug`
7. Guardar APK y ZIP del código en:
   - `C:\Users\ignac\Desktop\Bitácora\vX.Y.Z`
8. Crear commit.
9. Subir `develop`.
10. Crear o mover el tag `vX.Y.Z`.
11. Publicar la release en GitHub.

## Nota sobre la APK release

La APK release firmada queda pendiente hasta resolver el bloqueo local de certificados SSL/Gradle. Mientras tanto, para uso personal se puede instalar la APK debug generada localmente.

## Compatibilidad

Aunque la app se llama Bitácora, algunos nombres internos siguen usando `pescatronik`, como el paquete Android y la base de datos. No deben cambiarse sin migración previa, porque podrían romper instalaciones existentes o hacer que Android trate la app como una app distinta.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'data/backup_repository.dart';
import 'data/android_gallery_picker.dart';
import 'data/catch_repository.dart';
import 'data/photo_storage.dart';
import 'data/shared_map_repository.dart';
import 'data/spain_catalog.dart';
import 'models/fishing_catch.dart';
import 'models/shared_capture_map.dart';

const _paper = Color(0xFFF7F1E3);
const _paperCard = Color(0xFFFFFBF0);
const _ink = Color(0xFF22302C);
const _mutedInk = Color(0xFF65736C);
const _accentBrown = Color(0xFF8A6F3D);
const _buttonBeige = Color(0xFFD8C08A);
const _lineBrown = Color(0xFFD8C7A3);
const _stampPaper = Color(0xFFEAD6A7);
const _mapInk = Color(0xFF6D5A31);
const _pagePadding = EdgeInsets.fromLTRB(38, 20, 20, 20);
const _pagePaddingLarge = EdgeInsets.fromLTRB(38, 24, 24, 24);
const _notebookFont = 'casual';
const _appVersionLabel = '1.3.0';

const _versionHistory = [
  _VersionNote(
    version: '1.3.0',
    title: 'Control de versiones',
    details: [
      'Nueva pantalla de historial de versiones dentro de Acerca de.',
      'Mejoras de comprobación para mantener fechas y textos en español.',
    ],
  ),
  _VersionNote(
    version: '1.2.0',
    title: 'Pulido de idioma y arranque',
    details: [
      'Fechas, meses y calendarios localizados para España.',
      'Arranque inicial más ligero al cargar datos y recursos en segundo plano.',
    ],
  ),
  _VersionNote(
    version: '1.1.0',
    title: 'Visualización de fotos',
    details: [
      'Mejorada la vista de fotos de capturas en pantalla completa.',
      'Demo y datos de presentación preparados para enseñar la app.',
    ],
  ),
  _VersionNote(
    version: '1.0.0',
    title: 'Primera versión estable',
    details: [
      'Diario de capturas, biblioteca, mapas, filtros y copia de seguridad.',
      'Portada estilo diario de pesca e interfaz visual tipo cuaderno.',
    ],
  ),
];

const _speciesIconAssets = {
  'black_bass': 'assets/images/species/black_bass.png',
  'carp': 'assets/images/species/carp.png',
  'pike': 'assets/images/species/pike.png',
  'brown_trout': 'assets/images/species/brown_trout.png',
  'wels_catfish': 'assets/images/species/wels_catfish.png',
  'barbel': 'assets/images/species/barbel.png',
  'european_seabass': 'assets/images/species/european_seabass.png',
  'gilthead_bream': 'assets/images/species/gilthead_bream.png',
  'white_seabream': 'assets/images/species/white_seabream.png',
  'atlantic_bluefin_tuna': 'assets/images/species/atlantic_bluefin_tuna.png',
  'common_dentex': 'assets/images/species/common_dentex.png',
  'cuttlefish_squid': 'assets/images/species/cuttlefish_squid.png',
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: _paper,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const BitacoraApp());
}

class BitacoraApp extends StatelessWidget {
  const BitacoraApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Bitácora',
    debugShowCheckedModeBanner: false,
    locale: const Locale('es', 'ES'),
    supportedLocales: const [Locale('es', 'ES')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _accentBrown,
        surface: _paper,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: _paper,
      fontFamily: _notebookFont,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _NotebookPageTransitionsBuilder(),
          TargetPlatform.iOS: _NotebookPageTransitionsBuilder(),
          TargetPlatform.windows: _NotebookPageTransitionsBuilder(),
        },
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: _notebookFont,
          color: _ink,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: TextStyle(
          fontFamily: _notebookFont,
          color: _ink,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          fontFamily: _notebookFont,
          color: _ink,
          fontSize: 34,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        headlineSmall: TextStyle(
          fontFamily: _notebookFont,
          color: _ink,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        titleLarge: TextStyle(
          fontFamily: _notebookFont,
          color: _ink,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          fontFamily: _notebookFont,
          color: _ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          fontFamily: _notebookFont,
          color: _ink,
          fontSize: 18,
          height: 1.2,
        ),
        bodyMedium: TextStyle(
          fontFamily: _notebookFont,
          color: _ink,
          fontSize: 16,
          height: 1.2,
        ),
        bodySmall: TextStyle(
          fontFamily: _notebookFont,
          color: _mutedInk,
          fontSize: 14,
        ),
        labelLarge: TextStyle(
          fontFamily: _notebookFont,
          color: _ink,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _paper,
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _notebookFont,
          color: _ink,
          fontSize: 26,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: _paperCard,
        elevation: 1.5,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shadowColor: _lineBrown.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _lineBrown),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: _accentBrown,
        textColor: _ink,
        titleTextStyle: TextStyle(
          fontFamily: _notebookFont,
          color: _ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: _notebookFont,
          color: _mutedInk,
          fontSize: 15,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _buttonBeige,
          foregroundColor: _ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _accentBrown),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: _paperCard,
        labelStyle: TextStyle(color: _mutedInk),
        floatingLabelStyle: TextStyle(color: _accentBrown),
        prefixIconColor: _accentBrown,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _lineBrown),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _lineBrown),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _accentBrown, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(color: _lineBrown),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _ink,
        contentTextStyle: const TextStyle(color: _paperCard),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    home: const AppBootstrap(),
  );
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late Future<void> _startup;

  @override
  void initState() {
    super.initState();
    _startup = _prepareApp();
  }

  Future<void> _prepareApp() async {
    unawaited(CatchRepository.instance.warmUp());
    unawaited(_warmUpAssets());
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  Future<void> _warmUpAssets() async {
    final assets = [
      'assets/images/bitacora_icon_transparent.png',
      ..._speciesIconAssets.values,
    ];
    for (final asset in assets) {
      await rootBundle.load(asset);
    }
  }

  void _retry() {
    setState(() => _startup = _prepareApp());
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _startup,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(
          body: _PaperSheet(
            child: _NotebookLoadingView(
              message: 'Preparando tu diario de pesca...',
              large: true,
            ),
          ),
        );
      }
      if (snapshot.hasError) {
        return Scaffold(
          body: _PaperSheet(
            child: _NotebookErrorView(
              title: 'No se pudo abrir Bitácora',
              message: 'Ha fallado la preparación inicial de la app.',
              onRetry: _retry,
            ),
          ),
        );
      }
      return const DiaryCoverScreen();
    },
  );
}

class _PaperSheet extends StatelessWidget {
  const _PaperSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(child: CustomPaint(painter: _PaperPainter())),
      Positioned.fill(child: child),
    ],
  );
}

class _NotebookPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NotebookPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.035, 0.015),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
          child: child,
        ),
      ),
    );
  }
}

class _AnimatedEntry extends StatefulWidget {
  const _AnimatedEntry({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSlide(
    offset: _visible ? Offset.zero : const Offset(0, 0.045),
    duration: const Duration(milliseconds: 420),
    curve: Curves.easeOutCubic,
    child: AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

class _NotebookLoadingView extends StatelessWidget {
  const _NotebookLoadingView({required this.message, this.large = false});

  final String message;
  final bool large;

  @override
  Widget build(BuildContext context) => Center(
    child: Card(
      margin: const EdgeInsets.fromLTRB(38, 24, 24, 24),
      child: Padding(
        padding: EdgeInsets.all(large ? 28 : 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/bitacora_icon_transparent.png',
              width: large ? 84 : 58,
              height: large ? 84 : 58,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.menu_book_outlined,
                size: large ? 64 : 42,
                color: _accentBrown,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: large ? 42 : 30,
              height: large ? 42 : 30,
              child: const CircularProgressIndicator(
                strokeWidth: 2.4,
                color: _accentBrown,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    ),
  );
}

class _NotebookErrorView extends StatelessWidget {
  const _NotebookErrorView({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Card(
      margin: const EdgeInsets.fromLTRB(38, 24, 24, 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 54, color: _accentBrown),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _NotebookEmptyView extends StatelessWidget {
  const _NotebookEmptyView({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Card(
      margin: const EdgeInsets.fromLTRB(38, 24, 24, 24),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 62, color: _accentBrown),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    ),
  );
}

class _SpeciesIconAvatar extends StatelessWidget {
  const _SpeciesIconAvatar({required this.speciesId, this.radius = 22});

  final String? speciesId;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final assetPath = speciesId == null ? null : _speciesIconAssets[speciesId];
    final iconSize = radius * 1.75;

    return CircleAvatar(
      radius: radius,
      backgroundColor: _stampPaper,
      child: assetPath == null
          ? Icon(
              Icons.set_meal_outlined,
              color: _accentBrown,
              size: iconSize * 0.62,
            )
          : Padding(
              padding: EdgeInsets.all(radius * 0.1),
              child: Image.asset(
                assetPath,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                semanticLabel: 'Icono de pez',
                errorBuilder: (_, _, _) => Icon(
                  Icons.set_meal_outlined,
                  color: _accentBrown,
                  size: iconSize * 0.62,
                ),
              ),
            ),
    );
  }
}

class _PaperPainter extends CustomPainter {
  const _PaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(_paper, BlendMode.src);

    final linePaint = Paint()
      ..color = _lineBrown.withValues(alpha: 0.22)
      ..strokeWidth = 1;
    for (double y = 170; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final marginPaint = Paint()
      ..color = _accentBrown.withValues(alpha: 0.16)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(34, 0), Offset(34, size.height), marginPaint);

    final speckPaint = Paint()
      ..color = _lineBrown.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (double y = 28; y < size.height; y += 96) {
      for (double x = 18; x < size.width; x += 118) {
        canvas.drawCircle(Offset(x, y), 0.8, speckPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DiaryCoverScreen extends StatelessWidget {
  const DiaryCoverScreen({super.key});

  void _openDiary(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const CountryScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Semantics(
      button: true,
      label: 'Portada de Bitácora',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openDiary(context),
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _CoverPainter())),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth * 0.78;
                  return Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: cardWidth.clamp(280.0, 430.0),
                          child: const _CoverTitleCard(),
                        ),
                      ),
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 34,
                        child: Text(
                          'Toca la pantalla para abrir el diario',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _stampPaper,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CoverTitleCard extends StatelessWidget {
  const _CoverTitleCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
    decoration: BoxDecoration(
      color: _paperCard.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _lineBrown.withValues(alpha: 0.9), width: 1.4),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/bitacora_icon_transparent.png',
          width: 108,
          height: 108,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            Icons.menu_book_outlined,
            size: 84,
            color: _accentBrown,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Bitácora',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 44,
            height: 0.95,
            color: _ink,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            shadows: [
              Shadow(
                color: Color(0x33906D3A),
                blurRadius: 1.5,
                offset: Offset(0.8, 1.1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Diario de pesca',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 22,
            color: _mapInk,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        const _CoverDivider(),
        const SizedBox(height: 12),
        Text(
          'Capturas · Señuelos · Mapas · Recuerdos',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: _mutedInk, fontSize: 15, letterSpacing: 0.5),
        ),
      ],
    ),
  );
}

class _CoverDivider extends StatelessWidget {
  const _CoverDivider();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(color: _lineBrown)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Icon(Icons.phishing_outlined, color: _accentBrown, size: 22),
      ),
      const Expanded(child: Divider(color: _lineBrown)),
    ],
  );
}

class _CoverPainter extends CustomPainter {
  const _CoverPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cover = Paint()..color = const Color(0xFF4A321F);
    canvas.drawRect(Offset.zero & size, cover);

    final vignette = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.18, -0.16),
        radius: 1.08,
        colors: [
          const Color(0xFF9A7846).withValues(alpha: 0.42),
          const Color(0xFF3B281A),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);

    final subtleFold = Paint()
      ..color = const Color(0xFFEAD6A7).withValues(alpha: 0.12)
      ..strokeWidth = 0.9;
    canvas.drawLine(const Offset(14, 0), Offset(14, size.height), subtleFold);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFD8C08A).withValues(alpha: 0.52);
    final coverRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(0, 0, size.width, size.height),
      Radius.zero,
    );
    canvas.drawRRect(coverRect, border);

    final innerBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFEAD6A7).withValues(alpha: 0.26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(32, 56, size.width - 32, size.height - 64),
        const Radius.circular(22),
      ),
      innerBorder,
    );

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..color = const Color(0xFFEAD6A7).withValues(alpha: 0.34);
    for (double y = size.height * 0.18; y < size.height * 0.86; y += 92) {
      final path = ui.Path()..moveTo(44, y);
      for (double x = 44; x < size.width - 44; x += 54) {
        path.quadraticBezierTo(x + 18, y + 13, x + 36, y);
        path.quadraticBezierTo(x + 48, y - 8, x + 54, y);
      }
      canvas.drawPath(path, wavePaint);
    }

    final fishPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFEAD6A7).withValues(alpha: 0.5);
    final fishCenter = Offset(size.width * 0.68, size.height * 0.17);
    final fishPath = ui.Path()
      ..moveTo(fishCenter.dx - 52, fishCenter.dy)
      ..quadraticBezierTo(
        fishCenter.dx,
        fishCenter.dy - 34,
        fishCenter.dx + 58,
        fishCenter.dy,
      )
      ..quadraticBezierTo(
        fishCenter.dx,
        fishCenter.dy + 34,
        fishCenter.dx - 52,
        fishCenter.dy,
      )
      ..moveTo(fishCenter.dx - 52, fishCenter.dy)
      ..lineTo(fishCenter.dx - 88, fishCenter.dy - 28)
      ..moveTo(fishCenter.dx - 52, fishCenter.dy)
      ..lineTo(fishCenter.dx - 88, fishCenter.dy + 28);
    canvas.drawPath(fishPath, fishPaint);
    canvas.drawCircle(
      Offset(fishCenter.dx + 34, fishCenter.dy - 6),
      2.8,
      Paint()..color = const Color(0xFFEAD6A7).withValues(alpha: 0.62),
    );

    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFFEAD6A7).withValues(alpha: 0.48);
    const corner = 58.0;
    canvas.drawArc(
      Rect.fromLTWH(42, 70, corner, corner),
      math.pi,
      math.pi / 2,
      false,
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width - 100, 70, corner, corner),
      math.pi * 1.5,
      math.pi / 2,
      false,
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(42, size.height - 122, corner, corner),
      math.pi / 2,
      math.pi / 2,
      false,
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(size.width - 100, size.height - 122, corner, corner),
      0,
      math.pi / 2,
      false,
      cornerPaint,
    );

    final speckPaint = Paint()
      ..color = const Color(0xFFEAD6A7).withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (double y = 34; y < size.height; y += 83) {
      for (double x = 42; x < size.width; x += 111) {
        canvas.drawCircle(Offset(x, y), 1.1, speckPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CountryScreen extends StatelessWidget {
  const CountryScreen({super.key});

  void _openMenu(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const HomeMenuScreen()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          Image.asset('assets/images/bitacora_icon.png', width: 36, height: 36),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Bitácora',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Menú',
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => _openMenu(context),
        ),
      ],
    ),
    body: _PaperSheet(
      child: Padding(
        padding: _pagePaddingLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu diario de pesca',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text('Elige el país donde has pescado.'),
            const SizedBox(height: 28),
            _AnimatedEntry(
              delay: const Duration(milliseconds: 90),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  leading: const Text('🇪🇸', style: TextStyle(fontSize: 36)),
                  title: const Text('España'),
                  subtitle: const Text('Catálogo inicial disponible'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WaterTypeScreen()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class HomeMenuScreen extends StatelessWidget {
  const HomeMenuScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Menú del diario')),
    body: _PaperSheet(
      child: ListView(
        padding: _pagePadding,
        children: [
          _AnimatedEntry(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const _MenuAppIcon(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bitácora',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tu diario de pesca organizado por secciones.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _HomeMenuItem(
            icon: Icons.book_outlined,
            title: 'Mis capturas',
            subtitle: 'Biblioteca completa',
            onTap: () => _open(context, const CatchListScreen()),
          ),
          _HomeMenuItem(
            icon: Icons.calendar_month_outlined,
            title: 'Calendario',
            subtitle: 'Capturas por día',
            onTap: () => _open(context, const CatchCalendarScreen()),
          ),
          _HomeMenuItem(
            icon: Icons.insights_outlined,
            title: 'Estadísticas',
            subtitle: 'Resumen de tu diario',
            onTap: () => _open(context, const CatchStatsScreen()),
          ),
          _HomeMenuItem(
            icon: Icons.map_outlined,
            title: 'Mapa de capturas',
            subtitle: 'Puntos GPS guardados',
            onTap: () => _open(context, const AllCapturesMapScreen()),
          ),
          _HomeMenuItem(
            icon: Icons.ios_share_outlined,
            title: 'Compartir ubicaciones',
            subtitle: 'Enviar, recibir y gestionar puntos',
            onTap: () => _open(context, const SharingHubScreen()),
          ),
          _HomeMenuItem(
            icon: Icons.save_alt_outlined,
            title: 'Copia de seguridad',
            subtitle: 'Exportar y restaurar datos',
            onTap: () => _open(context, const BackupScreen()),
          ),
          _HomeMenuItem(
            icon: Icons.info_outline,
            title: 'Acerca de Bitácora',
            subtitle: 'Versión, privacidad y estado',
            onTap: () => _open(context, const AboutBitacoraScreen()),
          ),
        ],
      ),
    ),
  );
}

class _MenuAppIcon extends StatelessWidget {
  const _MenuAppIcon();

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/bitacora_icon_transparent.png',
    width: 58,
    height: 58,
    fit: BoxFit.contain,
  );
}

class _HomeMenuItem extends StatelessWidget {
  const _HomeMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: _stampPaper,
        foregroundColor: _accentBrown,
        child: Icon(icon),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class AboutBitacoraScreen extends StatefulWidget {
  const AboutBitacoraScreen({super.key});

  @override
  State<AboutBitacoraScreen> createState() => _AboutBitacoraScreenState();
}

class _AboutBitacoraScreenState extends State<AboutBitacoraScreen> {
  late Future<_AppDiarySummary> _summary;

  @override
  void initState() {
    super.initState();
    _summary = _loadSummary();
  }

  Future<_AppDiarySummary> _loadSummary() async {
    final catches = await CatchRepository.instance.getAll();
    final sharedMaps = await SharedMapRepository.instance.getAll();
    return _AppDiarySummary(
      captures: catches.length,
      locatedCaptures: catches
          .where((entry) => entry.latitude != null && entry.longitude != null)
          .length,
      sharedPeople: sharedMaps
          .map((map) => map.ownerName.trim().toLowerCase())
          .where((name) => name.isNotEmpty)
          .toSet()
          .length,
      sharedPoints: sharedMaps.fold<int>(
        0,
        (total, map) => total + map.points.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Acerca de')),
    body: _PaperSheet(
      child: FutureBuilder<_AppDiarySummary>(
        future: _summary,
        builder: (context, snapshot) {
          final summary = snapshot.data;
          return ListView(
            padding: _pagePaddingLarge,
            children: [
              _AnimatedEntry(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/bitacora_icon_transparent.png',
                          width: 96,
                          height: 96,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Bitácora',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        const Text('Diario de pesca personal'),
                        const SizedBox(height: 8),
                        const _NotebookTag(label: 'Versión $_appVersionLabel'),
                      ],
                    ),
                  ),
                ),
              ),
              _AnimatedEntry(
                delay: const Duration(milliseconds: 70),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Estado del diario',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        if (snapshot.connectionState != ConnectionState.done)
                          const LinearProgressIndicator(color: _accentBrown)
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _NotebookTag(
                                label: '${summary?.captures ?? 0} capturas',
                              ),
                              _NotebookTag(
                                label:
                                    '${summary?.locatedCaptures ?? 0} con GPS',
                              ),
                              _NotebookTag(
                                label: '${summary?.sharedPeople ?? 0} personas',
                              ),
                              _NotebookTag(
                                label:
                                    '${summary?.sharedPoints ?? 0} puntos compartidos',
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const _AnimatedEntry(
                delay: Duration(milliseconds: 140),
                child: _PrivacyNoteCard(),
              ),
              _AnimatedEntry(
                delay: const Duration(milliseconds: 210),
                child: Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: _stampPaper,
                      foregroundColor: _accentBrown,
                      child: Icon(Icons.history_edu_outlined),
                    ),
                    title: const Text('Historial de versiones'),
                    subtitle: const Text('Qué ha cambiado en cada entrega'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const VersionHistoryScreen(),
                      ),
                    ),
                  ),
                ),
              ),
              _AnimatedEntry(
                delay: const Duration(milliseconds: 280),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consejo de uso',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Haz una copia de seguridad de vez en cuando si empiezas a usar la app como diario principal. Así tus capturas quedan a salvo si cambias de móvil.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class VersionHistoryScreen extends StatelessWidget {
  const VersionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Historial')),
    body: _PaperSheet(
      child: ListView.separated(
        padding: _pagePaddingLarge,
        itemCount: _versionHistory.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final note = _versionHistory[index];
          return _AnimatedEntry(
            delay: Duration(milliseconds: 70 * index),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _NotebookTag(label: 'v${note.version}'),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            note.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...note.details.map(
                      (detail) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Icon(
                                Icons.check_circle_outline,
                                size: 18,
                                color: _accentBrown,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(detail)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _VersionNote {
  const _VersionNote({
    required this.version,
    required this.title,
    required this.details,
  });

  final String version;
  final String title;
  final List<String> details;
}

class _AppDiarySummary {
  const _AppDiarySummary({
    required this.captures,
    required this.locatedCaptures,
    required this.sharedPeople,
    required this.sharedPoints,
  });

  final int captures;
  final int locatedCaptures;
  final int sharedPeople;
  final int sharedPoints;
}

class _NotebookTag extends StatelessWidget {
  const _NotebookTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: _stampPaper.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: _lineBrown),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    ),
  );
}

class _PrivacyNoteCard extends StatelessWidget {
  const _PrivacyNoteCard();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: _stampPaper,
            foregroundColor: _accentBrown,
            child: Icon(Icons.privacy_tip_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacidad',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tus capturas se guardan en este dispositivo. Al compartir ubicaciones solo se envían puntos del mapa mediante el código que tú generas.',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class WaterTypeScreen extends StatelessWidget {
  const WaterTypeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('España')),
    body: _PaperSheet(
      child: ListView(
        padding: _pagePadding,
        children: [
          Text(
            '¿Dónde pescaste?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          for (final (index, waterType) in spainWaterTypes.indexed)
            _AnimatedEntry(
              delay: Duration(milliseconds: 70 * index),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  leading: Text(
                    waterType.icon,
                    style: const TextStyle(fontSize: 34),
                  ),
                  title: Text(waterType.name),
                  subtitle: Text(waterType.description),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SpeciesScreen(waterType: waterType),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class SpeciesScreen extends StatelessWidget {
  const SpeciesScreen({super.key, required this.waterType});
  final WaterType waterType;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(waterType.name)),
    body: _PaperSheet(
      child: ListView.separated(
        padding: _pagePadding,
        itemCount: waterType.species.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final species = waterType.species[index];
          return _AnimatedEntry(
            delay: Duration(milliseconds: 45 * index),
            child: Card(
              child: ListTile(
                leading: _SpeciesIconAvatar(speciesId: species.id),
                title: Text(species.commonName),
                subtitle: Text(species.scientificName),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        CatchFormScreen(waterType: waterType, species: species),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class CatchFormScreen extends StatefulWidget {
  const CatchFormScreen({
    super.key,
    required this.waterType,
    required this.species,
    this.existingCatch,
  });
  final WaterType waterType;
  final FishingSpecies species;
  final FishingCatch? existingCatch;

  @override
  State<CatchFormScreen> createState() => _CatchFormScreenState();
}

class _CatchFormScreenState extends State<CatchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weight = TextEditingController();
  final _length = TextEditingController();
  final _place = TextEditingController();
  final _bait = TextEditingController();
  final _technique = TextEditingController();
  final _notes = TextEditingController();
  final _imagePicker = ImagePicker();
  late DateTime _caughtAt;
  String? _photoPath;
  String? _originalPhotoPath;
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;
  bool _isSaving = false;
  bool _isPickingPhoto = false;
  bool _photoChanged = false;

  bool get _isEditing => widget.existingCatch != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingCatch;
    if (existing == null) {
      _caughtAt = DateTime.now();
      return;
    }
    _weight.text = existing.weightKg?.toString() ?? '';
    _length.text = existing.lengthCm?.toString() ?? '';
    _place.text = existing.locationName ?? '';
    _bait.text = existing.baitOrLure ?? '';
    _technique.text = existing.technique ?? '';
    _notes.text = existing.notes ?? '';
    _caughtAt = existing.caughtAt;
    _photoPath = existing.photoPath;
    _originalPhotoPath = existing.photoPath;
    _latitude = existing.latitude;
    _longitude = existing.longitude;
  }

  @override
  void dispose() {
    for (final controller in [
      _weight,
      _length,
      _place,
      _bait,
      _technique,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _caughtAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_caughtAt),
    );
    if (time == null) return;
    setState(
      () => _caughtAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  void _setSelectedPhoto(String path) {
    setState(() {
      _photoPath = path;
      _photoChanged = true;
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_isPickingPhoto) return;
    setState(() => _isPickingPhoto = true);
    try {
      final photo = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (photo == null || !mounted) return;
      _setSelectedPhoto(photo.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la cámara o la galería.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  Future<void> _pickPhotoFromMiuiGallery() async {
    if (_isPickingPhoto) return;
    setState(() => _isPickingPhoto = true);
    try {
      final photoPath = await AndroidGalleryPicker.pickImageFromMiuiGallery();
      if (photoPath == null || !mounted) return;
      _setSelectedPhoto(photoPath);
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta opción solo está disponible en Android.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo abrir la Galería Xiaomi/POCO. Usa el selector Android.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  Future<void> _pickPhotoFromAndroidSelector() async {
    if (_isPickingPhoto) return;
    setState(() => _isPickingPhoto = true);
    try {
      final photoPath =
          await AndroidGalleryPicker.pickImageFromAndroidSelector();
      if (photoPath == null || !mounted) return;
      _setSelectedPhoto(photoPath);
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta opción solo está disponible en Android.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el selector Android de fotos.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar una foto'),
              subtitle: const Text('Usa la cámara del móvil'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galería Xiaomi/POCO'),
              subtitle: const Text('Abre la app Galería del Poco X6'),
              onTap: () {
                Navigator.pop(context);
                _pickPhotoFromMiuiGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.collections_outlined),
              title: const Text('Selector Android / Google Fotos'),
              subtitle: const Text('Respaldo compatible con otros móviles'),
              onTap: () {
                Navigator.pop(context);
                _pickPhotoFromAndroidSelector();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activa la ubicación del emulador o del móvil.'),
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado.')),
        );
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activa el permiso de ubicación en Ajustes.'),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ubicación GPS guardada.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la ubicación GPS.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _pickLocationOnMap() async {
    final selectedPoint = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );
    if (selectedPoint == null || !mounted) return;
    setState(() {
      _latitude = selectedPoint.latitude;
      _longitude = selectedPoint.longitude;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ubicación elegida en el mapa.')),
    );
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final existing = widget.existingCatch;
      final entryId =
          existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
      final savedPhotoPath = await _photoPathForSave(entryId);
      final entry = FishingCatch(
        id: entryId,
        countryId: 'es',
        waterTypeId: widget.waterType.id,
        speciesId: widget.species.id,
        photoPath: savedPhotoPath,
        weightKg: double.tryParse(_weight.text.replaceAll(',', '.')),
        lengthCm: double.tryParse(_length.text.replaceAll(',', '.')),
        latitude: _latitude,
        longitude: _longitude,
        locationName: _place.text.trim().isEmpty ? null : _place.text.trim(),
        baitOrLure: _bait.text.trim().isEmpty ? null : _bait.text.trim(),
        technique: _technique.text.trim().isEmpty
            ? null
            : _technique.text.trim(),
        caughtAt: _caughtAt,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        createdAt: existing?.createdAt ?? DateTime.now(),
      );
      await CatchRepository.instance.save(entry);
      if (_photoChanged && _originalPhotoPath != savedPhotoPath) {
        await PhotoStorage.deleteIfExists(_originalPhotoPath);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Captura actualizada en tu diario.'
                : 'Captura guardada en tu diario.',
          ),
        ),
      );
      Navigator.of(context).pop(entry);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo guardar. Revisa la foto o inténtalo de nuevo.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String?> _photoPathForSave(String entryId) async {
    if (_photoPath == null) return null;
    if (!_photoChanged && _photoPath == _originalPhotoPath) return _photoPath;
    return PhotoStorage.save(_photoPath!, entryId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        _isEditing
            ? 'Editar captura · ${widget.species.commonName}'
            : 'Nueva captura · ${widget.species.commonName}',
      ),
    ),
    body: _PaperSheet(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: _pagePadding,
          children: [
            if (_photoPath == null)
              OutlinedButton.icon(
                onPressed: _isPickingPhoto ? null : _showPhotoOptions,
                icon: _isPickingPhoto
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_a_photo_outlined),
                label: Text(
                  _isPickingPhoto
                      ? 'Abriendo fotos...'
                      : 'Añadir foto de la captura',
                ),
              )
            else
              _CapturePhoto(
                path: _photoPath!,
                onRemove: () => setState(() {
                  _photoPath = null;
                  _photoChanged = true;
                }),
                onChange: _isPickingPhoto ? null : _showPhotoOptions,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _numberField(_weight, 'Peso (kg)')),
                const SizedBox(width: 12),
                Expanded(child: _numberField(_length, 'Longitud (cm)')),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _place,
              decoration: const InputDecoration(labelText: 'Lugar exacto'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _isGettingLocation ? null : _useCurrentLocation,
              icon: _isGettingLocation
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                _isGettingLocation
                    ? 'Obteniendo ubicación...'
                    : 'Usar mi ubicación GPS',
              ),
            ),
            TextButton.icon(
              onPressed: _pickLocationOnMap,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(
                _latitude == null || _longitude == null
                    ? 'Elegir lugar en el mapa'
                    : 'Editar lugar en el mapa',
              ),
            ),
            if (_latitude != null && _longitude != null) ...[
              const SizedBox(height: 4),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Ubicación GPS'),
                subtitle: Text(
                  '${_formatCoordinate(_latitude!)}, '
                  '${_formatCoordinate(_longitude!)}',
                ),
                trailing: IconButton(
                  tooltip: 'Quitar GPS',
                  onPressed: () => setState(() {
                    _latitude = null;
                    _longitude = null;
                  }),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextFormField(
              controller: _bait,
              decoration: const InputDecoration(labelText: 'Cebo o señuelo'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _technique,
              decoration: const InputDecoration(labelText: 'Técnica de pesca'),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha y hora'),
              subtitle: Text(
                '${MaterialLocalizations.of(context).formatFullDate(_caughtAt)} · ${TimeOfDay.fromDateTime(_caughtAt).format(context)}',
              ),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notas adicionales'),
              minLines: 3,
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _isSaving
                    ? 'Guardando...'
                    : _isEditing
                    ? 'Guardar cambios'
                    : 'Guardar captura',
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _numberField(TextEditingController controller, String label) =>
      TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) return null;
          return double.tryParse(value.replaceAll(',', '.')) == null
              ? 'Introduce un número válido'
              : null;
        },
      );
}

class CatchListScreen extends StatefulWidget {
  const CatchListScreen({super.key});

  @override
  State<CatchListScreen> createState() => _CatchListScreenState();
}

class _CatchListScreenState extends State<CatchListScreen> {
  late Future<List<FishingCatch>> _catches;
  final _search = TextEditingController();
  String _waterTypeFilter = 'all';
  String _speciesFilter = 'all';
  String _sortMode = 'date_desc';
  bool _filtersExpanded = false;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _catches = CatchRepository.instance.getAll();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _catches = CatchRepository.instance.getAll();
    });
  }

  Future<void> _openDetail(FishingCatch entry) async {
    final deletedId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => CatchDetailScreen(entry: entry)),
    );
    if (!mounted) return;
    if (deletedId != null) {
      setState(() {
        _catches = CatchRepository.instance.getAll().then(
          (items) => items.where((item) => item.id != deletedId).toList(),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Captura eliminada de tu biblioteca.')),
      );
      return;
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mis capturas'),
      actions: [
        IconButton(
          tooltip: _isGridView ? 'Ver como lista' : 'Ver como álbum',
          onPressed: () => setState(() => _isGridView = !_isGridView),
          icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
        ),
        IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: _PaperSheet(
      child: FutureBuilder<List<FishingCatch>>(
        future: _catches,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _NotebookLoadingView(
              message: 'Cargando tu biblioteca...',
            );
          }
          if (snapshot.hasError) {
            return _NotebookErrorView(
              title: 'No se pudieron cargar las capturas',
              message: 'Inténtalo de nuevo en unos segundos.',
              onRetry: _reload,
            );
          }
          final catches = snapshot.data!;
          if (catches.isEmpty) {
            return const _NotebookEmptyView(
              icon: Icons.phishing_outlined,
              message: 'Aún no has guardado ninguna captura.',
            );
          }
          final filteredCatches = _applyFilters(catches);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: _pagePadding,
              children: [
                _CatchFilters(
                  search: _search,
                  waterTypeFilter: _waterTypeFilter,
                  speciesFilter: _speciesFilter,
                  sortMode: _sortMode,
                  isExpanded: _filtersExpanded,
                  hasActiveFilters: _hasActiveFilters,
                  resultCount: filteredCatches.length,
                  onToggleExpanded: () =>
                      setState(() => _filtersExpanded = !_filtersExpanded),
                  onSearchChanged: (_) => setState(() {}),
                  onWaterTypeChanged: (value) => setState(() {
                    _waterTypeFilter = value;
                    _speciesFilter = 'all';
                  }),
                  onSpeciesChanged: (value) =>
                      setState(() => _speciesFilter = value),
                  onSortChanged: (value) => setState(() => _sortMode = value),
                  onClear: () => setState(() {
                    _search.clear();
                    _waterTypeFilter = 'all';
                    _speciesFilter = 'all';
                    _sortMode = 'date_desc';
                    _filtersExpanded = false;
                  }),
                ),
                const SizedBox(height: 8),
                if (filteredCatches.isEmpty)
                  const _NotebookEmptyView(
                    icon: Icons.filter_alt_off_outlined,
                    message: 'No hay capturas que coincidan con esos filtros.',
                  )
                else
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        alignment: Alignment.topCenter,
                        child: child,
                      ),
                    ),
                    child: _isGridView
                        ? GridView.builder(
                            key: const ValueKey('captures-grid'),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredCatches.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 0.72,
                                ),
                            itemBuilder: (context, index) {
                              final entry = filteredCatches[index];
                              return _AnimatedEntry(
                                delay: Duration(milliseconds: 35 * index),
                                child: _CatchGridCard(
                                  entry: entry,
                                  onTap: () => _openDetail(entry),
                                ),
                              );
                            },
                          )
                        : Column(
                            key: const ValueKey('captures-list'),
                            children: [
                              for (final (index, entry)
                                  in filteredCatches.indexed) ...[
                                _AnimatedEntry(
                                  delay: Duration(milliseconds: 35 * index),
                                  child: _CatchCard(
                                    entry: entry,
                                    onTap: () => _openDetail(entry),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ],
                          ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );

  List<FishingCatch> _applyFilters(List<FishingCatch> catches) {
    final query = _search.text.trim().toLowerCase();
    final result = catches.where((entry) {
      if (_waterTypeFilter != 'all' && entry.waterTypeId != _waterTypeFilter) {
        return false;
      }
      if (_speciesFilter != 'all' && entry.speciesId != _speciesFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final species = _speciesFor(entry);
      final searchable = [
        species?.commonName,
        species?.scientificName,
        _waterTypeFor(entry)?.name,
        entry.locationName,
        entry.baitOrLure,
        entry.technique,
        entry.notes,
      ].whereType<String>().join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();

    int compareNullableDouble(double? a, double? b) =>
        (b ?? -1).compareTo(a ?? -1);

    switch (_sortMode) {
      case 'date_asc':
        result.sort((a, b) => a.caughtAt.compareTo(b.caughtAt));
      case 'species':
        result.sort(
          (a, b) => (_speciesFor(a)?.commonName ?? '').compareTo(
            _speciesFor(b)?.commonName ?? '',
          ),
        );
      case 'weight_desc':
        result.sort((a, b) => compareNullableDouble(a.weightKg, b.weightKg));
      case 'length_desc':
        result.sort((a, b) => compareNullableDouble(a.lengthCm, b.lengthCm));
      default:
        result.sort((a, b) => b.caughtAt.compareTo(a.caughtAt));
    }
    return result;
  }

  bool get _hasActiveFilters =>
      _search.text.trim().isNotEmpty ||
      _waterTypeFilter != 'all' ||
      _speciesFilter != 'all' ||
      _sortMode != 'date_desc';
}

class _CatchFilters extends StatelessWidget {
  const _CatchFilters({
    required this.search,
    required this.waterTypeFilter,
    required this.speciesFilter,
    required this.sortMode,
    required this.isExpanded,
    required this.hasActiveFilters,
    required this.resultCount,
    required this.onToggleExpanded,
    required this.onSearchChanged,
    required this.onWaterTypeChanged,
    required this.onSpeciesChanged,
    required this.onSortChanged,
    required this.onClear,
  });

  final TextEditingController search;
  final String waterTypeFilter;
  final String speciesFilter;
  final String sortMode;
  final bool isExpanded;
  final bool hasActiveFilters;
  final int resultCount;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onWaterTypeChanged;
  final ValueChanged<String> onSpeciesChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final availableSpecies = _speciesForWaterType(waterTypeFilter);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onToggleExpanded,
                    icon: Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.filter_list,
                    ),
                    label: Text(
                      hasActiveFilters ? 'Filtros activos' : 'Filtros',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('$resultCount resultados'),
              ],
            ),
            AnimatedCrossFade(
              firstChild: hasActiveFilters
                  ? const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Toca “Filtros activos” para modificarlos.',
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    TextField(
                      controller: search,
                      decoration: const InputDecoration(
                        labelText:
                            'Buscar por pez, lugar, cebo, técnica o notas',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: onSearchChanged,
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        DropdownButtonFormField<String>(
                          key: ValueKey('water-$waterTypeFilter'),
                          initialValue: waterTypeFilter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de agua',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 'all',
                              child: Text('Todos'),
                            ),
                            for (final waterType in spainWaterTypes)
                              DropdownMenuItem(
                                value: waterType.id,
                                child: Text(waterType.name),
                              ),
                          ],
                          onChanged: (value) =>
                              onWaterTypeChanged(value ?? 'all'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'species-$waterTypeFilter-$speciesFilter',
                          ),
                          initialValue: speciesFilter,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Pez'),
                          items: [
                            const DropdownMenuItem(
                              value: 'all',
                              child: Text('Todos'),
                            ),
                            for (final species in availableSpecies)
                              DropdownMenuItem(
                                value: species.id,
                                child: Text(species.commonName),
                              ),
                          ],
                          onChanged: (value) =>
                              onSpeciesChanged(value ?? 'all'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('sort-$sortMode'),
                      initialValue: sortMode,
                      decoration: const InputDecoration(
                        labelText: 'Ordenar por',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'date_desc',
                          child: Text('Fecha: más recientes'),
                        ),
                        DropdownMenuItem(
                          value: 'date_asc',
                          child: Text('Fecha: más antiguas'),
                        ),
                        DropdownMenuItem(
                          value: 'species',
                          child: Text('Tipo de pez'),
                        ),
                        DropdownMenuItem(
                          value: 'weight_desc',
                          child: Text('Peso: mayor primero'),
                        ),
                        DropdownMenuItem(
                          value: 'length_desc',
                          child: Text('Longitud: mayor primero'),
                        ),
                      ],
                      onChanged: (value) => onSortChanged(value ?? 'date_desc'),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onClear,
                        icon: const Icon(Icons.clear),
                        label: const Text('Limpiar'),
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatchCard extends StatelessWidget {
  const _CatchCard({required this.entry, required this.onTap});
  final FishingCatch entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final species = _speciesFor(entry);
    final measurements = [
      if (entry.weightKg != null) '${entry.weightKg} kg',
      if (entry.lengthCm != null) '${entry.lengthCm} cm',
    ].join(' · ');
    final details = [
      MaterialLocalizations.of(context).formatMediumDate(entry.caughtAt),
      if (measurements.isNotEmpty) measurements,
      if (entry.locationName != null) entry.locationName!,
    ].join('\n');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.photoPath != null)
              Image.file(
                File(entry.photoPath!),
                width: double.infinity,
                height: 170,
                fit: BoxFit.cover,
                cacheWidth: 900,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ListTile(
              leading: _SpeciesIconAvatar(speciesId: entry.speciesId),
              title: Text(species?.commonName ?? 'Especie desconocida'),
              subtitle: Text(details),
              trailing: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatchGridCard extends StatelessWidget {
  const _CatchGridCard({required this.entry, required this.onTap});

  final FishingCatch entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final species = _speciesFor(entry);
    final date = MaterialLocalizations.of(context)
        .formatMediumDate(entry.caughtAt);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: entry.photoPath == null
                  ? Center(
                      child: _SpeciesIconAvatar(
                        speciesId: entry.speciesId,
                        radius: 38,
                      ),
                    )
                  : Image.file(
                      File(entry.photoPath!),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      cacheWidth: 700,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => Center(
                        child: _SpeciesIconAvatar(
                          speciesId: entry.speciesId,
                          radius: 34,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    species?.commonName ?? 'Especie desconocida',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      date,
                      if (entry.locationName != null) entry.locationName!,
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  late Future<List<File>> _backups;
  bool _isBusy = false;
  File? _lastExportedFile;

  @override
  void initState() {
    super.initState();
    _backups = BackupRepository.instance.listBackups();
  }

  void _reload() {
    setState(() {
      _backups = BackupRepository.instance.listBackups();
    });
  }

  Future<void> _export() async {
    setState(() => _isBusy = true);
    try {
      final file = await BackupRepository.instance.exportCaptures();
      if (!mounted) return;
      setState(() {
        _lastExportedFile = file;
        _backups = BackupRepository.instance.listBackups();
      });
      await Clipboard.setData(ClipboardData(text: file.path));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copia creada. Ruta copiada al portapapeles.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear la copia.')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _restoreLatest(List<File> backups) async {
    if (backups.isEmpty) return;
    final latest = backups.first;
    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar copia'),
        content: const Text(
          'Se reemplazarán las capturas actuales por las de la última copia. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.restore_outlined),
            label: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (shouldRestore != true) return;
    setState(() => _isBusy = true);
    try {
      final count = await BackupRepository.instance.restore(latest);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copia restaurada: $count capturas.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo restaurar la copia.')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Copia de seguridad'),
      actions: [
        IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: _PaperSheet(
      child: FutureBuilder<List<File>>(
        future: _backups,
        builder: (context, snapshot) {
          final backups = snapshot.data ?? const <File>[];
          return ListView(
            padding: _pagePadding,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            color: _accentBrown,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Guardar tu diario',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Crea un archivo con todas tus capturas y las fotos disponibles para tener una copia de seguridad completa.',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nota: las copias completas pueden ocupar más espacio si tienes muchas fotos.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _isBusy ? null : _export,
                        icon: _isBusy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_alt_outlined),
                        label: const Text('Crear copia ahora'),
                      ),
                    ],
                  ),
                ),
              ),
              if (_lastExportedFile != null) ...[
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.folder_copy_outlined),
                    title: const Text('Última copia creada'),
                    subtitle: Text(_lastExportedFile!.path),
                    trailing: IconButton(
                      tooltip: 'Copiar ruta',
                      icon: const Icon(Icons.copy_outlined),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _lastExportedFile!.path),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ruta copiada.')),
                        );
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.restore_outlined,
                            color: _accentBrown,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Restaurar',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        backups.isEmpty
                            ? 'Todavía no hay copias disponibles.'
                            : 'Copias encontradas: ${backups.length}',
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _isBusy || backups.isEmpty
                            ? null
                            : () => _restoreLatest(backups),
                        icon: const Icon(Icons.restore_outlined),
                        label: const Text('Restaurar última copia'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (snapshot.connectionState != ConnectionState.done)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: _NotebookLoadingView(
                    message: 'Buscando copias guardadas...',
                  ),
                )
              else if (snapshot.hasError)
                _NotebookErrorView(
                  title: 'No se pudieron cargar las copias',
                  message: 'Puedes crear una copia nueva o reintentarlo.',
                  onRetry: _reload,
                )
              else if (backups.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Copias disponibles',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        for (final file in backups.take(5))
                          _BackupFileTile(file: file),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class _BackupFileTile extends StatelessWidget {
  const _BackupFileTile({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    final modified = file.lastModifiedSync();
    return FutureBuilder<BackupPreview>(
      future: BackupRepository.instance.preview(file),
      builder: (context, snapshot) {
        final preview = snapshot.data;
        final details = preview == null
            ? '${MaterialLocalizations.of(context).formatMediumDate(modified)} · '
                  '${TimeOfDay.fromDateTime(modified).format(context)}'
            : '${preview.capturesCount} capturas · ${preview.photosCount} fotos';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            preview != null && preview.photosCount > 0
                ? Icons.photo_library_outlined
                : Icons.description_outlined,
          ),
          title: Text(file.uri.pathSegments.last),
          subtitle: Text(details),
          trailing: IconButton(
            tooltip: 'Copiar ruta',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: file.path));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Ruta copiada.')));
            },
          ),
        );
      },
    );
  }
}

class CatchCalendarScreen extends StatefulWidget {
  const CatchCalendarScreen({super.key});

  @override
  State<CatchCalendarScreen> createState() => _CatchCalendarScreenState();
}

class _CatchCalendarScreenState extends State<CatchCalendarScreen> {
  late Future<List<FishingCatch>> _catches;
  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _visibleMonth = DateTime(today.year, today.month);
    _selectedDay = today;
    _catches = CatchRepository.instance.getAll();
  }

  void _reload() {
    setState(() {
      _catches = CatchRepository.instance.getAll();
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      _selectedDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    });
  }

  Future<void> _openDetail(FishingCatch entry) async {
    final deletedId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => CatchDetailScreen(entry: entry)),
    );
    if (!mounted) return;
    _reload();
    if (deletedId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Captura eliminada de tu biblioteca.')),
      );
    }
  }

  Map<DateTime, List<FishingCatch>> _groupByDay(List<FishingCatch> catches) {
    final grouped = <DateTime, List<FishingCatch>>{};
    for (final entry in catches) {
      final day = DateUtils.dateOnly(entry.caughtAt);
      grouped.putIfAbsent(day, () => []).add(entry);
    }
    for (final entries in grouped.values) {
      entries.sort((a, b) => b.caughtAt.compareTo(a.caughtAt));
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Calendario'),
      actions: [
        IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: _PaperSheet(
      child: FutureBuilder<List<FishingCatch>>(
        future: _catches,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _NotebookLoadingView(
              message: 'Preparando calendario...',
            );
          }
          if (snapshot.hasError) {
            return _NotebookErrorView(
              title: 'No se pudo cargar el calendario',
              message: 'Inténtalo de nuevo en unos segundos.',
              onRetry: _reload,
            );
          }

          final catches = snapshot.data!;
          if (catches.isEmpty) {
            return const _NotebookEmptyView(
              icon: Icons.calendar_month_outlined,
              message: 'Aún no tienes capturas para mostrar en el calendario.',
            );
          }

          final grouped = _groupByDay(catches);
          final selectedEntries =
              grouped[DateUtils.dateOnly(_selectedDay)] ?? const [];
          final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month);
          final daysInMonth = DateUtils.getDaysInMonth(
            _visibleMonth.year,
            _visibleMonth.month,
          );
          final leadingEmptyDays = (firstDay.weekday + 6) % 7;
          final totalCells = leadingEmptyDays + daysInMonth;

          return ListView(
            padding: _pagePadding,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _MapRoundButton(
                            tooltip: 'Mes anterior',
                            icon: Icons.chevron_left,
                            onPressed: () => _changeMonth(-1),
                          ),
                          Expanded(
                            child: Text(
                              MaterialLocalizations.of(context)
                                  .formatMonthYear(_visibleMonth),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          _MapRoundButton(
                            tooltip: 'Mes siguiente',
                            icon: Icons.chevron_right,
                            onPressed: () => _changeMonth(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Row(
                        children: [
                          _WeekdayLabel('L'),
                          _WeekdayLabel('M'),
                          _WeekdayLabel('X'),
                          _WeekdayLabel('J'),
                          _WeekdayLabel('V'),
                          _WeekdayLabel('S'),
                          _WeekdayLabel('D'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 6,
                              crossAxisSpacing: 6,
                            ),
                        itemCount: totalCells,
                        itemBuilder: (context, index) {
                          if (index < leadingEmptyDays) {
                            return const SizedBox.shrink();
                          }
                          final dayNumber = index - leadingEmptyDays + 1;
                          final day = DateTime(
                            _visibleMonth.year,
                            _visibleMonth.month,
                            dayNumber,
                          );
                          final capturesCount =
                              grouped[DateUtils.dateOnly(day)]?.length ?? 0;
                          return _CalendarDayButton(
                            day: dayNumber,
                            capturesCount: capturesCount,
                            isSelected: DateUtils.isSameDay(day, _selectedDay),
                            isToday: DateUtils.isSameDay(day, DateTime.now()),
                            onTap: () => setState(() => _selectedDay = day),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                MaterialLocalizations.of(context).formatFullDate(_selectedDay),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (selectedEntries.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('No hay capturas guardadas este día.'),
                  ),
                )
              else
                for (final entry in selectedEntries)
                  _CatchCard(entry: entry, onTap: () => _openDetail(entry)),
            ],
          );
        },
      ),
    ),
  );
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: _accentBrown),
    ),
  );
}

class _CalendarDayButton extends StatelessWidget {
  const _CalendarDayButton({
    required this.day,
    required this.capturesCount,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final int capturesCount;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasCaptures = capturesCount > 0;
    final backgroundColor = isSelected
        ? _buttonBeige
        : hasCaptures
        ? _stampPaper
        : _paperCard;
    final borderColor = isSelected
        ? _accentBrown
        : isToday
        ? _buttonBeige
        : _lineBrown;

    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: isSelected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Text(
                '$day',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (hasCaptures)
              Positioned(
                right: 4,
                bottom: 3,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: _accentBrown,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      '$capturesCount',
                      style: const TextStyle(
                        color: _paperCard,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CatchStatsScreen extends StatefulWidget {
  const CatchStatsScreen({super.key});

  @override
  State<CatchStatsScreen> createState() => _CatchStatsScreenState();
}

class _CatchStatsScreenState extends State<CatchStatsScreen> {
  late Future<List<FishingCatch>> _catches;

  @override
  void initState() {
    super.initState();
    _catches = CatchRepository.instance.getAll();
  }

  void _reload() {
    setState(() {
      _catches = CatchRepository.instance.getAll();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Estadísticas'),
      actions: [
        IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: _PaperSheet(
      child: FutureBuilder<List<FishingCatch>>(
        future: _catches,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _NotebookLoadingView(
              message: 'Calculando estadísticas...',
            );
          }
          if (snapshot.hasError) {
            return _NotebookErrorView(
              title: 'No se pudieron cargar las estadísticas',
              message: 'Inténtalo de nuevo en unos segundos.',
              onRetry: _reload,
            );
          }

          final catches = snapshot.data!;
          if (catches.isEmpty) {
            return const _NotebookEmptyView(
              icon: Icons.insights_outlined,
              message: 'Guarda alguna captura para ver tus estadísticas.',
            );
          }

          final stats = _CatchStats.from(catches);

          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: _pagePadding,
              children: [
                Text(
                  'Resumen del diario',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.25,
                  children: [
                    _StatCard(
                      icon: Icons.phishing_outlined,
                      label: 'Capturas',
                      value: '${stats.total}',
                    ),
                    _StatCard(
                      icon: Icons.set_meal_outlined,
                      label: 'Pez favorito',
                      value: stats.favoriteSpecies,
                    ),
                    _StatCard(
                      icon: Icons.scale_outlined,
                      label: 'Mayor peso',
                      value: stats.maxWeight,
                    ),
                    _StatCard(
                      icon: Icons.straighten_outlined,
                      label: 'Mayor longitud',
                      value: stats.maxLength,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Por tipo de agua',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        for (final waterType in spainWaterTypes)
                          _StatsLine(
                            label: waterType.name,
                            value:
                                '${stats.waterTypeCounts[waterType.id] ?? 0}',
                            icon: Icons.water_outlined,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top especies',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        for (final entry in stats.topSpecies)
                          _StatsLine(
                            label: entry.name,
                            value: '${entry.count}',
                            icon: Icons.set_meal_outlined,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meses con más movimiento',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        for (final entry in stats.topMonths)
                          _StatsLine(
                            label: entry.name,
                            value: '${entry.count}',
                            icon: Icons.calendar_month_outlined,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lugares más repetidos',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        if (stats.topPlaces.isEmpty)
                          const Text('Aún no hay lugares guardados.')
                        else
                          for (final entry in stats.topPlaces)
                            _StatsLine(
                              label: entry.name,
                              value: '${entry.count}',
                              icon: Icons.place_outlined,
                            ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _CatchStats {
  const _CatchStats({
    required this.total,
    required this.favoriteSpecies,
    required this.maxWeight,
    required this.maxLength,
    required this.waterTypeCounts,
    required this.topSpecies,
    required this.topMonths,
    required this.topPlaces,
  });

  final int total;
  final String favoriteSpecies;
  final String maxWeight;
  final String maxLength;
  final Map<String, int> waterTypeCounts;
  final List<_SpeciesCount> topSpecies;
  final List<_SpeciesCount> topMonths;
  final List<_SpeciesCount> topPlaces;

  factory _CatchStats.from(List<FishingCatch> catches) {
    final speciesCounts = <String, int>{};
    final waterTypeCounts = <String, int>{};
    final monthCounts = <String, int>{};
    final placeCounts = <String, int>{};
    double? maxWeight;
    double? maxLength;

    for (final entry in catches) {
      speciesCounts.update(
        entry.speciesId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      waterTypeCounts.update(
        entry.waterTypeId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      monthCounts.update(
        _monthKey(entry.caughtAt),
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      final place = entry.locationName?.trim();
      if (place != null && place.isNotEmpty) {
        placeCounts.update(place, (value) => value + 1, ifAbsent: () => 1);
      }
      final weight = entry.weightKg;
      if (weight != null && (maxWeight == null || weight > maxWeight)) {
        maxWeight = weight;
      }
      final length = entry.lengthCm;
      if (length != null && (maxLength == null || length > maxLength)) {
        maxLength = length;
      }
    }

    final sortedSpecies = speciesCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topSpecies = sortedSpecies
        .take(5)
        .map(
          (entry) => _SpeciesCount(
            name: _speciesNameById(entry.key),
            count: entry.value,
          ),
        )
        .toList();
    final topMonths = _sortedCounts(monthCounts).take(5).toList();
    final topPlaces = _sortedCounts(placeCounts).take(5).toList();

    return _CatchStats(
      total: catches.length,
      favoriteSpecies: topSpecies.isEmpty ? 'Sin datos' : topSpecies.first.name,
      maxWeight: maxWeight == null
          ? 'Sin dato'
          : '${_formatNumber(maxWeight)} kg',
      maxLength: maxLength == null
          ? 'Sin dato'
          : '${_formatNumber(maxLength)} cm',
      waterTypeCounts: waterTypeCounts,
      topSpecies: topSpecies,
      topMonths: topMonths,
      topPlaces: topPlaces,
    );
  }

  static String _monthKey(DateTime date) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  static List<_SpeciesCount> _sortedCounts(Map<String, int> counts) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map((entry) => _SpeciesCount(name: entry.key, count: entry.value))
        .toList();
  }
}

class _SpeciesCount {
  const _SpeciesCount({required this.name, required this.count});

  final String name;
  final int count;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _accentBrown),
          const Spacer(),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    ),
  );
}

class _StatsLine extends StatelessWidget {
  const _StatsLine({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, size: 20, color: _accentBrown),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}

class AllCapturesMapScreen extends StatefulWidget {
  const AllCapturesMapScreen({super.key});

  @override
  State<AllCapturesMapScreen> createState() => _AllCapturesMapScreenState();
}

class _AllCapturesMapScreenState extends State<AllCapturesMapScreen> {
  final _mapController = MapController();
  late Future<List<FishingCatch>> _catches;
  late Future<List<SharedCaptureMap>> _sharedMaps;
  String _waterTypeFilter = 'all';
  String _speciesFilter = 'all';
  double _zoom = 6;

  @override
  void initState() {
    super.initState();
    _catches = CatchRepository.instance.getAllWithLocation();
    _sharedMaps = SharedMapRepository.instance.getAll();
  }

  void _reload() {
    setState(() {
      _catches = CatchRepository.instance.getAllWithLocation();
      _sharedMaps = SharedMapRepository.instance.getAll();
    });
  }

  Future<void> _openDetail(FishingCatch entry) async {
    final deletedId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => CatchDetailScreen(entry: entry)),
    );
    if (!mounted) return;
    _reload();
    if (deletedId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Captura eliminada de tu biblioteca.')),
      );
    }
  }

  LatLng _centerFor(List<LatLng> points) {
    final latitude =
        points.map((point) => point.latitude).reduce((a, b) => a + b) /
        points.length;
    final longitude =
        points.map((point) => point.longitude).reduce((a, b) => a + b) /
        points.length;
    return LatLng(latitude, longitude);
  }

  void _moveTo(LatLng point, double zoom) {
    setState(() => _zoom = zoom.clamp(3, 19).toDouble());
    _mapController.move(point, _zoom);
  }

  List<FishingCatch> _applyFilters(List<FishingCatch> catches) => catches.where(
    (entry) {
      if (_waterTypeFilter != 'all' && entry.waterTypeId != _waterTypeFilter) {
        return false;
      }
      if (_speciesFilter != 'all' && entry.speciesId != _speciesFilter) {
        return false;
      }
      return true;
    },
  ).toList();

  List<LatLng> _allVisiblePoints(
    List<FishingCatch> catches,
    List<SharedCaptureMap> sharedMaps,
  ) => [
    for (final entry in catches) LatLng(entry.latitude!, entry.longitude!),
    for (final map in sharedMaps)
      for (final point in map.points) LatLng(point.latitude, point.longitude),
  ];

  void _showSharedPoint(SharedCaptureMap sharedMap, SharedCapturePoint point) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _paperCard,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: point.photoPath == null ? 0.48 : 0.72,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
          children: [
            Row(
              children: [
                _SharedLegendDot(color: Color(sharedMap.colorValue)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sharedMap.ownerName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (point.photoPath != null) ...[
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullScreenPhoto(
                      path: point.photoPath!,
                      heroTag:
                          'shared-photo-${sharedMap.id}-${point.caughtAt.microsecondsSinceEpoch}',
                      title: point.speciesName,
                      subtitle:
                          '${sharedMap.ownerName} · ${MaterialLocalizations.of(context).formatShortDate(point.caughtAt)}',
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(point.photoPath!),
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    cacheWidth: 1000,
                    errorBuilder: (_, _, _) => const _PhotoError(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Text(
              point.speciesName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(point.locationName),
            const SizedBox(height: 8),
            Text(
              '${MaterialLocalizations.of(context).formatFullDate(point.caughtAt)} · ${TimeOfDay.fromDateTime(point.caughtAt).format(context)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (point.weightKg != null)
                  _SharedPointChip(
                    icon: Icons.monitor_weight_outlined,
                    label: '${point.weightKg!.toStringAsFixed(1)} kg',
                  ),
                if (point.lengthCm != null)
                  _SharedPointChip(
                    icon: Icons.straighten_outlined,
                    label: '${point.lengthCm!.toStringAsFixed(1)} cm',
                  ),
                if (point.baitOrLure?.trim().isNotEmpty == true)
                  _SharedPointChip(
                    icon: Icons.sports_baseball_outlined,
                    label: point.baitOrLure!.trim(),
                  ),
                if (point.technique?.trim().isNotEmpty == true)
                  _SharedPointChip(
                    icon: Icons.gesture_outlined,
                    label: point.technique!.trim(),
                  ),
              ],
            ),
            if (point.notes?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 14),
              Text('Notas', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(point.notes!.trim()),
            ],
            const SizedBox(height: 12),
            Text(
              '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mapa de capturas'),
      actions: [
        IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
      ],
    ),
    body: _PaperSheet(
      child: FutureBuilder<List<dynamic>>(
        future: Future.wait([_catches, _sharedMaps]),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _NotebookLoadingView(
              message: 'Cargando mapa de capturas...',
            );
          }
          if (snapshot.hasError) {
            return _NotebookErrorView(
              title: 'No se pudo cargar el mapa',
              message: 'Inténtalo de nuevo en unos segundos.',
              onRetry: _reload,
            );
          }

          final allLocatedCatches = snapshot.data![0] as List<FishingCatch>;
          final sharedMaps = snapshot.data![1] as List<SharedCaptureMap>;
          if (allLocatedCatches.isEmpty && sharedMaps.isEmpty) {
            return const _NotebookEmptyView(
              icon: Icons.map_outlined,
              message: 'Aún no tienes capturas con ubicación GPS.',
            );
          }
          final locatedCatches = _applyFilters(allLocatedCatches);
          final visiblePoints = _allVisiblePoints(locatedCatches, sharedMaps);
          if (visiblePoints.isEmpty) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(38, 14, 14, 0),
                  child: _MapFiltersCard(
                    waterTypeFilter: _waterTypeFilter,
                    speciesFilter: _speciesFilter,
                    resultCount: 0,
                    onWaterTypeChanged: (value) => setState(() {
                      _waterTypeFilter = value;
                      _speciesFilter = 'all';
                    }),
                    onSpeciesChanged: (value) =>
                        setState(() => _speciesFilter = value),
                    onClear: () => setState(() {
                      _waterTypeFilter = 'all';
                      _speciesFilter = 'all';
                    }),
                  ),
                ),
                const Expanded(
                  child: _NotebookEmptyView(
                    icon: Icons.filter_alt_off_outlined,
                    message: 'No hay capturas con GPS que coincidan con esos filtros.',
                  ),
                ),
              ],
            );
          }

          final center = _centerFor(visiblePoints);
          final initialZoom = visiblePoints.length == 1 ? 15.0 : 6.0;

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(38, 126, 14, 110),
                child: _NotebookMapFrame(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: initialZoom,
                      interactionOptions: const InteractionOptions(
                        flags:
                            InteractiveFlag.drag |
                            InteractiveFlag.pinchZoom |
                            InteractiveFlag.doubleTapZoom |
                            InteractiveFlag.flingAnimation,
                      ),
                      onPositionChanged: (position, _) {
                        _zoom = position.zoom;
                      },
                    ),
                    children: [
                      _baseTileLayer(),
                      MarkerLayer(
                        markers: [
                          for (final entry in locatedCatches)
                            Marker(
                              point: LatLng(entry.latitude!, entry.longitude!),
                              width: 58,
                              height: 58,
                              child: _CatchMapMarker(
                                tooltip:
                                    _speciesFor(entry)?.commonName ?? 'Captura',
                                onTap: () => _openDetail(entry),
                              ),
                            ),
                          for (final sharedMap in sharedMaps)
                            for (final point in sharedMap.points)
                              Marker(
                                point: LatLng(point.latitude, point.longitude),
                                width: 58,
                                height: 58,
                                child: _CatchMapMarker(
                                  color: Color(sharedMap.colorValue),
                                  icon: Icons.person_pin_circle_outlined,
                                  tooltip:
                                      '${sharedMap.ownerName}: ${point.speciesName}',
                                  onTap: () =>
                                      _showSharedPoint(sharedMap, point),
                                ),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 38,
                right: 14,
                child: _MapFiltersCard(
                  waterTypeFilter: _waterTypeFilter,
                  speciesFilter: _speciesFilter,
                  resultCount: locatedCatches.length,
                  onWaterTypeChanged: (value) => setState(() {
                    _waterTypeFilter = value;
                    _speciesFilter = 'all';
                  }),
                  onSpeciesChanged: (value) =>
                      setState(() => _speciesFilter = value),
                  onClear: () => setState(() {
                    _waterTypeFilter = 'all';
                    _speciesFilter = 'all';
                  }),
                ),
              ),
              Positioned(
                left: 38,
                right: 14,
                bottom: 22,
                child: _MapControlCard(
                  label:
                      '${locatedCatches.length} tuyas · ${sharedMaps.fold<int>(0, (total, map) => total + map.points.length)} compartidas',
                  onZoomOut: () => _moveTo(center, _zoom - 1),
                  onCenter: () => _moveTo(center, initialZoom),
                  onZoomIn: () => _moveTo(center, _zoom + 1),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _SharedPointChip extends StatelessWidget {
  const _SharedPointChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 16, color: _accentBrown),
    label: Text(label),
    backgroundColor: _paper,
    side: const BorderSide(color: _lineBrown),
  );
}

class SharingHubScreen extends StatefulWidget {
  const SharingHubScreen({super.key});

  @override
  State<SharingHubScreen> createState() => _SharingHubScreenState();
}

class _SharingHubScreenState extends State<SharingHubScreen> {
  late Future<List<FishingCatch>> _catches;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _catches = CatchRepository.instance.getAll();
  }

  Future<void> _openShare(List<FishingCatch> catches) async {
    final deviceId = await SharedMapRepository.instance.getLocalDeviceId();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ShareDiaryCodeScreen(catches: catches, deviceId: deviceId),
      ),
    );
  }

  Future<void> _openImport() async {
    final importedLabel = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ImportLocationsCodeScreen()),
    );
    if (!mounted || importedLabel == null) return;
    setState(_reload);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(importedLabel)));
  }

  Future<void> _openPeople() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SharedPeopleScreen()));
    if (!mounted) return;
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Compartir ubicaciones')),
    body: _PaperSheet(
      child: FutureBuilder<List<FishingCatch>>(
        future: _catches,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _NotebookLoadingView(
              message: 'Preparando tu diario compartido...',
            );
          }
          if (snapshot.hasError) {
            return _NotebookErrorView(
              title: 'No se pudo abrir compartir',
              message: 'Inténtalo de nuevo en unos segundos.',
              onRetry: () => setState(_reload),
            );
          }

          final catches = snapshot.data ?? const <FishingCatch>[];
          final locatedCount = catches
              .where(
                (entry) => entry.latitude != null && entry.longitude != null,
              )
              .length;
          return ListView(
            padding: _pagePaddingLarge,
            children: [
              Text(
                'Compartir con otros dispositivos',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Desde aquí puedes enviar tus ubicaciones, importar puntos de otra persona y limpiar lo que ya no quieras ver.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              _AnimatedEntry(
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    leading: const CircleAvatar(
                      backgroundColor: _stampPaper,
                      foregroundColor: _accentBrown,
                      child: Icon(Icons.qr_code_2_outlined),
                    ),
                    title: const Text('Generar código para compartir'),
                    subtitle: Text('$locatedCount ubicaciones disponibles'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openShare(catches),
                  ),
                ),
              ),
              _AnimatedEntry(
                delay: const Duration(milliseconds: 70),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    leading: const CircleAvatar(
                      backgroundColor: _stampPaper,
                      foregroundColor: _accentBrown,
                      child: Icon(Icons.content_paste_go_outlined),
                    ),
                    title: const Text('Recibir código'),
                    subtitle: const Text('Importa ubicaciones de otra persona'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openImport,
                  ),
                ),
              ),
              _AnimatedEntry(
                delay: const Duration(milliseconds: 140),
                child: Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    leading: const CircleAvatar(
                      backgroundColor: _stampPaper,
                      foregroundColor: _accentBrown,
                      child: Icon(Icons.manage_accounts_outlined),
                    ),
                    title: const Text('Personas compartidas'),
                    subtitle: const Text('Borra ubicaciones importadas'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openPeople,
                  ),
                ),
              ),
              const _AnimatedEntry(
                delay: Duration(milliseconds: 210),
                child: _PrivacyNoteCard(),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class SharedPeopleScreen extends StatefulWidget {
  const SharedPeopleScreen({super.key});

  @override
  State<SharedPeopleScreen> createState() => _SharedPeopleScreenState();
}

class _SharedPeopleScreenState extends State<SharedPeopleScreen> {
  late Future<List<_SharedPersonSummary>> _people;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _people = _loadPeople();
  }

  Future<List<_SharedPersonSummary>> _loadPeople() async {
    final sharedMaps = await SharedMapRepository.instance.getAll();
    final catches = await CatchRepository.instance.getAll();
    final summaries = <String, _SharedPersonSummary>{};

    _SharedPersonSummary summaryFor(String ownerName) {
      final key = ownerName.trim().toLowerCase();
      return summaries.putIfAbsent(
        key,
        () => _SharedPersonSummary(ownerName: ownerName.trim()),
      );
    }

    for (final map in sharedMaps) {
      if (map.ownerName.trim().isEmpty) continue;
      summaryFor(map.ownerName).sharedMaps.add(map);
    }
    for (final entry in catches) {
      final ownerName = _importedOwnerFor(entry);
      if (ownerName == null) continue;
      summaryFor(ownerName).importedCaptures.add(entry);
    }

    final people = summaries.values.toList()
      ..sort(
        (a, b) =>
            a.ownerName.toLowerCase().compareTo(b.ownerName.toLowerCase()),
      );
    return people;
  }

  Future<void> _deletePerson(_SharedPersonSummary person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Borrar datos de ${person.ownerName}?'),
        content: Text(
          'Se eliminarán ${person.importedCaptures.length + person.sharedPointCount} ubicaciones compartidas de esta persona.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(context).pop(true);
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    for (final map in person.sharedMaps) {
      for (final point in map.points) {
        await PhotoStorage.deleteIfExists(point.photoPath);
      }
    }
    await SharedMapRepository.instance.deleteByOwnerName(person.ownerName);
    for (final entry in person.importedCaptures) {
      await CatchRepository.instance.deleteById(entry.id);
      await PhotoStorage.deleteIfExists(entry.photoPath);
    }

    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Datos de ${person.ownerName} eliminados.')),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Personas compartidas'),
      actions: [
        IconButton(
          onPressed: () => setState(_reload),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: _PaperSheet(
      child: FutureBuilder<List<_SharedPersonSummary>>(
        future: _people,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _NotebookLoadingView(
              message: 'Revisando personas compartidas...',
            );
          }
          if (snapshot.hasError) {
            return _NotebookErrorView(
              title: 'No se pudo cargar la lista',
              message: 'Inténtalo de nuevo en unos segundos.',
              onRetry: () => setState(_reload),
            );
          }

          final people = snapshot.data ?? const <_SharedPersonSummary>[];
          if (people.isEmpty) {
            return const _NotebookEmptyView(
              icon: Icons.people_outline,
              message: 'Aún no has importado datos de otra persona.',
            );
          }

          return ListView(
            padding: _pagePaddingLarge,
            children: [
              Text(
                'Datos importados',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Aquí puedes borrar todas las ubicaciones que hayas recibido de una persona.',
              ),
              const SizedBox(height: 18),
              for (final (index, person) in people.indexed)
                _AnimatedEntry(
                  delay: Duration(milliseconds: 60 * index),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(18),
                      leading: CircleAvatar(
                        backgroundColor: Color(person.colorValue),
                        foregroundColor: Colors.white,
                        child: const Icon(Icons.person_pin_circle_outlined),
                      ),
                      title: Text(person.ownerName),
                      subtitle: Text(
                        '${person.importedCaptures.length + person.sharedPointCount} ubicaciones compartidas',
                      ),
                      trailing: IconButton(
                        tooltip: 'Borrar datos de esta persona',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deletePerson(person),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class _SharedPersonSummary {
  _SharedPersonSummary({required this.ownerName});

  final String ownerName;
  final List<SharedCaptureMap> sharedMaps = [];
  final List<FishingCatch> importedCaptures = [];

  int get sharedPointCount =>
      sharedMaps.fold(0, (total, map) => total + map.points.length);

  int get colorValue => sharedMaps.isEmpty
      ? _sharedColorFor(ownerName.hashCode.abs())
      : sharedMaps.first.colorValue;
}

String? _importedOwnerFor(FishingCatch entry) {
  final notes = entry.notes;
  if (notes == null || notes.trim().isEmpty) return null;
  for (final line in notes.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.startsWith('Importada de ')) {
      final ownerName = trimmed.substring('Importada de '.length).trim();
      if (ownerName.isNotEmpty) return ownerName;
    }
  }
  return null;
}

class _SharedLocationsPayload {
  const _SharedLocationsPayload({
    required this.sourceDeviceId,
    required this.points,
  });

  final String? sourceDeviceId;
  final List<SharedCapturePoint> points;
}

_SharedLocationsPayload? _sharedPayloadFromCode(String payload) {
  try {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) return null;
    final type = decoded['type'];
    if (type != 'pescatronik_locations' && type != 'pescatronik_share') {
      return null;
    }
    final points = (decoded['points'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SharedCapturePoint.fromJson)
        .where(_isValidSharedPoint)
        .toList();
    return _SharedLocationsPayload(
      sourceDeviceId: decoded['sourceDeviceId'] as String?,
      points: points,
    );
  } catch (_) {
    return null;
  }
}

bool _isValidSharedPoint(SharedCapturePoint point) =>
    point.latitude >= -90 &&
    point.latitude <= 90 &&
    point.longitude >= -180 &&
    point.longitude <= 180;

class ShareDiaryCodeScreen extends StatefulWidget {
  const ShareDiaryCodeScreen({
    super.key,
    required this.catches,
    required this.deviceId,
  });

  final List<FishingCatch> catches;
  final String deviceId;

  @override
  State<ShareDiaryCodeScreen> createState() => _ShareDiaryCodeScreenState();
}

class _ShareDiaryCodeScreenState extends State<ShareDiaryCodeScreen> {
  String get _payload {
    final locatedCatches = widget.catches
        .where((entry) => entry.latitude != null && entry.longitude != null)
        .toList();
    final points = locatedCatches
        .map((entry) => _sharedPointForCatch(entry).toJson())
        .toList();
    return jsonEncode({
      'type': 'pescatronik_share',
      'version': 4,
      'mode': 'locations',
      'sourceDeviceId': widget.deviceId,
      'createdAt': DateTime.now().toIso8601String(),
      'points': points,
    });
  }

  @override
  Widget build(BuildContext context) {
    final locatedCount = widget.catches
        .where((entry) => entry.latitude != null && entry.longitude != null)
        .length;
    final itemCount = locatedCount;
    final excludedCount = widget.catches.length - locatedCount;
    return Scaffold(
      appBar: AppBar(title: const Text('Compartir ubicaciones')),
      body: _PaperSheet(
        child: Padding(
          padding: _pagePaddingLarge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tu código BIDI',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Comparte únicamente las ubicaciones de tus capturas para que otra persona pueda verlas en su mapa.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 22),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: itemCount == 0
                      ? const _NotebookEmptyView(
                          icon: Icons.location_off_outlined,
                          message: 'No tienes capturas con GPS para compartir.',
                        )
                      : Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: _lineBrown),
                              ),
                              child: QrImageView(
                                data: _payload,
                                version: QrVersions.auto,
                                size: 245,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.circle,
                                  color: _ink,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.circle,
                                  color: _ink,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              '$itemCount ubicaciones incluidas',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (excludedCount > 0) ...[
                              const SizedBox(height: 4),
                              Text(
                                '$excludedCount capturas sin GPS no se incluyen porque no pueden aparecer en el mapa.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Text(
                              'Se comparten coordenadas, lugar, especie y fecha. No se envían fotos ni datos privados de la captura.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: _payload),
                                );
                                HapticFeedback.selectionClick();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Código copiado.'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy_outlined),
                              label: const Text('Copiar código'),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

SharedCapturePoint _sharedPointForCatch(FishingCatch entry) {
  final place = entry.locationName?.trim() ?? '';
  return SharedCapturePoint(
    latitude: entry.latitude!,
    longitude: entry.longitude!,
    speciesName: _speciesFor(entry)?.commonName ?? 'Captura',
    locationName: place.isEmpty ? 'Lugar sin nombre' : place,
    caughtAt: entry.caughtAt,
  );
}

class ImportLocationsCodeScreen extends StatefulWidget {
  const ImportLocationsCodeScreen({super.key});

  @override
  State<ImportLocationsCodeScreen> createState() =>
      _ImportLocationsCodeScreenState();
}

class _ImportLocationsCodeScreenState extends State<ImportLocationsCodeScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  String? _errorText;
  int? _pointCount;
  bool _saving = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    final payload = _sharedPayloadFromCode(_codeController.text.trim());
    setState(() {
      _errorText = null;
      _pointCount = payload?.points.length;
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    _codeController.text = text;
    _refreshPreview();
  }

  Future<void> _import() async {
    if (_saving) return;
    final payload = _sharedPayloadFromCode(_codeController.text.trim());
    final itemCount = payload?.points.length ?? 0;
    if (payload == null || itemCount == 0) {
      setState(() {
        _errorText = 'Ese código no contiene datos válidos.';
        _pointCount = null;
      });
      return;
    }

    final localDeviceId = await SharedMapRepository.instance.getLocalDeviceId();
    if (!mounted) return;
    if (payload.sourceDeviceId == localDeviceId) {
      setState(() {
        _errorText = 'Este código se generó en este mismo dispositivo.';
        _pointCount = itemCount;
      });
      return;
    }

    final ownerName = _nameController.text.trim();
    if (ownerName.isEmpty) {
      setState(() {
        _errorText = null;
        _pointCount = itemCount;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pon el nombre de la persona.')),
      );
      return;
    }

    setState(() => _saving = true);
    final existing = await SharedMapRepository.instance.getAll();
    final importedAt = DateTime.now();
    final importId = importedAt.microsecondsSinceEpoch.toString();
    final sharedMap = SharedCaptureMap(
      id: importId,
      ownerName: ownerName,
      colorValue: _sharedColorFor(existing.length),
      importedAt: importedAt,
      points: payload.points,
    );
    await SharedMapRepository.instance.save(sharedMap);
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop('Ubicaciones de $ownerName añadidas al mapa.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recibir ubicaciones')),
    body: _PaperSheet(
      child: ListView(
        padding: _pagePaddingLarge,
        children: [
          Text(
            'Pega el código recibido',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Copia el código en el otro dispositivo y pégalo aquí. Después pon el nombre de la persona para identificar sus puntos en el mapa.',
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _codeController,
            minLines: 5,
            maxLines: 8,
            onChanged: (_) => _refreshPreview(),
            decoration: InputDecoration(
              labelText: 'Código compartido',
              alignLabelWithHint: true,
              errorText: _errorText,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Nombre de la persona',
              helperText: _pointCount == null
                  ? 'Ejemplo: Dani, Papá, Club de pesca...'
                  : '$_pointCount puntos encontrados',
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _paste,
                  icon: const Icon(Icons.content_paste_outlined),
                  label: const Text('Pegar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _import,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(_saving ? 'Guardando...' : 'Importar'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

int _sharedColorFor(int index) {
  const colors = [
    0xFFB85C5C,
    0xFF4F7CAC,
    0xFFB07A2A,
    0xFF7D5BA6,
    0xFF2F8F83,
    0xFFC46A35,
  ];
  return colors[index % colors.length];
}

class _SharedLegendDot extends StatelessWidget {
  const _SharedLegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 18,
    height: 18,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    ),
  );
}

class _MapFiltersCard extends StatelessWidget {
  const _MapFiltersCard({
    required this.waterTypeFilter,
    required this.speciesFilter,
    required this.resultCount,
    required this.onWaterTypeChanged,
    required this.onSpeciesChanged,
    required this.onClear,
  });

  final String waterTypeFilter;
  final String speciesFilter;
  final int resultCount;
  final ValueChanged<String> onWaterTypeChanged;
  final ValueChanged<String> onSpeciesChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final availableSpecies = _speciesForWaterType(waterTypeFilter);
    final hasFilters = waterTypeFilter != 'all' || speciesFilter != 'all';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: _accentBrown),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$resultCount puntos visibles',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (hasFilters)
                  TextButton(onPressed: onClear, child: const Text('Limpiar')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('map-water-$waterTypeFilter'),
                    initialValue: waterTypeFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Agua'),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('Todas'),
                      ),
                      for (final waterType in spainWaterTypes)
                        DropdownMenuItem(
                          value: waterType.id,
                          child: Text(waterType.name),
                        ),
                    ],
                    onChanged: (value) => onWaterTypeChanged(value ?? 'all'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(
                      'map-species-$waterTypeFilter-$speciesFilter',
                    ),
                    initialValue: speciesFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Pez'),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('Todos'),
                      ),
                      for (final species in availableSpecies)
                        DropdownMenuItem(
                          value: species.id,
                          child: Text(species.commonName),
                        ),
                    ],
                    onChanged: (value) => onSpeciesChanged(value ?? 'all'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CatchDetailScreen extends StatefulWidget {
  const CatchDetailScreen({super.key, required this.entry});

  final FishingCatch entry;

  @override
  State<CatchDetailScreen> createState() => _CatchDetailScreenState();
}

class _CatchDetailScreenState extends State<CatchDetailScreen> {
  late FishingCatch entry;

  @override
  void initState() {
    super.initState();
    entry = widget.entry;
  }

  Future<void> _editCatch() async {
    final species = _speciesFor(entry);
    final waterType = _waterTypeFor(entry);
    if (species == null || waterType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo editar esta captura.')),
      );
      return;
    }
    final updated = await Navigator.of(context).push<FishingCatch>(
      MaterialPageRoute(
        builder: (_) => CatchFormScreen(
          waterType: waterType,
          species: species,
          existingCatch: entry,
        ),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => entry = updated);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar captura'),
        content: const Text(
          'Esta captura se borrará de tu biblioteca. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !context.mounted) return;
    try {
      final deletedRows = await CatchRepository.instance.deleteById(entry.id);
      try {
        await PhotoStorage.deleteIfExists(entry.photoPath);
      } catch (_) {
        // La captura ya se ha eliminado de la biblioteca; la foto no debe bloquearlo.
      }
      if (!context.mounted) return;
      if (deletedRows == 0) {
        Navigator.pop(context, entry.id);
        return;
      }
      Navigator.pop(context, entry.id);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la captura.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final species = _speciesFor(entry);
    final waterType = _waterTypeFor(entry);
    final dateText =
        '${MaterialLocalizations.of(context).formatFullDate(entry.caughtAt)} · ${TimeOfDay.fromDateTime(entry.caughtAt).format(context)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(species?.commonName ?? 'Detalle'),
        actions: [
          IconButton(
            tooltip: 'Editar captura',
            onPressed: _editCatch,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Eliminar captura',
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: _PaperSheet(
        child: ListView(
          padding: _pagePadding,
          children: [
            _DetailHeader(
              entry: entry,
              speciesName: species?.commonName ?? 'Especie desconocida',
              scientificName: species?.scientificName,
              waterTypeName: waterType?.name ?? 'Sin dato',
            ),
            const SizedBox(height: 12),
            _DetailPhotoCard(entry: entry),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DetailMetricCard(
                    icon: Icons.scale_outlined,
                    label: 'Peso',
                    value: entry.weightKg == null
                        ? 'Sin dato'
                        : '${_formatNumber(entry.weightKg!)} kg',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DetailMetricCard(
                    icon: Icons.straighten_outlined,
                    label: 'Longitud',
                    value: entry.lengthCm == null
                        ? 'Sin dato'
                        : '${_formatNumber(entry.lengthCm!)} cm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailSection(
              title: 'Dónde y cuándo',
              icon: Icons.place_outlined,
              children: [
                _DetailRow(
                  icon: Icons.place_outlined,
                  label: 'Lugar',
                  value: entry.locationName ?? 'Sin dato',
                ),
                _DetailRow(
                  icon: Icons.calendar_month_outlined,
                  label: 'Fecha y hora',
                  value: dateText,
                ),
                if (entry.latitude == null || entry.longitude == null)
                  const _DetailRow(
                    icon: Icons.my_location_outlined,
                    label: 'GPS',
                    value: 'Sin dato',
                    isLast: true,
                  )
                else
                  _MapDetail(
                    latitude: entry.latitude!,
                    longitude: entry.longitude!,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailSection(
              title: 'Cómo fue la pesca',
              icon: Icons.phishing_outlined,
              children: [
                _DetailRow(
                  icon: Icons.sports_handball_outlined,
                  label: 'Cebo o señuelo',
                  value: entry.baitOrLure ?? 'Sin dato',
                ),
                _DetailRow(
                  icon: Icons.phishing_outlined,
                  label: 'Técnica',
                  value: entry.technique ?? 'Sin dato',
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DetailSection(
              title: 'Notas del diario',
              icon: Icons.notes_outlined,
              children: [
                _NotebookNote(text: entry.notes ?? 'Sin notas adicionales.'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FullScreenPhoto extends StatelessWidget {
  const FullScreenPhoto({
    super.key,
    required this.path,
    required this.heroTag,
    this.title = 'Foto de la captura',
    this.subtitle,
  });

  final String path;
  final String heroTag;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Center(
                      child: Image.file(
                        File(path),
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) =>
                            const _PhotoError(isDark: true),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton.filledTonal(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _mapController = MapController();
  late LatLng _selectedPoint;
  double _zoom = 6;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedPoint = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      _zoom = 15;
    } else {
      _selectedPoint = const LatLng(40.4168, -3.7038);
      _zoom = 6;
    }
  }

  void _moveTo(double zoom) {
    setState(() => _zoom = zoom.clamp(3, 19).toDouble());
    _mapController.move(_selectedPoint, _zoom);
  }

  void _selectPoint(TapPosition _, LatLng point) {
    setState(() => _selectedPoint = point);
    _mapController.move(point, _zoom);
  }

  @override
  Widget build(BuildContext context) {
    final coordinateText =
        '${_formatCoordinate(_selectedPoint.latitude)}, '
        '${_formatCoordinate(_selectedPoint.longitude)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Elegir ubicación')),
      body: _PaperSheet(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(38, 14, 14, 150),
              child: _NotebookMapFrame(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedPoint,
                    initialZoom: _zoom,
                    interactionOptions: const InteractionOptions(
                      flags:
                          InteractiveFlag.drag |
                          InteractiveFlag.pinchZoom |
                          InteractiveFlag.doubleTapZoom |
                          InteractiveFlag.flingAnimation,
                    ),
                    onTap: _selectPoint,
                    onPositionChanged: (position, _) {
                      _zoom = position.zoom;
                    },
                  ),
                  children: _mapLayers(context, _selectedPoint, markerSize: 58),
                ),
              ),
            ),
            Positioned(
              left: 38,
              right: 14,
              bottom: 82,
              child: _MapControlCard(
                label: coordinateText,
                onZoomOut: () => _moveTo(_zoom - 1),
                onCenter: () => _mapController.move(_selectedPoint, _zoom),
                onZoomIn: () => _moveTo(_zoom + 1),
              ),
            ),
            Positioned(
              left: 38,
              right: 14,
              bottom: 22,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(_selectedPoint),
                icon: const Icon(Icons.check),
                label: const Text('Guardar esta ubicación'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.entry,
    required this.speciesName,
    required this.waterTypeName,
    this.scientificName,
  });

  final FishingCatch entry;
  final String speciesName;
  final String? scientificName;
  final String waterTypeName;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SpeciesIconAvatar(speciesId: entry.speciesId, radius: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  speciesName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (scientificName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    scientificName!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DetailTag(icon: Icons.water_outlined, text: waterTypeName),
                    _DetailTag(
                      icon: Icons.calendar_today_outlined,
                      text: MaterialLocalizations.of(context)
                          .formatMediumDate(entry.caughtAt),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _DetailPhotoCard extends StatelessWidget {
  const _DetailPhotoCard({required this.entry});

  final FishingCatch entry;

  @override
  Widget build(BuildContext context) {
    final photoPath = entry.photoPath;
    return Transform.rotate(
      angle: -0.015,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _paperCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _lineBrown),
          boxShadow: [
            BoxShadow(
              color: _accentBrown.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  if (photoPath == null)
                    const _NoPhotoPlaceholder()
                  else
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FullScreenPhoto(
                            path: photoPath,
                            heroTag: 'catch-photo-${entry.id}',
                            title:
                                _speciesFor(entry)?.commonName ??
                                'Foto de la captura',
                            subtitle:
                                [
                                      entry.locationName?.trim(),
                                      MaterialLocalizations.of(context)
                                          .formatShortDate(entry.caughtAt),
                                    ]
                                    .whereType<String>()
                                    .where((value) => value.isNotEmpty)
                                    .join(' · '),
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(photoPath),
                          width: double.infinity,
                          height: 260,
                          fit: BoxFit.cover,
                          cacheWidth: 1200,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) => const _PhotoError(),
                        ),
                      ),
                    ),
                  Positioned(
                    top: -10,
                    child: Transform.rotate(
                      angle: 0.06,
                      child: Container(
                        width: 82,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _stampPaper.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: _lineBrown.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (photoPath == null) ...[
                const SizedBox(height: 8),
                Text(
                  'Captura sin foto',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NoPhotoPlaceholder extends StatelessWidget {
  const _NoPhotoPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    height: 210,
    width: double.infinity,
    decoration: BoxDecoration(
      color: _paper,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _lineBrown),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.photo_camera_outlined,
          size: 58,
          color: _accentBrown.withValues(alpha: 0.72),
        ),
        const SizedBox(height: 10),
        Text(
          'Espacio para la foto',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    ),
  );
}

class _DetailMetricCard extends StatelessWidget {
  const _DetailMetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _accentBrown),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    ),
  );
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _accentBrown),
              const SizedBox(width: 10),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    ),
  );
}

class _DetailTag extends StatelessWidget {
  const _DetailTag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: _stampPaper.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: _lineBrown),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _accentBrown),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    ),
  );
}

class _NotebookNote extends StatelessWidget {
  const _NotebookNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _paper,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _lineBrown),
    ),
    child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MapDetail extends StatelessWidget {
  const _MapDetail({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    final coordinateText =
        '${_formatCoordinate(latitude)}, ${_formatCoordinate(longitude)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.map_outlined, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mapa', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FullScreenMap(
                        latitude: latitude,
                        longitude: longitude,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    height: 220,
                    child: _NotebookMapFrame(
                      child: AbsorbPointer(
                        child: _CaptureMap(point: point, initialZoom: 15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  coordinateText,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenMap extends StatefulWidget {
  const FullScreenMap({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  State<FullScreenMap> createState() => _FullScreenMapState();
}

class _FullScreenMapState extends State<FullScreenMap> {
  final _mapController = MapController();
  late final LatLng _point;
  double _zoom = 16;

  @override
  void initState() {
    super.initState();
    _point = LatLng(widget.latitude, widget.longitude);
  }

  void _moveTo(double zoom) {
    setState(() => _zoom = zoom.clamp(3, 19).toDouble());
    _mapController.move(_point, _zoom);
  }

  @override
  Widget build(BuildContext context) {
    final coordinateText =
        '${_formatCoordinate(widget.latitude)}, '
        '${_formatCoordinate(widget.longitude)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de la captura')),
      body: _PaperSheet(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(38, 14, 14, 110),
              child: _NotebookMapFrame(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _point,
                    initialZoom: _zoom,
                    interactionOptions: const InteractionOptions(
                      flags:
                          InteractiveFlag.drag |
                          InteractiveFlag.pinchZoom |
                          InteractiveFlag.doubleTapZoom |
                          InteractiveFlag.flingAnimation,
                    ),
                    onPositionChanged: (position, _) {
                      _zoom = position.zoom;
                    },
                  ),
                  children: _mapLayers(context, _point, markerSize: 58),
                ),
              ),
            ),
            Positioned(
              left: 38,
              right: 14,
              bottom: 22,
              child: _MapControlCard(
                label: coordinateText,
                onZoomOut: () => _moveTo(_zoom - 1),
                onCenter: () => _mapController.move(_point, _zoom),
                onZoomIn: () => _moveTo(_zoom + 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureMap extends StatelessWidget {
  const _CaptureMap({required this.point, required this.initialZoom});

  final LatLng point;
  final double initialZoom;

  @override
  Widget build(BuildContext context) => FlutterMap(
    options: MapOptions(
      initialCenter: point,
      initialZoom: initialZoom,
      interactionOptions: const InteractionOptions(
        flags:
            InteractiveFlag.drag |
            InteractiveFlag.pinchZoom |
            InteractiveFlag.doubleTapZoom,
      ),
    ),
    children: _mapLayers(context, point, markerSize: 48),
  );
}

class _NotebookMapFrame extends StatelessWidget {
  const _NotebookMapFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: _paperCard,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _lineBrown, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: _accentBrown.withValues(alpha: 0.18),
          blurRadius: 14,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            const IgnorePointer(child: _MapPaperTint()),
            Positioned(
              left: 10,
              top: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _paperCard.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _lineBrown),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Text('Mapa del diario'),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MapPaperTint extends StatelessWidget {
  const _MapPaperTint();

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _MapPaperTintPainter(),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: _paper.withValues(alpha: 0.10),
        backgroundBlendMode: BlendMode.screen,
      ),
    ),
  );
}

class _MapPaperTintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = _paperCard.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (double y = 34; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final marginPaint = Paint()
      ..color = _accentBrown.withValues(alpha: 0.18)
      ..strokeWidth = 1.1;
    canvas.drawLine(const Offset(28, 0), Offset(28, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CatchMapMarker extends StatelessWidget {
  const _CatchMapMarker({
    this.onTap,
    this.tooltip,
    this.color = _accentBrown,
    this.icon = Icons.set_meal_outlined,
  });

  final VoidCallback? onTap;
  final String? tooltip;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip ?? 'Captura',
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _stampPaper,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: _mapInk, size: 22),
          ),
          Positioned(
            bottom: 2,
            child: Icon(Icons.arrow_drop_down, color: color, size: 28),
          ),
        ],
      ),
    ),
  );
}

class _MapControlCard extends StatelessWidget {
  const _MapControlCard({
    required this.label,
    required this.onZoomOut,
    required this.onCenter,
    required this.onZoomIn,
  });

  final String label;
  final VoidCallback onZoomOut;
  final VoidCallback onCenter;
  final VoidCallback onZoomIn;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: _accentBrown),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          _MapRoundButton(
            tooltip: 'Alejar',
            icon: Icons.remove,
            onPressed: onZoomOut,
          ),
          const SizedBox(width: 4),
          _MapRoundButton(
            tooltip: 'Centrar',
            icon: Icons.my_location,
            onPressed: onCenter,
          ),
          const SizedBox(width: 4),
          _MapRoundButton(
            tooltip: 'Acercar',
            icon: Icons.add,
            onPressed: onZoomIn,
          ),
        ],
      ),
    ),
  );
}

class _MapRoundButton extends StatelessWidget {
  const _MapRoundButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon),
    style: IconButton.styleFrom(
      backgroundColor: _buttonBeige,
      foregroundColor: _ink,
      minimumSize: const Size(36, 36),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );
}

List<Widget> _mapLayers(
  BuildContext context,
  LatLng point, {
  required double markerSize,
}) => [
  _baseTileLayer(),
  MarkerLayer(
    markers: [
      Marker(
        point: point,
        width: markerSize,
        height: markerSize,
        child: const _CatchMapMarker(),
      ),
    ],
  ),
];

TileLayer _baseTileLayer() => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.pescatronik.pescatronik',
);

class _PhotoError extends StatelessWidget {
  const _PhotoError({this.isDark = false});

  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
    height: 220,
    alignment: Alignment.center,
    color: isDark
        ? Colors.black
        : Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Text(
      'No se pudo cargar la foto',
      style: TextStyle(color: isDark ? Colors.white : null),
    ),
  );
}

FishingSpecies? _speciesById(String speciesId) => spainWaterTypes
    .expand((waterType) => waterType.species)
    .where((species) => species.id == speciesId)
    .firstOrNull;

FishingSpecies? _speciesFor(FishingCatch entry) =>
    _speciesById(entry.speciesId);

WaterType? _waterTypeFor(FishingCatch entry) => spainWaterTypes
    .where((waterType) => waterType.id == entry.waterTypeId)
    .firstOrNull;

List<FishingSpecies> _speciesForWaterType(String waterTypeId) {
  if (waterTypeId == 'all') {
    return spainWaterTypes.expand((waterType) => waterType.species).toList();
  }
  return spainWaterTypes
          .where((waterType) => waterType.id == waterTypeId)
          .firstOrNull
          ?.species ??
      const [];
}

String _speciesNameById(String speciesId) =>
    spainWaterTypes
        .expand((waterType) => waterType.species)
        .where((species) => species.id == speciesId)
        .firstOrNull
        ?.commonName ??
    'Especie desconocida';

String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

String _formatCoordinate(double value) => value.toStringAsFixed(6);

class _CapturePhoto extends StatelessWidget {
  const _CapturePhoto({
    required this.path,
    required this.onRemove,
    this.onChange,
  });

  final String path;
  final VoidCallback onRemove;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(path),
          width: double.infinity,
          height: 220,
          fit: BoxFit.cover,
          cacheWidth: 1200,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const _PhotoError(),
        ),
      ),
      Positioned(
        top: 8,
        right: 8,
        child: IconButton.filledTonal(
          tooltip: 'Quitar foto',
          onPressed: onRemove,
          icon: const Icon(Icons.close),
        ),
      ),
      Positioned(
        bottom: 8,
        left: 8,
        child: FilledButton.icon(
          onPressed: onChange,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Cambiar foto'),
        ),
      ),
    ],
  );
}

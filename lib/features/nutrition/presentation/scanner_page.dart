import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/theme/halo_colors.dart';
import '../../../app/theme/halo_glass.dart';
import '../../../app/theme/halo_metrics.dart';

/// The camera, looking for a product barcode. Pops with the code.
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  static Route<String> route() => PageRouteBuilder<String>(
    opaque: true,
    fullscreenDialog: true,
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, _, _) => const ScannerPage(),
    transitionsBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController _camera = MobileScannerController(
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    final code = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (code == null) return;
    _done = true;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final window = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.42),
      width: size.width - 64,
      height: 180,
    );

    return CupertinoTheme(
      data: const CupertinoThemeData(brightness: Brightness.dark),
      child: ColoredBox(
        color: const Color(0xFF000000),
        child: Stack(
          children: [
            Positioned.fill(
              child: MobileScanner(
                controller: _camera,
                onDetect: _onDetect,
                errorBuilder: (context, error) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      error.errorCode == MobileScannerErrorCode.permissionDenied
                          ? 'Halo needs the camera to read barcodes. Allow it '
                                'in Settings.'
                          : 'The camera could not start.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Everything but the window darkened, the window outlined.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _Window(window)),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: window.bottom + 24,
              child: const Text(
                'Point the camera at a barcode',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Positioned(
              left: HaloMetrics.pagePadding,
              top: padding.top + 8,
              child: Builder(
                builder: (context) => GlassButton(
                  icon: const Icon(CupertinoIcons.xmark),
                  label: 'Close',
                  onTap: () => Navigator.of(context).pop(),
                  width: HaloMetrics.barButtonSize,
                  height: HaloMetrics.barButtonSize,
                  iconSize:
                      HaloMetrics.barButtonSize * HaloMetrics.barGlyphRatio,
                  iconColor: const Color(0xFFFFFFFF),
                  settings: HaloGlass.of(context),
                  quality: HaloGlass.quality,
                  useOwnLayer: true,
                ),
              ),
            ),
            Positioned(
              right: HaloMetrics.pagePadding,
              top: padding.top + 8,
              child: Builder(
                builder: (context) => GlassButton(
                  icon: const Icon(CupertinoIcons.bolt_fill),
                  label: 'Torch',
                  onTap: _camera.toggleTorch,
                  width: HaloMetrics.barButtonSize,
                  height: HaloMetrics.barButtonSize,
                  iconSize:
                      HaloMetrics.barButtonSize * HaloMetrics.barGlyphRatio,
                  iconColor: HaloColors.accent.darkColor,
                  settings: HaloGlass.of(context),
                  quality: HaloGlass.quality,
                  useOwnLayer: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Window extends CustomPainter {
  _Window(this.window);

  final Rect window;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = RRect.fromRectAndRadius(window, const Radius.circular(24));
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(hole),
      ),
      Paint()..color = const Color(0x99000000),
    );
    canvas.drawRRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFFFFFFF),
    );
  }

  @override
  bool shouldRepaint(_Window old) => old.window != window;
}

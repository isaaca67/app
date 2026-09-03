import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:stitch_cov_dark_mobile_login/core/theme/app_theme.dart';

/// Punto único de entrada al escáner nativo.
///
/// La comprobación se mantiene aquí, además de ocultar los botones en Web, para
/// impedir que una llamada accidental intente abrir la cámara desde el navegador.
Future<String?> openProductCodeScanner(BuildContext context) async {
  if (kIsWeb) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El escáner con cámara está disponible en la app móvil.'),
      ),
    );
    return null;
  }

  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => const ProductScannerScreen()),
  );
}

class ProductScannerScreen extends StatefulWidget {
  const ProductScannerScreen({super.key});

  @override
  State<ProductScannerScreen> createState() => _ProductScannerScreenState();
}

class _ProductScannerScreenState extends State<ProductScannerScreen> {
  late final MobileScannerController _controller;
  bool _captureHandled = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      formats: const [
        BarcodeFormat.qrCode,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.codabar,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.itf14,
      ],
    );
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_captureHandled) return;

    String? value;
    for (final barcode in capture.barcodes) {
      final candidate = barcode.rawValue?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        value = candidate;
        break;
      }
    }
    if (value == null) return;

    _captureHandled = true;
    await _controller.stop();
    if (mounted) Navigator.of(context).pop(value);
  }

  Future<void> _retry() async {
    _captureHandled = false;
    try {
      await _controller.stop();
    } catch (_) {
      // Puede no haber una cámara iniciada después de negar el permiso.
    }
    if (mounted) await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    // Defensa adicional para compilaciones Web o navegación programática.
    if (kIsWeb) {
      return const Scaffold(
        body: Center(child: Text('Escáner disponible solo en móvil.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear producto'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            fit: BoxFit.cover,
            tapToFocus: true,
            onDetect: _onDetect,
            errorBuilder: (_, error) =>
                _ScannerError(error: error, onRetry: _retry),
          ),
          const IgnorePointer(child: _ScannerOverlay()),
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: SafeArea(
              top: false,
              child: ValueListenableBuilder<MobileScannerState>(
                valueListenable: _controller,
                builder: (_, state, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CameraButton(
                      tooltip: 'Linterna',
                      icon: state.torchState == TorchState.on
                          ? Icons.flash_on
                          : Icons.flash_off,
                      onPressed: state.torchState == TorchState.unavailable
                          ? null
                          : _controller.toggleTorch,
                    ),
                    const SizedBox(width: 20),
                    _CameraButton(
                      tooltip: 'Cambiar cámara',
                      icon: Icons.cameraswitch_outlined,
                      onPressed: (state.availableCameras ?? 0) > 1
                          ? _controller.switchCamera
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Expanded(child: ColoredBox(color: Color(0x77000000))),
      Row(
        children: [
          const Expanded(child: ColoredBox(color: Color(0x77000000))),
          Container(
            width: 280,
            height: 190,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryColor, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const Expanded(child: ColoredBox(color: Color(0x77000000))),
        ],
      ),
      const Expanded(
        child: ColoredBox(
          color: Color(0x77000000),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text(
                'Alinea el código dentro del recuadro',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _CameraButton extends StatelessWidget {
  const _CameraButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filled(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon),
    style: IconButton.styleFrom(
      backgroundColor: Colors.black.withValues(alpha: 0.65),
      foregroundColor: Colors.white,
      disabledForegroundColor: Colors.white38,
      minimumSize: const Size(54, 54),
    ),
  );
}

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error, required this.onRetry});

  final MobileScannerException error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    final unsupported = error.errorCode == MobileScannerErrorCode.unsupported;
    final message = denied
        ? 'Necesitamos permiso para usar la cámara. Concédelo y vuelve a intentar.'
        : unsupported
        ? 'Este dispositivo no tiene una cámara compatible.'
        : 'No se pudo iniciar la cámara. Comprueba que no esté siendo usada por otra aplicación.';

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                denied
                    ? Icons.no_photography_outlined
                    : Icons.camera_alt_outlined,
                color: AppTheme.primaryColor,
                size: 64,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              if (!unsupported) ...[
                const SizedBox(height: 20),
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
}

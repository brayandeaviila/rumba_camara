import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../services/media_service.dart';
import 'theme.dart';

enum _CamState { loading, ready, denied, noCamera, error }

/// Cámara en vivo con el paquete `camera`.
///
/// Al hacer `initialize()` el sistema muestra el diálogo de permiso
/// (Android, iOS y navegador). Si el usuario lo niega, el plugin lanza una
/// `CameraException` con código `CameraAccessDenied...` y lo mostramos.
/// Al cerrar devuelve un [PickedPhoto] (o null si se cancela).
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _index = 0;
  _CamState _state = _CamState.loading;
  String _detail = '';
  bool _taking = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _controller?.dispose(); // libera la cámara siempre
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _state = _CamState.loading);
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _state = _CamState.noCamera);
        return;
      }
      // Preferimos la cámara trasera; si no hay, la primera disponible.
      final back =
          _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
      _index = back >= 0 ? back : 0;
      await _start(_cameras[_index]);
    } on CameraException catch (e) {
      _handle(e);
    } catch (e) {
      // Ej.: página sin HTTPS en Web (no existe navigator.mediaDevices).
      if (!mounted) return;
      setState(() {
        _state = _CamState.error;
        _detail = '$e';
      });
    }
  }

  Future<void> _start(CameraDescription description) async {
    final previous = _controller;
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false, // solo foto: así NO pedimos micrófono
    );
    _controller = controller;
    if (mounted) setState(() => _state = _CamState.loading);
    await previous?.dispose();
    try {
      await controller.initialize(); // <- aquí aparece el diálogo de permiso
      if (!mounted) return;
      setState(() => _state = _CamState.ready);
    } on CameraException catch (e) {
      _handle(e);
    }
  }

  void _handle(CameraException e) {
    if (!mounted) return;
    final denied =
        e.code.startsWith('CameraAccessDenied') || e.code == 'CameraAccessRestricted';
    setState(() {
      _state = denied ? _CamState.denied : _CamState.error;
      _detail = e.description ?? e.code;
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _index = (_index + 1) % _cameras.length;
    await _start(_cameras[_index]);
  }

  Future<void> _shoot() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _taking) return;
    setState(() => _taking = true);
    try {
      final XFile file = await c.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      Navigator.of(context).pop(PickedPhoto(bytes: bytes, name: file.name));
    } on CameraException catch (e) {
      _handle(e);
    } finally {
      if (mounted) setState(() => _taking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _body()),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (_state == _CamState.ready) _controls(),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    switch (_state) {
      case _CamState.loading:
        return const Center(child: CircularProgressIndicator(color: RumbaColors.red));
      case _CamState.ready:
        return Center(child: CameraPreview(_controller!));
      case _CamState.denied:
        return _Message(
          icon: Icons.no_photography_outlined,
          title: 'Permiso de cámara denegado',
          body: 'Rumba necesita la cámara para tomar la foto. '
              'Actívala en los ajustes del dispositivo o del sitio web '
              '(en Safari: botón "aA" → Ajustes del sitio web → Cámara) '
              'y vuelve a intentar.',
          onRetry: _init,
        );
      case _CamState.noCamera:
        return _Message(
          icon: Icons.videocam_off_outlined,
          title: 'No se encontró ninguna cámara',
          body: 'Prueba elegir una foto de la galería.',
          onRetry: _init,
        );
      case _CamState.error:
        return _Message(
          icon: Icons.error_outline,
          title: 'No se pudo abrir la cámara',
          body: _detail,
          onRetry: _init,
        );
    }
  }

  Widget _controls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const SizedBox(width: 48),
          GestureDetector(
            onTap: _shoot,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _taking ? RumbaColors.dim : Colors.white,
                border: Border.all(color: Colors.white54, width: 4),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: _cameras.length > 1
                ? IconButton(
                    icon: const Icon(Icons.cameraswitch_outlined, color: Colors.white),
                    onPressed: _switchCamera,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onRetry;

  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: RumbaColors.dim),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: const TextStyle(color: RumbaColors.dim, height: 1.4)),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

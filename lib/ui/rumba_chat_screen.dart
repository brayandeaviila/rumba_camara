import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;

import '../models/chat_message.dart';
import '../services/media_service.dart';
import 'camera_capture_screen.dart';
import 'theme.dart';

enum _AttachAction { liveCamera, gallery, systemCamera }

/// Chat de una Rumba (réplica del prototipo HTML) con el botón de adjuntar
/// conectado a Cámara y Galería.
class RumbaChatScreen extends StatefulWidget {
  const RumbaChatScreen({super.key});

  @override
  State<RumbaChatScreen> createState() => _RumbaChatScreenState();
}

class _RumbaChatScreenState extends State<RumbaChatScreen> {
  final _media = MediaService();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  final List<ChatMessage> _messages = [
    const ChatMessage(
      sender: MessageSender.them,
      time: '10:02 a. m.',
      text: 'Quiubo! vi que ofreces ese servicio, ¿tienes tiempo esta semana?',
    ),
    const ChatMessage(
      sender: MessageSender.me,
      time: '10:04 a. m.',
      text: 'Buenas, estoy interesado en un beat de afro. Te paso una foto de la referencia',
    ),
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _now() => TimeOfDay.now().format(context);

  void _add(ChatMessage m) {
    setState(() => _messages.add(m));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendText() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _add(ChatMessage(sender: MessageSender.me, time: _now(), text: text));
    _input.clear();
    setState(() {});
  }

  void _addPhoto(PickedPhoto photo) {
    if (!mounted) return;
    _add(ChatMessage(
      sender: MessageSender.me,
      time: _now(),
      imageBytes: photo.bytes,
      imageName: photo.name,
    ));
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------- Adjuntar ----------

  Future<void> _openAttachSheet() async {
    final action = await showModalBottomSheet<_AttachAction>(
      context: context,
      backgroundColor: RumbaColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => const SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            _SheetTile(
              icon: Icons.photo_camera_outlined,
              title: 'Tomar foto',
              subtitle: 'Cámara en vivo · paquete camera',
              action: _AttachAction.liveCamera,
            ),
            _SheetTile(
              icon: Icons.photo_library_outlined,
              title: 'Elegir de la galería',
              subtitle: 'Selector del sistema · image_picker',
              action: _AttachAction.gallery,
            ),
            _SheetTile(
              icon: Icons.camera_alt_outlined,
              title: 'Cámara del sistema',
              subtitle: 'App de cámara nativa · image_picker',
              action: _AttachAction.systemCamera,
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _AttachAction.liveCamera:
        final photo = await Navigator.of(context).push<PickedPhoto>(
          MaterialPageRoute(
            builder: (_) => const CameraCaptureScreen(),
            fullscreenDialog: true,
          ),
        );
        if (photo != null) _addPhoto(photo);
      case _AttachAction.gallery:
        await _pick(_media.fromGallery);
      case _AttachAction.systemCamera:
        await _pick(_media.fromSystemCamera);
    }
  }

  Future<void> _pick(Future<PickedPhoto?> Function() source) async {
    try {
      final photo = await source();
      if (photo != null) _addPhoto(photo);
    } on PlatformException catch (e) {
      // image_picker usa códigos como camera_access_denied (iOS).
      final denied = e.code.contains('denied') || e.code.contains('restricted');
      _snack(denied
          ? 'Permiso denegado. Actívalo en Ajustes para adjuntar fotos.'
          : 'No se pudo abrir: ${e.message ?? e.code}');
    } catch (e) {
      _snack('No se pudo adjuntar la foto: $e');
    }
  }

  void _openViewer(ChatMessage m) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: InteractiveViewer(
          child: Center(child: Image.memory(m.imageBytes!)),
        ),
      ),
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _Bubble(
                  message: _messages[i],
                  onImageTap: () => _openViewer(_messages[i]),
                ),
              ),
            ),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _composer() {
    final hasText = _input.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: RumbaColors.bg,
        border: Border(top: BorderSide(color: RumbaColors.border)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Adjuntar',
            icon: const Icon(Icons.attach_file, color: RumbaColors.dim),
            onPressed: _openAttachSheet,
          ),
          Expanded(
            child: TextField(
              controller: _input,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _sendText(),
              decoration: InputDecoration(
                hintText: 'Escribe un mensaje…',
                filled: true,
                fillColor: RumbaColors.card2,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: hasText ? RumbaColors.red : RumbaColors.card2,
            ),
            icon: const Icon(Icons.send, size: 18),
            onPressed: hasText ? _sendText : null,
          ),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final _AttachAction action;

  const _SheetTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: RumbaColors.text),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: RumbaColors.dim)),
      onTap: () => Navigator.of(context).pop(action),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: RumbaColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.chevron_left, color: RumbaColors.text),
          const CircleAvatar(
            radius: 16,
            backgroundColor: RumbaColors.card2,
            child: Text('C', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chide', style: TextStyle(fontWeight: FontWeight.w700)),
                Text('Rumba #2 · Producción musical',
                    style: TextStyle(fontSize: 12, color: RumbaColors.dim)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: RumbaColors.card2,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Solicitada',
                style: TextStyle(fontSize: 11, color: RumbaColors.dim)),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onImageTap;

  const _Bubble({required this.message, required this.onImageTap});

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            crossAxisAlignment:
                mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.isImage)
                GestureDetector(
                  onTap: onImageTap,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      message.imageBytes!,
                      width: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: mine ? RumbaColors.redDim : RumbaColors.card2,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(message.text ?? '',
                      style: const TextStyle(fontSize: 14, height: 1.35)),
                ),
              const SizedBox(height: 3),
              Text(message.time,
                  style: const TextStyle(fontSize: 10.5, color: RumbaColors.faint)),
            ],
          ),
        ),
      ),
    );
  }
}

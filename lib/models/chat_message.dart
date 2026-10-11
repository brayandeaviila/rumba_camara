import 'dart:typed_data';

// Dominio puro: sin imports de Flutter (solo dart:typed_data).

enum MessageSender { me, them }

class ChatMessage {
  final MessageSender sender;
  final String time;
  final String? text;

  /// Bytes de la foto adjunta. Usamos bytes (y no una ruta de archivo)
  /// porque en Web no existe `File`: así el mismo código sirve en
  /// Android, iOS y Web.
  final Uint8List? imageBytes;
  final String? imageName;

  const ChatMessage({
    required this.sender,
    required this.time,
    this.text,
    this.imageBytes,
    this.imageName,
  });

  bool get isImage => imageBytes != null;
  bool get isMine => sender == MessageSender.me;
}

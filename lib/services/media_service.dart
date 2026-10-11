import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Foto ya leída en memoria, lista para mostrarse o subirse.
class PickedPhoto {
  final Uint8List bytes;
  final String name;
  const PickedPhoto({required this.bytes, required this.name});
}

/// Envuelve `image_picker` (galería y cámara del sistema).
///
/// Galería: en Android usa el Photo Picker y en iOS el PHPicker; ambos son
/// selectores del sistema, por eso NO piden permiso para elegir una foto.
/// Cámara del sistema: sí requiere permiso de cámara (lo pide el SO).
/// Web: abre un <input type="file"> (con `capture` para la cámara).
class MediaService {
  final ImagePicker _picker = ImagePicker();

  Future<PickedPhoto?> fromGallery() => _pick(ImageSource.gallery);

  Future<PickedPhoto?> fromSystemCamera() => _pick(ImageSource.camera);

  Future<PickedPhoto?> _pick(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      maxWidth: 1600, // reduce el peso de fotos de 12 MP
      imageQuality: 85,
    );
    if (file == null) return null; // el usuario canceló: no es un error
    return PickedPhoto(bytes: await file.readAsBytes(), name: file.name);
  }
}

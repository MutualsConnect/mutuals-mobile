import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Elige una foto de la galería y devuelve la ruta del archivo, o `null` si se
/// cancela. Es una interfaz para poder simularla en pruebas.
abstract interface class PhotoPicker {
  /// Elige una foto de la galería.
  Future<String?> pick();

  /// Abre la cámara y devuelve la foto tomada. Lanza una excepción si no hay cámara
  /// (por ejemplo en el simulador), para que la pantalla ofrezca la galería.
  Future<String?> takePhoto();
}

class GalleryPhotoPicker implements PhotoPicker {
  @override
  Future<String?> takePhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 85,
    );
    return file?.path;
  }

  @override
  Future<String?> pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    return file?.path;
  }
}

final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => GalleryPhotoPicker(),
);

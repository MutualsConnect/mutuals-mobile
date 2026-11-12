import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Elige una foto de la galería y devuelve la ruta del archivo, o `null` si se
/// cancela. Es una interfaz para poder simularla en pruebas.
abstract interface class PhotoPicker {
  Future<String?> pick();
}

class GalleryPhotoPicker implements PhotoPicker {
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

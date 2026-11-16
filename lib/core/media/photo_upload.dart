import 'package:dio/dio.dart';

/// Tipo de contenido de una foto según su extensión. El backend solo acepta
/// JPEG, PNG o WEBP y rechaza lo que llegue como `application/octet-stream`.
String imageMimeType(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}

/// Parte de un formulario multipart con la foto y su tipo de contenido correcto.
Future<MultipartFile> photoPart(String path) async {
  final mime = imageMimeType(path).split('/');
  final name = path.split('/').last;
  return MultipartFile.fromFile(
    path,
    filename: name,
    contentType: DioMediaType(mime[0], mime[1]),
  );
}

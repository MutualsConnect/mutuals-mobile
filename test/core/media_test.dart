import 'package:flutter_test/flutter_test.dart';
import 'package:mutuals/core/media/photo_upload.dart';
import 'package:mutuals/core/network/api_config.dart';

void main() {
  group('ApiConfig.mediaUrl', () {
    const api = 'http://localhost:8080/api/v1';

    test('convierte la ruta que devuelve la API en una dirección completa', () {
      expect(
        ApiConfig.mediaUrl('/uploads/moments/a.png', apiBaseUrl: api),
        'http://localhost:8080/uploads/moments/a.png',
      );
    });

    test('respeta el puerto y el servidor configurados', () {
      expect(
        ApiConfig.mediaUrl(
          '/uploads/x.jpg',
          apiBaseUrl: 'https://mutuals.example.com/api/v1',
        ),
        'https://mutuals.example.com/uploads/x.jpg',
      );
    });

    test(
      'agrega la barra inicial si falta y no toca las direcciones completas',
      () {
        expect(
          ApiConfig.mediaUrl('uploads/x.jpg', apiBaseUrl: api),
          'http://localhost:8080/uploads/x.jpg',
        );
        expect(
          ApiConfig.mediaUrl('https://cdn.example.com/a.png', apiBaseUrl: api),
          'https://cdn.example.com/a.png',
        );
      },
    );
  });

  group('imageMimeType', () {
    test('reconoce JPEG, PNG y WEBP sin importar mayúsculas', () {
      expect(imageMimeType('/tmp/a.jpg'), 'image/jpeg');
      expect(imageMimeType('/tmp/a.JPEG'), 'image/jpeg');
      expect(imageMimeType('/tmp/a.png'), 'image/png');
      expect(imageMimeType('/tmp/A.PNG'), 'image/png');
      expect(imageMimeType('/tmp/a.webp'), 'image/webp');
    });

    test('lo desconocido se envía como JPEG, el formato de la cámara', () {
      expect(imageMimeType('/tmp/foto'), 'image/jpeg');
    });
  });
}

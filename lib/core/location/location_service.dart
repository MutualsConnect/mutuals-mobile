import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef Coordinates = ({double latitude, double longitude});

/// Obtiene la ubicación actual. Es una interfaz para poder simularla en pruebas.
abstract interface class LocationService {
  Future<Coordinates> current();
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<Coordinates> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
        'Activa la ubicación de tu teléfono para continuar.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Necesitamos tu permiso de ubicación para comprobar que están juntos.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'El permiso de ubicación está bloqueado. Actívalo en los Ajustes del teléfono.',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return (latitude: position.latitude, longitude: position.longitude);
  }
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => GeolocatorLocationService(),
);

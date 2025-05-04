import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/shared/services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
}); 
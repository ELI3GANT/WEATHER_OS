typedef LocationResult = ({double latitude, double longitude, String locationName});

abstract interface class LocationService {
  Future<LocationResult?> getCurrentLocation();
}

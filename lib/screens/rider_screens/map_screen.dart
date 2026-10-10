import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

class MapScreen extends StatefulWidget {
  final bool isSelectingStart;
  final LatLng? startCoordinates;
  final LatLng? endCoordinates;

  const MapScreen({
    Key? key,
    required this.isSelectingStart,
    this.startCoordinates,
    this.endCoordinates,
  }) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final Location _locationService = Location();
  
  LatLng? selectedLocation;
  List<LatLng> _routePoints = [];
  List<Marker> _markers = [];
  bool _isLoading = false;
  String? locationName;
  double _distanceInKm = 0.0;
  LatLng? _startLocation;
  LatLng? _endLocation;
  String? _startAddress;
  String? _endAddress;

  // Color palette matching the rest of the app
  static const Color kPrimaryColor = Color(0xFF1E3A8A);    // Deep navy
  static const Color kTextColor = Color(0xFF0F172A);       // Dark navy
  static const Color kDangerColor = Color.fromARGB(255, 139, 56, 56);     // Bright red
  static const Color kAccentColor = Color(0xFF3B82F6);     // Bright blue

  // Sayoun coordinates (15.9430, 48.7873)
  static const LatLng _sayounCenter = LatLng(15.9430, 48.7873);
  
  // IMPORTANT: In production, don't hardcode API keys. Use backend services or secure storage.
  // ignore: unused_field
  final String _orsApiKey = '5b3ce3597851110001cf6248ed0d5801c81b43e9bc3cf4f8ea98cc6f';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    
    // If both start and end coordinates are provided, show them on the map
    if (widget.startCoordinates != null && widget.endCoordinates != null) {
      _addStartEndMarkers(widget.startCoordinates!, widget.endCoordinates!);
      _calculateDistance(widget.startCoordinates!, widget.endCoordinates!);
    } else if (widget.isSelectingStart && widget.startCoordinates != null) {
      _updateSelectedLocation(widget.startCoordinates!);
    } else if (!widget.isSelectingStart && widget.endCoordinates != null) {
      _updateSelectedLocation(widget.endCoordinates!);
    }
  }

  Future<void> _initializeLocation() async {
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        _showLocationServiceError();
        return;
      }
    }

    PermissionStatus permission = await _locationService.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _locationService.requestPermission();
      if (permission != PermissionStatus.granted) {
        _showLocationPermissionError();
        return;
      }
    }

    _locationService.onLocationChanged.listen((LocationData currentLocation) {
      if (selectedLocation == null && mounted) {
        _updateSelectedLocation(LatLng(
          currentLocation.latitude ?? _sayounCenter.latitude,
          currentLocation.longitude ?? _sayounCenter.longitude,
        ));
      }
    });
  }

  void _showLocationServiceError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Location services are disabled. Please enable them.',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: kDangerColor,
      )
    );
  }

  void _showLocationPermissionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Location permissions are required for this app to work properly.',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: kDangerColor,
      )
    );
  }

  Future<void> _updateSelectedLocation(LatLng point) async {
    setState(() => _isLoading = true);
    
    final address = await _reverseGeocode(point);
    if (!mounted) return;
    
    setState(() {
      selectedLocation = point;
      locationName = address;
      _markers = [_createMarker(point, Icons.location_on, kPrimaryColor)];
      _mapController.move(point, 14.0);
      _isLoading = false;
    });
  }

  Future<String> _reverseGeocode(LatLng point) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?'
          'format=json&lat=${point.latitude}&lon=${point.longitude}',
        ),
        headers: {'User-Agent': 'SayounNavigationApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ?? _formatCoordinates(point);
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
    return _formatCoordinates(point);
  }

  String _formatCoordinates(LatLng point) {
    return '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
  }

  Marker _createMarker(LatLng point, IconData icon, Color color) {
    return Marker(
      width: 50,
      height: 50,
      point: point,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }

  void _addStartEndMarkers(LatLng start, LatLng end) {
    setState(() {
      _markers = [
        _createMarker(start, Icons.location_on, kPrimaryColor),
        _createMarker(end, Icons.flag, kDangerColor),
      ];
      _routePoints = [start, end];
    });
  }

  void _calculateDistance(LatLng start, LatLng end) {
    const Distance distance = Distance();
    double distanceInMeters = distance.as(
      LengthUnit.Kilometer,
      start,
      end,
    );
    setState(() {
      _distanceInKm = distanceInMeters;
    });
  }

  Future<String> _getAddressFromLatLng(LatLng position) async {
    try {
      final response = await http.get(Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1'
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          return displayName;
        }
      }
      return widget.isSelectingStart ? 'موقع البداية' : 'موقع الوصول';
    } catch (e) {
      print('Error getting address: $e');
      return widget.isSelectingStart ? 'موقع البداية' : 'موقع الوصول';
    }
  }

  void _handleMapTap(LatLng position) async {
    setState(() {
      if (widget.isSelectingStart) {
        _startLocation = position;
        _endLocation = null; // Reset end location when start is selected
      } else {
        _endLocation = position;
      }
    });

    // Get address for the selected location
    try {
      final address = await _getAddressFromLatLng(position);
      setState(() {
        if (widget.isSelectingStart) {
          _startAddress = address;
        } else {
          _endAddress = address;
        }
      });
    } catch (e) {
      print('Error getting address: $e');
    }

    // Calculate distance if both locations are set
    if (_startLocation != null && _endLocation != null) {
      final distance = _calculateDistanceBetweenPoints(_startLocation!, _endLocation!);
      setState(() {
        _distanceInKm = distance;
        // Add markers for both locations
        _markers = [
          _createMarker(_startLocation!, Icons.location_on, kPrimaryColor),
          _createMarker(_endLocation!, Icons.flag, kDangerColor),
        ];
        // Add route points
        _routePoints = [_startLocation!, _endLocation!];
      });
    } else if (widget.isSelectingStart) {
      // If only start location is set
      setState(() {
        _markers = [_createMarker(_startLocation!, Icons.location_on, kPrimaryColor)];
        _routePoints = [];
      });
    } else {
      // If only end location is set
      setState(() {
        _markers = [_createMarker(_endLocation!, Icons.flag, kDangerColor)];
        _routePoints = [];
      });
    }
  }

  double _calculateDistanceBetweenPoints(LatLng start, LatLng end) {
    const double earthRadius = 6371; // in kilometers
    double dLat = _degreesToRadians(end.latitude - start.latitude);
    double dLng = _degreesToRadians(end.longitude - start.longitude);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(start.latitude)) * math.cos(_degreesToRadians(end.latitude)) *
               math.sin(dLng / 2) * math.sin(dLng / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  void _confirmLocation() {
    if (widget.isSelectingStart && _startLocation != null) {
      Navigator.pop(context, {
        'location': _startAddress ?? 'موقع البداية',
        'coordinates': '${_startLocation!.latitude},${_startLocation!.longitude}',
        'distance': _distanceInKm,
      });
    } else if (!widget.isSelectingStart && _endLocation != null) {
      Navigator.pop(context, {
        'location': _endAddress ?? 'موقع الوصول',
        'coordinates': '${_endLocation!.latitude},${_endLocation!.longitude}',
        'distance': _distanceInKm,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            widget.isSelectingStart ? 'حدد موقع البداية' : 'حدد موقع الوصول',
            style: const TextStyle(
              color: kTextColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward, color: kPrimaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: Colors.grey.withOpacity(0.1),
            ),
          ),
        ),
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _sayounCenter,
                initialZoom: 14.0,
                onTap: (_, point) => _handleMapTap(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(markers: _markers),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: kAccentColor.withOpacity(0.7),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              ],
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: kPrimaryColor,
                ),
              ),
            if (locationName != null && selectedLocation != null)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        locationName!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                          fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Tajawal',
                        ),
                      ),
                      if (_distanceInKm > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          'المسافة: ${_distanceInKm.toStringAsFixed(1)} كم',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: kAccentColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: selectedLocation != null
                    ? () {
                        _confirmLocation();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.isSelectingStart ? 'تأكيد موقع البداية' : 'تأكيد موقع الوصول',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _mapController.move(_sayounCenter, 14),
          tooltip: 'Center on Sayoun',
          backgroundColor: kPrimaryColor,
          child: const Icon(Icons.center_focus_strong, color: Colors.white),
        ),
      ),
    );
  }
}
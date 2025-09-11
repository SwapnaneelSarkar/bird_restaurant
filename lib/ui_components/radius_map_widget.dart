import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../presentation/resources/colors.dart';
import '../presentation/resources/font.dart';

class RadiusMapWidget extends StatefulWidget {
  final double initialRadius;
  final double initialLatitude;
  final double initialLongitude;
  final Function(double radius, double latitude, double longitude) onRadiusChanged;

  const RadiusMapWidget({
    Key? key,
    required this.initialRadius,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.onRadiusChanged,
  }) : super(key: key);

  @override
  State<RadiusMapWidget> createState() => _RadiusMapWidgetState();
}

class _RadiusMapWidgetState extends State<RadiusMapWidget> {
  late GoogleMapController _mapController;
  late double _currentRadius;
  late double _currentLatitude;
  late double _currentLongitude;
  Set<Circle> _circles = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _currentRadius = widget.initialRadius;
    _currentLatitude = widget.initialLatitude;
    _currentLongitude = widget.initialLongitude;
    _updateMapElements();
  }

  void _updateMapElements() {
    setState(() {
      _circles = {
        Circle(
          circleId: const CircleId('delivery_radius'),
          center: LatLng(_currentLatitude, _currentLongitude),
          radius: _currentRadius * 1000, // Convert km to meters
          fillColor: ColorManager.primary.withOpacity(0.2),
          strokeColor: ColorManager.primary,
          strokeWidth: 2,
        ),
      };

      _markers = {
        Marker(
          markerId: const MarkerId('restaurant_location'),
          position: LatLng(_currentLatitude, _currentLongitude),
          infoWindow: const InfoWindow(
            title: 'Restaurant Location',
            snippet: 'Your restaurant location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraMove(CameraPosition position) {
    _currentLatitude = position.target.latitude;
    _currentLongitude = position.target.longitude;
    _updateMapElements();
    widget.onRadiusChanged(_currentRadius, _currentLatitude, _currentLongitude);
  }

  void _onRadiusChanged(double newRadius) {
    setState(() {
      _currentRadius = newRadius;
    });
    _updateMapElements();
    widget.onRadiusChanged(_currentRadius, _currentLatitude, _currentLongitude);
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
      });
      
      _updateMapElements();
      
      _mapController.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentLatitude, _currentLongitude),
        ),
      );
      
      widget.onRadiusChanged(_currentRadius, _currentLatitude, _currentLongitude);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(_currentLatitude, _currentLongitude),
                zoom: 12.0,
              ),
              onCameraMove: _onCameraMove,
              circles: _circles,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
            
            // Current location button
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: _getCurrentLocation,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.my_location,
                  color: ColorManager.primary,
                ),
              ),
            ),
            
            // Radius control
            Positioned(
              bottom: 16,
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
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.radio_button_checked,
                          color: ColorManager.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Delivery Radius: ${_currentRadius.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontFamily: FontConstants.fontFamily,
                            fontSize: FontSize.s14,
                            fontWeight: FontWeightManager.medium,
                            color: ColorManager.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: _currentRadius,
                      min: 1.0,
                      max: 50.0,
                      divisions: 49,
                      activeColor: ColorManager.primary,
                      inactiveColor: Colors.grey.shade300,
                      onChanged: _onRadiusChanged,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '1 km',
                          style: TextStyle(
                            fontSize: FontSize.s12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '50 km',
                          style: TextStyle(
                            fontSize: FontSize.s12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

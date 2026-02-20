import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPickerScreen extends StatefulWidget {
  // 1. Idagdag ang callback function na ito
  final Function(LatLng) onLocationSelected;

  const MapPickerScreen({super.key, required this.onLocationSelected});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _selectedLocation;

  // Default camera position sa Manila City Hall area
  static const LatLng _initialPosition = LatLng(14.5895, 120.9815);

  void _onTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("Select Delivery Location"),
      ),
      child: Stack(
        children: [
          // MAPA
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _initialPosition,
              zoom: 15,
            ),
            onTap: _onTap,
            markers: _selectedLocation != null
                ? {
              Marker(
                markerId: const MarkerId("target"),
                position: _selectedLocation!,
              ),
            }
                : {},
          ),

          // OVERLAY INSTRUCTION & BUTTON
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _selectedLocation == null
                        ? null
                        : () {
                      // 2. TATAWAGIN ANG CALLBACK AT MAGPO-POP
                      widget.onLocationSelected(_selectedLocation!);
                      Navigator.pop(context);
                    },
                    child: const Text("Confirm Destination"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
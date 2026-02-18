import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'OrderTrackingScreen.dart'; // Siguraduhing tama ang filename ng tracking screen mo

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

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
                Container(
                  padding: const EdgeInsets.all(10),
                  color: CupertinoColors.white.withOpacity(0.8),
                  child: const Text(
                    "Tap on the map to set your pin",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 15),
                CupertinoButton.filled(
                  onPressed: _selectedLocation == null
                      ? null
                      : () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => OrderTrackingScreen(
                          destination: _selectedLocation!,
                          orderName: "Track your Rider",
                        ),
                      ),
                    );
                  },
                  child: const Text("Confirm Destination"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
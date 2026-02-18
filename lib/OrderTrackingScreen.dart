import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class OrderTrackingScreen extends StatefulWidget {
  final LatLng destination;
  final String orderName;

  const OrderTrackingScreen({super.key, required this.destination, required this.orderName});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  GoogleMapController? _controller;
  List<LatLng> polylineCoordinates = [];
  Marker? riderMarker;
  String deliveryStatus = "Order Confirmed";

  @override
  void initState() {
    super.initState();
    // 3 seconds delay bago lumabas ang ruta at rider
    Timer(const Duration(seconds: 60), () {
      if (mounted) {
        setState(() => deliveryStatus = "Rider is picking up your order...");
        _getOSRMRoute();
      }
    });
  }

  // ITO ANG ATING LIBRENG ROUTING ENGINE
  Future<void> _getOSRMRoute() async {
    // Kunwari ang rider ay nagsimula sa layong ~1km (Para may dadaanan siyang highway)
    LatLng startLocation = LatLng(
        widget.destination.latitude + 0.008,
        widget.destination.longitude + 0.008
    );

    final url = 'https://router.project-osrm.org/route/v1/driving/'
        '${startLocation.longitude},${startLocation.latitude};'
        '${widget.destination.longitude},${widget.destination.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List coords = data['routes'][0]['geometry']['coordinates'];

        setState(() {
          deliveryStatus = "Delivery is on the way";
          // Baligtarin ang [Long, Lat] papuntang [Lat, Long]
          polylineCoordinates = coords
              .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
              .toList();
        });

        _startRiderSimulation();
      }
    } catch (e) {
      debugPrint("OSRM Error: $e");
    }
  }

  void _startRiderSimulation() {
    int currentStep = 0;
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (currentStep < polylineCoordinates.length) {
        if (mounted) {
          setState(() {
            riderMarker = Marker(
              markerId: const MarkerId("rider"),
              position: polylineCoordinates[currentStep],
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            );
          });

          _controller?.animateCamera(
            CameraUpdate.newLatLng(polylineCoordinates[currentStep]),
          );
        }
        currentStep++;
      } else {
        if (mounted) {
          setState(() => deliveryStatus = "Rider has Arrived!");
        }
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(widget.orderName)),
      child: SafeArea(
        child: Column(
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: CupertinoColors.activeBlue.withOpacity(0.1),
              child: Text(deliveryStatus, textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: CupertinoColors.activeBlue)),
            ),
            // The Map
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: widget.destination, zoom: 15),
                onMapCreated: (ctrl) => _controller = ctrl,
                myLocationEnabled: false, // Iwas crash sa emulator
                polylines: {
                  Polyline(
                    polylineId: const PolylineId("route"),
                    points: polylineCoordinates,
                    color: CupertinoColors.activeBlue,
                    width: 5,
                  ),
                },
                markers: {
                  Marker(markerId: const MarkerId("user"), position: widget.destination),
                  if (riderMarker != null) riderMarker!,
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui; // Import para sa resizing
import 'package:flutter/services.dart'; // Import para sa rootBundle
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
  BitmapDescriptor? riderIcon;

  Timer? _initialTimer;
  Timer? _simulationTimer;

  @override
  void initState() {
    super.initState();
    _setCustomMarkerIcon();

    deliveryStatus = "Order Confirmed";

    _initialTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => deliveryStatus = "Rider is picking up your order...");
        _getOSRMRoute();
      }
    });
  }

  @override
  void dispose() {
    _initialTimer?.cancel();
    _simulationTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // --- BAGONG HELPER FUNCTION PARA SA PAG-ADJUST NG SIZE ---
  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    // Naglo-load ng image file mula sa assets
    ByteData data = await rootBundle.load(path);

    // Nire-resize ang image gamit ang targetWidth
    ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: width
    );

    ui.FrameInfo fi = await codec.getNextFrame();

    // ITO ANG FIX: buffer.asUint8List() ang tamang syntax
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }
  void _setCustomMarkerIcon() async {
    try {
      // Palitan ang '120' sa size na gusto mo (e.g., 100, 150, 200)
      final Uint8List markerIcon = await getBytesFromAsset('assets/icon.png', 120);

      setState(() {
        riderIcon = BitmapDescriptor.fromBytes(markerIcon);
      });
    } catch (e) {
      debugPrint("Error resizing icon: $e");
    }
  }

  Future<void> _getOSRMRoute() async {
    LatLng startLocation = LatLng(
        widget.destination.latitude + 0.005,
        widget.destination.longitude + 0.005
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

        if (mounted) {
          setState(() {
            deliveryStatus = "Rider is on the way...";
            polylineCoordinates = coords
                .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
                .toList();
          });
          _startRiderSimulation();
        }
      }
    } catch (e) {
      debugPrint("OSRM Error: $e");
    }
  }

  void _startRiderSimulation() {
    int currentStep = 0;
    _simulationTimer?.cancel();

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (currentStep < polylineCoordinates.length) {
        if (mounted) {
          setState(() {
            riderMarker = Marker(
              markerId: const MarkerId("rider"),
              position: polylineCoordinates[currentStep],
              icon: riderIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              anchor: const Offset(0.5, 0.5),
              infoWindow: const InfoWindow(title: "Rider is delivering..."),
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
          timer.cancel();

          Future.delayed(const Duration(seconds: 4), () {
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.orderName),
        automaticallyImplyLeading: false,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: CupertinoColors.systemPink.withOpacity(0.1),
                  border: const Border(bottom: BorderSide(color: CupertinoColors.systemPink, width: 0.5))
              ),
              child: Text(
                deliveryStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFD70F64)),
              ),
            ),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: widget.destination, zoom: 15),
                onMapCreated: (ctrl) => _controller = ctrl,
                polylines: {
                  Polyline(
                    polylineId: const PolylineId("route"),
                    points: polylineCoordinates,
                    color: const Color(0xFFD70F64),
                    width: 6,
                  ),
                },
                markers: {
                  Marker(
                      markerId: const MarkerId("user"),
                      position: widget.destination,
                      infoWindow: const InfoWindow(title: "Delivery Point")
                  ),
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
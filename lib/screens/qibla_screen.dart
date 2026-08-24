import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

// Kaaba coordinates
const double _kaabaLat = 21.4225;
const double _kaabaLng = 39.8262;

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});
  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  double? _qiblaBearing;
  String? _error;
  StreamSubscription<CompassEvent>? _sub;
  double _heading = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _error = 'Location permission is required to compute Qibla direction.');
      return;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() => _error = 'Enable location services to compute Qibla direction.');
      return;
    }

    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _qiblaBearing = _computeBearing(pos.latitude, pos.longitude, _kaabaLat, _kaabaLng);
    });

    _sub = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        setState(() => _heading = event.heading!);
      }
    });
  }

  double _computeBearing(double lat1, double lng1, double lat2, double lng2) {
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final deltaLambda = (lng2 - lng1) * pi / 180;
    final y = sin(deltaLambda) * cos(phi2);
    final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda);
    final theta = atan2(y, x);
    return (theta * 180 / pi + 360) % 360;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qibla')),
      body: Center(
        child: _error != null
            ? Padding(padding: const EdgeInsets.all(24), child: Text(_error!))
            : _qiblaBearing == null
                ? const CircularProgressIndicator()
                : _CompassDial(heading: _heading, qiblaBearing: _qiblaBearing!),
      ),
    );
  }
}

class _CompassDial extends StatelessWidget {
  final double heading;
  final double qiblaBearing;
  const _CompassDial({required this.heading, required this.qiblaBearing});

  @override
  Widget build(BuildContext context) {
    // Angle of the Qibla needle relative to the phone's current heading.
    final needleAngle = (qiblaBearing - heading) * pi / 180;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFB5121B), width: 2),
                ),
              ),
              Transform.rotate(
                angle: needleAngle,
                child: const Icon(Icons.navigation, size: 90, color: Color(0xFFB5121B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Qibla bearing: ${qiblaBearing.toStringAsFixed(1)}°'),
      ],
    );
  }
}

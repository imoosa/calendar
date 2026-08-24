// lib/screens/qibla_screen.dart
//
// Same compass logic as before, restyled to match qibla.html: maroon
// needle, "using default location" warning banner style, maroon compass
// ring. The actual bug fix for this screen not working is NOT in this
// file -- it's the missing AndroidManifest.xml / Info.plist location
// permission entries. Add those first, or this screen will still hang
// or error regardless of styling.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../theme.dart';

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
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      setState(() => _error =
          'Location permission is required to compute Qibla direction. Enable it in your phone\'s app settings.');
      return;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() => _error = 'Enable location services on your phone to compute Qibla direction.');
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _qiblaBearing = _computeBearing(pos.latitude, pos.longitude, _kaabaLat, _kaabaLng);
      });
      _sub = FlutterCompass.events?.listen((event) {
        if (event.heading != null && mounted) {
          setState(() => _heading = event.heading!);
        }
      });
    } catch (e) {
      setState(() => _error = 'Could not get your location: $e');
    }
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
      appBar: AppBar(title: const Text('Qibla Direction')),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_off, color: AppColors.muted, size: 40),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.text)),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        setState(() => _error = null);
                        _init();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _qiblaBearing == null
                ? const CircularProgressIndicator(color: AppColors.maroon)
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
                  color: Colors.white,
                  border: Border.all(color: AppColors.maroon, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2)),
                  ],
                ),
              ),
              Transform.rotate(
                angle: needleAngle,
                child: const Icon(Icons.navigation, size: 90, color: AppColors.maroon),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('${qiblaBearing.toStringAsFixed(1)}° from North',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.maroon)),
        const SizedBox(height: 4),
        const Text('Point the top of your phone toward North to find your qibla direction.',
            style: TextStyle(fontSize: 13, color: AppColors.muted), textAlign: TextAlign.center),
      ],
    );
  }
}

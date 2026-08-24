import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../theme.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  final _api = ApiService();

  double? _qiblaBearing;
  double? _distanceKm;
  double _heading = 0;
  String? _error;
  StreamSubscription<CompassEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _error = null);

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required for Qibla.');
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Enable location services to use Qibla.');
      }

      final position = await Geolocator.getCurrentPosition();

      final server = await _api.fetchQibla(
        lat: position.latitude,
        lng: position.longitude,
      );

      if (!mounted) return;
      setState(() {
        _qiblaBearing =
            double.tryParse('${server['bearing_degrees']}');
        _distanceKm = double.tryParse('${server['distance_km']}');
      });

      await _sub?.cancel();
      _sub = FlutterCompass.events?.listen((event) {
        final value = event.heading;
        if (value != null && mounted) {
          setState(() => _heading = value);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qibla'),
        actions: [
          IconButton(onPressed: _init, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _error != null
          ? _errorView()
          : _qiblaBearing == null
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.maroon),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  children: [
                    InfoCard(
                      child: Column(
                        children: [
                          const Text(
                            'Qibla Direction',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_qiblaBearing!.toStringAsFixed(1)}° from North',
                            style: const TextStyle(
                              color: AppColors.maroon,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (_distanceKm != null)
                            Text(
                              '${_distanceKm!.toStringAsFixed(1)} km to Kaaba',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 20),
                          _CompassDial(
                            heading: _heading,
                            qiblaBearing: _qiblaBearing!,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: InfoCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, size: 38, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(
                _error ?? '',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _init,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompassDial extends StatelessWidget {
  final double heading;
  final double qiblaBearing;

  const _CompassDial({
    required this.heading,
    required this.qiblaBearing,
  });

  @override
  Widget build(BuildContext context) {
    final angle = (qiblaBearing - heading) * pi / 180;

    return SizedBox(
      width: 285,
      height: 285,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cream,
              border: Border.all(color: AppColors.maroon, width: 2),
            ),
          ),
          const Positioned(top: 14, child: Text('N', style: TextStyle(fontWeight: FontWeight.w900))),
          const Positioned(bottom: 14, child: Text('S', style: TextStyle(fontWeight: FontWeight.w900))),
          const Positioned(left: 18, child: Text('W', style: TextStyle(fontWeight: FontWeight.w900))),
          const Positioned(right: 18, child: Text('E', style: TextStyle(fontWeight: FontWeight.w900))),
          Transform.rotate(
            angle: angle,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.navigation, size: 92, color: AppColors.maroon),
                Text(
                  'QIBLA',
                  style: TextStyle(
                    color: AppColors.maroon,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
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

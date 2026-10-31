import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme/halo_colors.dart';
import '../../../domain/route.dart';

/// A workout's route on a map: the line it took, where it started and where
/// it ended or is now.
///
/// Two uses. A finished workout frames the whole route once and stays still;
/// it sits in a scrolling page, where a map that grabs the finger would trap
/// the scroll. A live workout follows [position] instead, also without
/// gestures, because the live layer is dragged down to minimise.
///
/// The tiles are CARTO's Positron and Dark Matter: quiet, grey basemaps that
/// let the route be the colour on the page, light or dark with the app.
class RouteMap extends StatefulWidget {
  const RouteMap({
    super.key,
    required this.route,
    this.position,
    this.follow = false,
    this.padding = const EdgeInsets.all(32),
  });

  final List<RoutePoint> route;

  /// Where the phone is, live.
  final RoutePoint? position;

  /// Keep [position] centred, rather than framing the route.
  final bool follow;

  /// Room left around the route when it is framed.
  final EdgeInsets padding;

  /// Whether to fetch tiles. Off in tests, which have no network; the route
  /// draws on the plain background.
  static bool tiles = true;

  static const _followZoom = 15.5;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  final MapController _map = MapController();
  bool _ready = false;

  @override
  void didUpdateWidget(RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final position = widget.position;
    if (widget.follow &&
        _ready &&
        position != null &&
        position != oldWidget.position) {
      _map.move(_latLng(position), _map.camera.zoom);
    }
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  static LatLng _latLng(RoutePoint p) => LatLng(p.latitude, p.longitude);

  /// One line per stretch of moving: a pause is a gap, not a straight line
  /// across wherever the user wandered meanwhile.
  List<List<LatLng>> _segments() {
    final segments = <List<LatLng>>[];
    int? current;
    for (final point in widget.route) {
      if (point.segment != current) {
        segments.add([]);
        current = point.segment;
      }
      segments.last.add(_latLng(point));
    }
    return segments.where((s) => s.length > 1).toList();
  }

  MapOptions _options(Color background) {
    const none = InteractionOptions(flags: InteractiveFlag.none);
    final route = widget.route;
    final position = widget.position;

    if (!widget.follow && route.length > 1) {
      return MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: [for (final p in route) _latLng(p)],
          padding: widget.padding,
          maxZoom: 17,
        ),
        interactionOptions: none,
        backgroundColor: background,
      );
    }
    final centre = position ?? (route.isEmpty ? null : route.last);
    return MapOptions(
      initialCenter: centre == null ? const LatLng(0, 0) : _latLng(centre),
      initialZoom: centre == null ? 2 : RouteMap._followZoom,
      interactionOptions: none,
      backgroundColor: background,
      onMapReady: () => _ready = true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final accent = HaloColors.accent.resolveFrom(context);
    final background = dark ? const Color(0xFF1B1B1D) : const Color(0xFFF1F0EC);
    final route = widget.route;
    final position = widget.position;

    return FlutterMap(
      mapController: _map,
      options: _options(background),
      children: [
        if (RouteMap.tiles)
          TileLayer(
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/{style}/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            additionalOptions: {'style': dark ? 'dark_all' : 'light_all'},
            retinaMode: RetinaMode.isHighDensity(context),
            maxNativeZoom: 20,
            userAgentPackageName: 'com.halo.halo',
            tileDisplay: const TileDisplay.fadeIn(
              duration: Duration(milliseconds: 200),
            ),
          ),
        PolylineLayer(
          // Drawn as recorded: the default simplification turns a curving
          // path into straight chords.
          simplificationTolerance: 0,
          polylines: [
            for (final segment in _segments())
              Polyline(
                points: segment,
                strokeWidth: 5,
                color: accent,
                // A hairline of the ground colour keeps the line distinct
                // where it crosses a road drawn in a similar grey.
                borderStrokeWidth: 1.5,
                borderColor: dark
                    ? const Color(0x99000000)
                    : const Color(0x66000000),
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            if (route.isNotEmpty && !widget.follow)
              Marker(
                point: _latLng(route.first),
                width: 16,
                height: 16,
                child: _Dot(color: accent, size: 16),
              ),
            if (route.length > 1 && !widget.follow)
              Marker(
                point: _latLng(route.last),
                width: 16,
                height: 16,
                child: _Dot(
                  color: CupertinoColors.systemRed.resolveFrom(context),
                  size: 16,
                ),
              ),
            if (widget.follow && position != null)
              Marker(
                point: _latLng(position),
                width: 26,
                height: 26,
                child: _Dot(color: accent, size: 22, halo: true),
              ),
          ],
        ),
        if (RouteMap.tiles) const _Attribution(),
      ],
    );
  }
}

/// A marker: a coloured dot in a white ring, with a glow around the live one.
class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size, this.halo = false});

  final Color color;
  final double size;
  final bool halo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: const Color(0xFFFFFFFF), width: 3),
          boxShadow: [
            BoxShadow(
              color: halo
                  ? color.withValues(alpha: 0.45)
                  : const Color(0x40000000),
              blurRadius: halo ? 12 : 4,
              spreadRadius: halo ? 4 : 0,
            ),
          ],
        ),
      ),
    );
  }
}

/// The credit the tiles' licences ask for, small in the corner.
class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          '© OpenStreetMap © CARTO',
          style: TextStyle(
            color: HaloColors.secondaryLabelOf(context),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

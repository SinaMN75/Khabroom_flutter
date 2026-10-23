import "package:u/utilities.dart";

/// Move the map until the pin sits on the place, then confirm. Returns the chosen point.
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController map = MapController();
  late LatLng point = widget.latitude == null || widget.longitude == null ? const LatLng(35.6997, 51.3380) : LatLng(widget.latitude!, widget.longitude!);

  @override
  void dispose() {
    map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UScaffold(
      appBar: AppBar(title: Text(U.s.pickTheLocationOnTheMap)),
      body: UMap(
        controller: map,
        center: point,
        zoom: widget.latitude == null ? 11 : 16,
        initOnUserLocation: widget.latitude == null,
        persianDigits: true,
        centerWidget: Icon(Icons.location_on_rounded, size: 44, color: scheme.primary).pOnly(bottom: 40),
        onPositionChanged: (MapCamera camera, bool _) => point = camera.center,
        onTap: (TapPosition _, LatLng p) => map.move(p, map.camera.zoom),
      ),
      bottomNavigationBar: SafeArea(child: UButton(title: U.s.useThisLocation, onTap: () => UNavigator.back(point)).pAll(12)),
    );
  }
}

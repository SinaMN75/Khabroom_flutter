import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// The photos customers see for a place; the cover is the first thing on its card.
class PlacePhotosPage extends StatefulWidget {
  const PlacePhotosPage({required this.place, super.key});

  final AppPlace place;

  @override
  State<PlacePhotosPage> createState() => _PlacePhotosPageState();
}

class _PlacePhotosPageState extends State<PlacePhotosPage> {
  final URxState state = URxState();
  List<UMediaResponse> media = <UMediaResponse>[];
  UFilePickerController? photos;
  bool busy = false;

  @override
  void initState() {
    read();
    super.initState();
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  Future<void> read() async {
    state.loading();
    final String id = widget.place.id;
    media = switch (widget.place.kind) {
      AppKind.hotel => (await UServices.hotel.readHotelById(p: UIdParams(id: id, selectorArgs: const UHotelSelectorArgs(media: UMediaSelectorArgs())))).$1?.result?.media,
      AppKind.dorm => (await UServices.dorm.readDormById(p: UIdParams(id: id, selectorArgs: const UDormSelectorArgs(media: UMediaSelectorArgs())))).$1?.result?.media,
    } ?? <UMediaResponse>[];
    photos = UFilePickerController.fromMedia(media);
    if (mounted) setState(() {});
    state.loaded();
  }

  Future<void> _save() async {
    if (photos == null) return;
    setState(() => busy = true);
    final AppPlace p = widget.place;
    await UServices.media.syncGallery(
      photos!,
      existing: media,
      hotelId: p.kind == AppKind.hotel ? p.id : null,
      dormId: p.kind == AppKind.dorm ? p.id : null,
    );
    UToast.success(message: U.s.done);
    if (mounted) setState(() => busy = false);
    await read();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.photos).help("app.photos.page", inline: true)),
    body: AppStateView(
      state: state,
      onRetry: read,
      onLoaded: (BuildContext context) => AppPageBody(
        maxWidth: 760,
        children: <Widget>[
          UTextBodySmall(U.s.pickTheCoverPhotoItIsShownFirst, color: Theme.of(context).colorScheme.onSurfaceVariant).pOnly(bottom: 12),
          UFilePicker.gallery(photos!),
          const SizedBox(height: 16),
          UButton(title: U.s.save, isLoading: busy, onTap: busy ? null : _save),
        ],
      ),
    ),
  );
}

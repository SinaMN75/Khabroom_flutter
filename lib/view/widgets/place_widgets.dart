import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

// Widgets that show the rich details of hotels and dorms (gallery, amenities, nearby places, FAQs...).

/// Horizontal strip of photos (cover first). Tap a photo to see it large.
class AppGallery extends StatelessWidget {
  const AppGallery({required this.media, super.key, this.height = 92});

  final List<UMediaResponse>? media;
  final double height;

  @override
  Widget build(BuildContext context) {
    final List<UMediaResponse> photos = (media ?? <UMediaResponse>[]).sortedForGallery().where((UMediaResponse m) => (m.url ?? "").isNotEmpty).toList();
    if (photos.length < 2) return const SizedBox();
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: photos.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int i) => GestureDetector(
          onTap: () => UNavigator.dialog(
            Dialog(
              insetPadding: const EdgeInsets.all(12),
              child: InteractiveViewer(child: UImage(photos[i].url!)),
            ),
          ),
          child: AspectRatio(aspectRatio: 4 / 3, child: UImage(photos[i].url!, fit: BoxFit.cover, borderRadius: 10)),
        ),
      ),
    );
  }
}

/// Amenities as small boxes with a check mark.
/// The titles come from the tags: `AppAmenityList(items: TagHotel.values.group(500).titlesFromNumbers(hotel.tags))`.
class AppAmenityList extends StatelessWidget {
  const AppAmenityList({required this.items, super.key});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final String item in items)
          UContainer(
            radius: 10,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: scheme.surfaceContainer,
            border: Border.all(color: scheme.outlineVariant),
            child: URow(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.check_circle_outline_rounded, size: 15, color: scheme.primary),
                const SizedBox(width: 6),
                UTextBodySmall(item, color: scheme.onSurface),
              ],
            ),
          ),
      ],
    );
  }
}

/// Short selling points, one per line.
class AppHighlightList extends StatelessWidget {
  const AppHighlightList({required this.items, super.key});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final String item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: URow(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.auto_awesome_rounded, size: 15, color: scheme.primary),
                const SizedBox(width: 8),
                UTextBodyMedium(item, color: scheme.onSurface, expanded: 1),
              ],
            ),
          ),
      ],
    );
  }
}

/// Nearby places with distance / travel time.
class AppNearbyList extends StatelessWidget {
  const AppNearbyList({required this.items, super.key});

  final List<UPlaceNearby> items;

  static String _distance(int meters) => meters < 1000 ? "${meters.toString().toPersianNumber()} ${U.s.meterUnit}" : "${(meters / 1000).toStringAsFixed(1).toPersianNumber()} ${U.s.kilometerUnit}";

  @override
  Widget build(BuildContext context) => UColumn(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (final UPlaceNearby n in items)
        AppInfoRow(
          icon: Icons.place_outlined,
          label: n.title,
          value: <String>[
            if (n.distanceMeters != null) _distance(n.distanceMeters!),
            if (n.minutes != null) "${n.minutes.toString().toPersianNumber()} ${U.s.minuteUnit}",
          ].join(" · "),
        ),
    ],
  );
}

/// Frequently asked questions.
class AppFaqList extends StatelessWidget {
  const AppFaqList({required this.items, super.key});

  final List<UPlaceFaq> items;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final UPlaceFaq f in items)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 10),
              expandedAlignment: Alignment.centerRight,
              title: UTextTitleSmall(f.question, color: scheme.onSurface),
              children: <Widget>[UTextBodySmall(f.answer, color: scheme.onSurfaceVariant)],
            ),
          ),
      ],
    );
  }
}

/// Website / WhatsApp / Telegram / Instagram buttons (only the ones the place has).
class AppSocialLinks extends StatelessWidget {
  const AppSocialLinks({required this.website, required this.whatsapp, required this.instagram, required this.telegram, super.key});

  final String? website;
  final String? whatsapp;
  final String? instagram;
  final String? telegram;

  static bool _has(String? v) => v != null && v.trim().isNotEmpty;

  /// Values may be a full address or just a number / username.
  static Future<void> _open(String value, Future<void> Function(String) fallback) => value.startsWith("http") ? ULaunch.url(value) : fallback(value);

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: <Widget>[
      if (_has(website)) ActionChip(avatar: const Icon(Icons.language_rounded, size: 16), label: Text(U.s.website), onPressed: () => ULaunch.url(website!.startsWith("http") ? website! : "https://$website")),
      if (_has(whatsapp)) ActionChip(avatar: const Icon(Icons.chat_rounded, size: 16), label: Text(U.s.whatsapp), onPressed: () => _open(whatsapp!, ULaunch.whatsApp)),
      if (_has(telegram)) ActionChip(avatar: const Icon(Icons.send_rounded, size: 16), label: Text(U.s.telegram), onPressed: () => _open(telegram!, ULaunch.telegram)),
      if (_has(instagram)) ActionChip(avatar: const Icon(Icons.camera_alt_outlined, size: 16), label: Text(U.s.instagram), onPressed: () => _open(instagram!, ULaunch.instagram)),
    ],
  );

  bool get isEmpty => !_has(website) && !_has(whatsapp) && !_has(instagram) && !_has(telegram);
}

/// Joins titles for one row: "Breakfast، Dinner".
String joinTitles(List<String> titles) => titles.join("، ");

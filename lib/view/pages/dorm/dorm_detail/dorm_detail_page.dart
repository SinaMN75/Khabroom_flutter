import "package:khabroom/main.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/pages/dorm/dorm_detail/dorm_detail_controller.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:khabroom/view/widgets/review_widgets.dart";
import "package:u/utilities.dart";

class DormDetailPage extends StatefulWidget {
  const DormDetailPage({required this.dormId, super.key});

  final String dormId;

  @override
  State<DormDetailPage> createState() => _DormDetailPageState();
}

class _DormDetailPageState extends State<DormDetailPage> {
  final DormDetailController c = DormDetailController();

  @override
  void initState() {
    c.init(dormId: widget.dormId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.dorms)),
    body: Obx(() {
      if (c.detailState.isLoading() || c.detailState.isInitial()) return const UProgressCircular(size: 34, strokeWidth: 3).alignAtCenter();
      if (c.detailState.isError() || c.dorm == null) return UErrorRetry(onTap: c.read);

      final UDormResponse dorm = c.dorm!;
      return SingleChildScrollView(
        padding: AppResponsive.pagePadding(context),
        child: AppContent(
          child: AppDetailLayout(
            content: _content(context, dorm),
            side: _contactCard(context, dorm),
            compactSideFirst: true,
          ),
        ),
      );
    }),
  );

  Widget _content(BuildContext context, UDormResponse dorm) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool girls = dorm.tags.contains(TagDorm.girls.number);
    final bool boys = dorm.tags.contains(TagDorm.boys.number);

    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          padding: EdgeInsets.zero,
          clip: true,
          child: UColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppCoverImage(media: dorm.media, height: AppResponsive.isCompact(context) ? 200 : 280, fallbackIcon: Icons.bedroom_parent_rounded),
              UColumn(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  URow(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      UTextHeadlineSmall(dorm.title, color: scheme.onSurface, expanded: 1),
                      if (girls || boys) AppChip(label: girls ? TagDorm.girls.titleFa : TagDorm.boys.titleFa, tone: AppTone.brand),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppRating(score: dorm.averageScore, count: dorm.commentCount),
                  if (dorm.jsonData.nearbyUniversity != null) ...<Widget>[
                    const SizedBox(height: 10),
                    URow(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.school_outlined, size: 15, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        UTextBodySmall(dorm.jsonData.nearbyUniversity!, color: scheme.onSurfaceVariant, expanded: 1),
                      ],
                    ),
                  ],
                ],
              ).pAll(16),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (dorm.jsonData.description != null) ...<Widget>[
          AppSectionCard(title: U.s.aboutThisPlace, icon: Icons.info_outline_rounded, child: UTextBodyMedium(dorm.jsonData.description!, color: scheme.onSurface)),
          const SizedBox(height: 16),
        ],
        if (dorm.jsonData.amenities.isNotEmpty) ...<Widget>[
          AppSectionCard(title: U.s.amenities, icon: Icons.check_circle_outline_rounded, child: AppChipList(items: dorm.jsonData.amenities)),
          const SizedBox(height: 16),
        ],
        AppSectionCard(
          title: U.s.roomsAndBeds,
          icon: Icons.bed_outlined,
          child: UColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final UDormRoomResponse room in dorm.rooms ?? <UDormRoomResponse>[]) _RoomRow(room: room),
            ],
          ),
        ),
        if (dorm.jsonData.requiredDocuments.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          AppSectionCard(title: U.s.requiredDocuments, icon: Icons.description_outlined, child: AppBulletList(items: dorm.jsonData.requiredDocuments)),
        ],
        if (dorm.jsonData.rules.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          AppSectionCard(title: U.s.rules, icon: Icons.gavel_rounded, child: AppBulletList(items: dorm.jsonData.rules)),
        ],
        const SizedBox(height: 16),
        ReviewSection(comments: dorm.comments ?? <UCommentResponse>[], dormId: dorm.id, onSubmitted: c.read),
      ],
    );
  }

  /// Dorms are not booked online, so the side card explains the in-person flow and gives a way to reach them.
  Widget _contactCard(BuildContext context, UDormResponse dorm) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          URow(
            children: <Widget>[
              UIconBackground(Icons.handshake_outlined, color: scheme.primary),
              const SizedBox(width: 12),
              UTextTitleSmall(U.s.dormBedsAreBookedInPersonOnly, color: scheme.onSurface, expanded: 1),
            ],
          ),
          const SizedBox(height: 12),
          UTextBodySmall(U.s.toTakeABedCallTheDormOrVisitInPersonOnceYouAreRegisteredTheContractAndItsMonthlyInvoicesShowUpRightHere, color: scheme.onSurfaceVariant),
          const SizedBox(height: 16),
          AppInfoRow(label: U.s.monthlyRent, value: money(dorm.minMonthlyRent), emphasize: true),
          if (dorm.jsonData.visitingHours != null) AppInfoRow(label: U.s.visitingHours, value: dorm.jsonData.visitingHours!),
          if (dorm.address != null) AppInfoRow(label: U.s.address, value: dorm.address!),
          const SizedBox(height: 14),
          if (dorm.phoneNumber != null)
            UButton(
              title: U.s.callTheDorm,
              icon: const Icon(Icons.call_outlined),
              fullWidth: true,
              onTap: () => ULaunch.call(dorm.phoneNumber!),
            ),
          if (dorm.jsonData.latitude != null && dorm.jsonData.longitude != null)
            UButton(
              title: U.s.directions,
              type: UButtonType.text,
              icon: const Icon(Icons.map_outlined),
              fullWidth: true,
              onTap: () => ULaunch.map(dorm.jsonData.latitude!, dorm.jsonData.longitude!),
            ).pOnly(top: 8),
        ],
      ),
    );
  }
}

class _RoomRow extends StatelessWidget {
  const _RoomRow({required this.room});

  final UDormRoomResponse room;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<UDormBedResponse> beds = room.beds ?? <UDormBedResponse>[];
    final double? minRent = beds.isEmpty ? null : beds.map((UDormBedResponse b) => b.monthlyRent).reduce((double a, double b) => a < b ? a : b);
    final double? minDeposit = beds.isEmpty ? null : beds.map((UDormBedResponse b) => b.deposit).reduce((double a, double b) => a < b ? a : b);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: UContainer(
        radius: 13,
        padding: const EdgeInsets.all(13),
        color: scheme.surfaceContainer,
        border: Border.all(color: scheme.outlineVariant),
        child: UColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            URow(
              children: <Widget>[
                UTextTitleSmall(room.title, color: scheme.onSurface, expanded: 1),
                AppChip(label: "${beds.length.toString().toPersianNumber()} ${U.s.bed}", filled: false),
              ],
            ),
            if (room.capacity > 0 || room.jsonData.floor != null) ...<Widget>[
              const SizedBox(height: 8),
              URow(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (room.capacity > 0) UTextBodySmall("${U.s.roomCapacity}: ${room.capacity.toString().toPersianNumber()}", color: scheme.onSurfaceVariant),
                  if (room.capacity > 0 && room.jsonData.floor != null) const SizedBox(width: 12),
                  if (room.jsonData.floor != null) UTextBodySmall("${U.s.floor}: ${room.jsonData.floor.toString().toPersianNumber()}", color: scheme.onSurfaceVariant),
                ],
              ),
            ],
            if (minRent != null) ...<Widget>[
              const SizedBox(height: 10),
              AppInfoRow(label: U.s.monthlyRent, value: money(minRent)),
              AppInfoRow(label: U.s.deposit, value: money(minDeposit)),
            ],
          ],
        ),
      ),
    );
  }
}

import "package:khabroom/main.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/pages/dorm/dorm_detail/dorm_detail_page.dart";
import "package:khabroom/view/pages/home/home_controller.dart";
import "package:khabroom/view/pages/hotel/hotel_detail/hotel_detail_page.dart";
import "package:khabroom/view/pages/notifications/notification_page.dart";
import "package:khabroom/view/pages/reservations/reservation_detail/reservation_detail_page.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController c = HomeController();

  @override
  void initState() {
    c.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => UNavigator.push(const NotificationPage()),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: c.init,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppResponsive.pagePadding(context),
          child: AppContent(
            child: UColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _header(context).fadeSlideIn(),
                const SizedBox(height: 20),
                Obx(() => c.stayState.isLoaded() ? _stayBanner(context) : const SizedBox.shrink()),
                AppSectionHeader(title: U.s.hotels, subtitle: U.s.hotelReservation).pOnly(bottom: 14),
                AppStateView(
                  state: c.hotelState,
                  onRetry: c.readHotels,
                  emptyTitle: U.s.noPlacesHaveBeenAddedYet,
                  emptyIcon: Icons.apartment_outlined,
                  onLoaded: (BuildContext context) => UColumn(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (final UHotelResponse hotel in c.hotels)
                        _HotelSpotlight(hotel: hotel, onTap: () => UNavigator.push(HotelDetailPage(hotelId: hotel.id))).pOnly(bottom: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppSectionHeader(title: U.s.dorms, subtitle: U.s.dormBedsAreBookedInPersonOnly).pOnly(bottom: 14),
                AppStateView(
                  state: c.dormState,
                  onRetry: c.readDorms,
                  emptyTitle: U.s.noPlacesHaveBeenAddedYet,
                  emptyIcon: Icons.bedroom_parent_outlined,
                  onLoaded: (BuildContext context) => AppGrid(
                    children: <Widget>[
                      for (final UDormResponse dorm in c.dorms) _DormCard(dorm: dorm, onTap: () => UNavigator.push(DormDetailPage(dormId: dorm.id))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

  Widget _header(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        UTextBodySmall("${U.s.welcome} ${U.user.firstName ?? ""}".trim(), color: scheme.onSurfaceVariant),
        const SizedBox(height: 4),
        UTextHeadlineMedium(U.s.whereAreYouStaying, color: scheme.onSurface),
      ],
    );
  }

  /// One card at a time: the nearest stay, or the invoice that is waiting to be paid.
  Widget _stayBanner(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    if (c.upcomingReservations.isNotEmpty) {
      final UHotelReservationResponse r = c.upcomingReservations.first;
      return UContainer(
        radius: 18,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 24),
        gradient: const LinearGradient(colors: AppColors.gradient, begin: Alignment.topRight, end: Alignment.bottomLeft),
        onTap: () => UNavigator.push(ReservationDetailPage(reservationId: r.id)),
        child: URow(
          children: <Widget>[
            UColumn(
              expanded: 1,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                UTextLabelMedium(U.s.yourStay, color: AppColors.onGradient.withValues(alpha: 0.85)),
                const SizedBox(height: 6),
                UTextTitleLarge(r.hotel?.title ?? U.s.hotelReservation, color: AppColors.onGradient),
                const SizedBox(height: 6),
                UTextBodySmall(
                  "${r.checkInDate.toJalaliDate()} — ${r.checkOutDate.toJalaliDate()}",
                  color: AppColors.onGradient.withValues(alpha: 0.85),
                ),
              ],
            ),
            Icon(Icons.chevron_left_rounded, color: AppColors.onGradient.withValues(alpha: 0.9)),
          ],
        ),
      );
    }

    if (c.unpaidInvoices.isNotEmpty) {
      final UDormBedInvoiceResponse invoice = c.unpaidInvoices.first;
      final bool overdue = invoice.dueDate.isBefore(DateTime.now());
      return AppCard(
        onTap: () => AppShell.go(2),
        child: URow(
          children: <Widget>[
            UIconBackground(Icons.receipt_long_outlined, color: overdue ? scheme.error : AppColors.warning),
            const SizedBox(width: 12),
            UColumn(
              expanded: 1,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                UTextTitleSmall(overdue ? U.s.overdue : U.s.monthlyInvoices, color: scheme.onSurface),
                const SizedBox(height: 4),
                UTextBodySmall("${U.s.dueDate}: ${invoice.dueDate.toJalaliDate()}", color: scheme.onSurfaceVariant),
              ],
            ),
            AppPrice(amount: invoice.debtAmount + invoice.penaltyAmount - invoice.creditorAmount),
          ],
        ),
      ).pOnly(bottom: 24);
    }

    return const SizedBox.shrink();
  }
}

/// Hotels are few, so each one gets a full-width spotlight rather than a row in a list.
class _HotelSpotlight extends StatelessWidget {
  const _HotelSpotlight({required this.hotel, required this.onTap});

  final UHotelResponse hotel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool compact = AppResponsive.isCompact(context);
    final Widget cover = AppCoverImage(media: hotel.media, height: compact ? 190 : 230, fallbackIcon: Icons.apartment_rounded);

    return AppCard(
      padding: EdgeInsets.zero,
      clip: true,
      onTap: onTap,
      child: compact
          ? UColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[cover, _body(context)],
            )
          : IntrinsicHeight(
              child: URow(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(width: 272, child: cover),
                  UColumn(
                    expanded: 1,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[_body(context)],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _body(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<String> amenities = hotel.jsonData.amenities.take(4).toList();

    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        URow(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            UTextTitleLarge(hotel.title, color: scheme.onSurface, expanded: 1),
            if (hotel.stars > 0) AppChip(label: "${hotel.stars.toString().toPersianNumber()} ${U.s.stars}", icon: Icons.star_rounded, tone: AppTone.warning),
          ],
        ),
        const SizedBox(height: 8),
        URow(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.location_on_outlined, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 5),
            UTextBodySmall(hotel.address ?? hotel.cityCode, color: scheme.onSurfaceVariant, maxLines: 1, overflow: TextOverflow.ellipsis, expanded: 1),
          ],
        ),
        const SizedBox(height: 8),
        AppRating(score: hotel.averageScore, count: hotel.commentCount),
        if (amenities.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          AppChipList(items: amenities),
        ],
        const SizedBox(height: 14),
        Divider(color: scheme.outlineVariant, height: 1),
        const SizedBox(height: 14),
        URow(
          children: <Widget>[
            UColumn(
              expanded: 1,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                UTextLabelSmall(U.s.startingFrom, color: scheme.onSurfaceVariant),
                const SizedBox(height: 2),
                URow(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    UTextTitleLarge(money(hotel.minPricePerNight), color: scheme.onSurface),
                    const SizedBox(width: 5),
                    UTextLabelSmall(U.s.perNight, color: scheme.onSurfaceVariant),
                  ],
                ),
              ],
            ),
            UButton(title: U.s.book, onTap: onTap),
          ],
        ),
      ],
    ).pAll(16);
  }
}

class _DormCard extends StatelessWidget {
  const _DormCard({required this.dorm, required this.onTap});

  final UDormResponse dorm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool girls = dorm.tags.contains(TagDorm.girls.number);
    final bool boys = dorm.tags.contains(TagDorm.boys.number);

    return AppCard(
      padding: EdgeInsets.zero,
      clip: true,
      onTap: onTap,
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppCoverImage(media: dorm.media, height: 150, fallbackIcon: Icons.bedroom_parent_rounded),
          UColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              URow(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  UTextTitleMedium(dorm.title, color: scheme.onSurface, expanded: 1),
                  if (girls || boys) AppChip(label: girls ? TagDorm.girls.titleFa : TagDorm.boys.titleFa, tone: AppTone.brand),
                ],
              ),
              const SizedBox(height: 8),
              UTextBodySmall(dorm.jsonData.nearbyUniversity ?? dorm.address ?? dorm.cityCode, color: scheme.onSurfaceVariant, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              URow(
                children: <Widget>[
                  UColumn(
                    expanded: 1,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      UTextLabelSmall(U.s.monthlyRent, color: scheme.onSurfaceVariant),
                      const SizedBox(height: 2),
                      UTextTitleSmall(money(dorm.minMonthlyRent), color: scheme.onSurface),
                    ],
                  ),
                  AppChip(label: U.s.inPerson, icon: Icons.handshake_outlined),
                ],
              ),
            ],
          ).pAll(14),
        ],
      ),
    );
  }
}

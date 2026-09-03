import "package:khabroom/utils/responsive.dart";
import "package:khabroom/utils/status_helpers.dart";
import "package:khabroom/view/pages/reservations/reservation_detail/reservation_detail_page.dart";
import "package:khabroom/view/pages/reservations/reservations_controller.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({super.key});

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  final ReservationsController c = ReservationsController();

  @override
  void initState() {
    c.read();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.myReservations)),
    body: RefreshIndicator(
      onRefresh: c.read,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppResponsive.pagePadding(context),
        child: AppContent(
          maxWidth: AppResponsive.readableMaxWidth + 160,
          child: UColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Obx(
                () => USegmentedControl<int>(
                  selectedValue: c.selectedTab.value,
                  items: <int, String>{0: U.s.upcoming, 1: U.s.past},
                  onValueChanged: (int? value) => c.selectedTab(value ?? 0),
                ),
              ),
              const SizedBox(height: 16),
              AppStateView(
                state: c.reservationState,
                onRetry: c.read,
                emptyTitle: U.s.youHaveNoReservations,
                emptyIcon: Icons.confirmation_number_outlined,
                onLoaded: (BuildContext context) => Obx(() {
                  final List<UHotelReservationResponse> items = c.selectedTab.value == 0 ? c.upcoming : c.past;
                  if (items.isEmpty) return AppEmpty(title: U.s.youHaveNoReservations, icon: Icons.confirmation_number_outlined);
                  return UColumn(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (final UHotelReservationResponse item in items)
                        ReservationTile(reservation: item, onTap: () async {
                          await UNavigator.push(ReservationDetailPage(reservationId: item.id));
                          await c.read();
                        }).pOnly(bottom: 12),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ReservationTile extends StatelessWidget {
  const ReservationTile({required this.reservation, required this.onTap, super.key});

  final UHotelReservationResponse reservation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          URow(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UColumn(
                expanded: 1,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UTextTitleMedium(reservation.hotel?.title ?? U.s.hotelReservation, color: scheme.onSurface),
                  const SizedBox(height: 5),
                  UTextBodySmall(reservation.room?.title ?? "", color: scheme.onSurfaceVariant),
                ],
              ),
              AppStatusChip(status: AppStatus.reservation(reservation.tags)),
            ],
          ),
          const SizedBox(height: 12),
          URow(
            children: <Widget>[
              Icon(Icons.calendar_today_outlined, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              UTextBodySmall("${reservation.checkInDate.toJalaliDate()} — ${reservation.checkOutDate.toJalaliDate()}", color: scheme.onSurfaceVariant, expanded: 1),
              AppPrice(amount: reservation.totalPrice),
            ],
          ),
        ],
      ),
    );
  }
}

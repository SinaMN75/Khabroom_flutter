import "package:khabroom/main.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/utils/status_helpers.dart";
import "package:khabroom/view/pages/reservations/reservation_detail/reservation_detail_controller.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

class ReservationDetailPage extends StatefulWidget {
  const ReservationDetailPage({required this.reservationId, super.key});

  final String reservationId;

  @override
  State<ReservationDetailPage> createState() => _ReservationDetailPageState();
}

class _ReservationDetailPageState extends State<ReservationDetailPage> {
  final ReservationDetailController c = ReservationDetailController();

  @override
  void initState() {
    c.init(reservationId: widget.reservationId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.reservationDetails)),
    body: Obx(() {
      if (c.detailState.isLoading() || c.detailState.isInitial()) return const UProgressCircular(size: 34, strokeWidth: 3).alignAtCenter();
      if (c.detailState.isError() || c.reservation == null) return UErrorRetry(onTap: c.read);

      final UHotelReservationResponse r = c.reservation!;
      return SingleChildScrollView(
        padding: AppResponsive.pagePadding(context),
        child: AppContent(
          maxWidth: AppResponsive.readableMaxWidth,
          child: UColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _headerCard(context, r),
              const SizedBox(height: 16),
              AppSectionCard(
                title: U.s.reservationDetails,
                icon: Icons.event_available_outlined,
                child: UColumn(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (r.jsonData.reservationCode != null) AppInfoRow(label: U.s.reservationCode, value: r.jsonData.reservationCode!),
                    AppInfoRow(label: U.s.roomTitle, value: r.room?.title ?? "-"),
                    AppInfoRow(label: U.s.checkInDate, value: r.checkInDate.toJalaliDate()),
                    AppInfoRow(label: U.s.checkOutDate, value: r.checkOutDate.toJalaliDate()),
                    AppInfoRow(label: U.s.nightsCountLabel, value: "${(r.jsonData.nightCount ?? 0).toString().toPersianNumber()} ${U.s.night}"),
                    AppInfoRow(label: U.s.guestCount, value: r.guestCount.toString().toPersianNumber()),
                    AppInfoRow(label: U.s.totalPrice, value: money(r.totalPrice), emphasize: true),
                  ],
                ),
              ),
              if (r.jsonData.guests.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                AppSectionCard(
                  title: U.s.guestInformation,
                  icon: Icons.people_outline_rounded,
                  child: UColumn(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (final UReservationGuest guest in r.jsonData.guests)
                        AppInfoRow(label: guest.fullName, value: guest.nationalCode?.toPersianNumber() ?? "-"),
                    ],
                  ),
                ),
              ],
              if (c.invoice != null) ...<Widget>[
                const SizedBox(height: 16),
                _invoiceCard(context, c.invoice!),
              ],
              if (r.jsonData.cancelledAt != null) ...<Widget>[
                const SizedBox(height: 16),
                AppSectionCard(
                  title: U.s.cancelReservation,
                  icon: Icons.event_busy_outlined,
                  child: UColumn(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AppInfoRow(label: U.s.date, value: r.jsonData.cancelledAt!.toJalaliDate()),
                      AppInfoRow(label: U.s.cancellationPenalty, value: money(r.jsonData.cancellationPenalty)),
                      AppInfoRow(label: U.s.refundAmount, value: money(r.jsonData.refundAmount), emphasize: true),
                    ],
                  ),
                ),
              ],
              if (c.canCancel) ...<Widget>[
                const SizedBox(height: 20),
                UButton(
                  title: U.s.cancelReservation,
                  type: UButtonType.outlined,
                  foregroundColor: Theme.of(context).colorScheme.error,
                  borderColor: Theme.of(context).colorScheme.error,
                  fullWidth: true,
                  onTap: c.cancel,
                ),
              ],
            ],
          ),
        ),
      );
    }),
  );

  Widget _headerCard(BuildContext context, UHotelReservationResponse r) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppCoverImage(media: r.hotel?.media, height: 160, fallbackIcon: Icons.apartment_rounded),
          URow(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UColumn(
                expanded: 1,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UTextTitleLarge(r.hotel?.title ?? U.s.hotelReservation, color: scheme.onSurface),
                  if (r.hotel?.address != null) ...<Widget>[
                    const SizedBox(height: 6),
                    UTextBodySmall(r.hotel!.address!, color: scheme.onSurfaceVariant),
                  ],
                ],
              ),
              AppStatusChip(status: AppStatus.reservation(r.tags)),
            ],
          ).pAll(16),
        ],
      ),
    );
  }

  Widget _invoiceCard(BuildContext context, UHotelInvoiceResponse invoice) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double remaining = invoice.debtAmount + invoice.penaltyAmount - invoice.creditorAmount - invoice.paidAmount;
    return AppSectionCard(
      title: U.s.invoiceDetails,
      icon: Icons.receipt_long_outlined,
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          URow(
            children: <Widget>[
              UTextBodySmall(U.s.status, color: scheme.onSurfaceVariant, expanded: 1),
              AppStatusChip(status: AppStatus.hotelInvoice(invoice.tags, invoice.dueDate)),
            ],
          ),
          AppInfoRow(label: U.s.dueDate, value: invoice.dueDate.toJalaliDate()),
          AppInfoRow(label: U.s.totalPrice, value: money(invoice.debtAmount)),
          if (invoice.penaltyAmount > 0) AppInfoRow(label: U.s.penaltyAmount, value: money(invoice.penaltyAmount)),
          if (invoice.paidAmount > 0) AppInfoRow(label: U.s.paidAmount, value: money(invoice.paidAmount)),
          if (c.isUnpaid) ...<Widget>[
            AppInfoRow(label: U.s.remainingAmount, value: money(remaining), emphasize: true, valueColor: scheme.primary),
            const SizedBox(height: 12),
            URow(
              children: <Widget>[
                UButton(expanded: 1, title: U.s.payFromWallet, type: UButtonType.outlined, onTap: c.payFromWallet),
                const SizedBox(width: 10),
                UButton(expanded: 1, title: U.s.payWithGateway, onTap: c.payWithGateway),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

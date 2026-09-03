import "package:khabroom/main.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/pages/hotel/booking/booking_controller.dart";
import "package:khabroom/view/pages/reservations/reservation_detail/reservation_detail_page.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

class BookingPage extends StatefulWidget {
  const BookingPage({
    required this.hotel,
    required this.availability,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestCount,
    super.key,
  });

  final UHotelResponse hotel;
  final UHotelRoomAvailabilityResponse availability;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestCount;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final BookingController c = BookingController();

  @override
  void initState() {
    c.init(guestCount: widget.guestCount);
    super.initState();
  }

  double get _total => widget.availability.totalPrice;

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.hotelReservation)),
    body: SingleChildScrollView(
      padding: AppResponsive.pagePadding(context),
      child: AppContent(
        child: AppDetailLayout(
          content: _content(context),
          side: _summary(context),
        ),
      ),
    ),
  );

  Widget _content(BuildContext context) => UColumn(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      AppSectionCard(
        title: U.s.yourStay,
        icon: Icons.event_available_outlined,
        child: UColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppInfoRow(label: U.s.hotels, value: widget.hotel.title),
            AppInfoRow(label: U.s.roomTitle, value: widget.availability.room.title),
            AppInfoRow(label: U.s.checkInDate, value: widget.checkInDate.toJalaliDate()),
            AppInfoRow(label: U.s.checkOutDate, value: widget.checkOutDate.toJalaliDate()),
            AppInfoRow(label: U.s.nightsCountLabel, value: "${widget.availability.nightCount.toString().toPersianNumber()} ${U.s.night}"),
            AppInfoRow(label: U.s.guestCount, value: widget.guestCount.toString().toPersianNumber()),
          ],
        ),
      ),
      const SizedBox(height: 16),
      AppSectionCard(
        title: U.s.guestInformation,
        icon: Icons.people_outline_rounded,
        child: Obx(
          () => UColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < c.guests.length; i++) _guestForm(context, i),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      AppSectionCard(
        title: U.s.description,
        icon: Icons.edit_note_rounded,
        child: UTextField(hintText: U.s.description, controller: c.controllerNotes, lines: 3),
      ),
    ],
  );

  Widget _guestForm(BuildContext context, int index) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final GuestForm form = c.guests[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          UTextLabelMedium(index == 0 ? U.s.mainGuest : "${U.s.guestNumber} ${(index + 1).toString().toPersianNumber()}", color: scheme.onSurfaceVariant),
          const SizedBox(height: 8),
          UTextField(labelText: U.s.fullName, controller: form.controllerName),
          const SizedBox(height: 10),
          UTextField(
            labelText: U.s.nationalCodeOptional,
            controller: form.controllerNationalCode,
            keyboardType: TextInputType.number,
            maxLength: 10,
          ),
        ],
      ),
    );
  }

  Widget _summary(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          UTextTitleSmall(U.s.priceDetails, color: scheme.onSurface),
          const SizedBox(height: 12),
          AppInfoRow(
            label: "${money(widget.availability.room.pricePerNight)} × ${widget.availability.nightCount.toString().toPersianNumber()} ${U.s.night}",
            value: money(_total),
          ),
          const Divider(height: 22),
          AppInfoRow(label: U.s.totalPrice, value: money(_total), emphasize: true, valueColor: scheme.primary),
          const SizedBox(height: 16),
          UTextTitleSmall(U.s.choosePaymentMethod, color: scheme.onSurface),
          const SizedBox(height: 10),
          Obx(
            () => UColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _paymentOption(
                  context,
                  selected: c.useWallet.value,
                  title: U.s.payFromWallet,
                  subtitle: c.walletState.isLoaded() ? "${U.s.walletBalance}: ${money(c.walletBalance)}" : U.s.payFromWalletBalance,
                  icon: Icons.account_balance_wallet_outlined,
                  enabled: c.canPayFromWallet(_total),
                  onTap: () => c.useWallet(true),
                ),
                const SizedBox(height: 10),
                _paymentOption(
                  context,
                  selected: !c.useWallet.value,
                  title: U.s.payWithGateway,
                  subtitle: U.s.payOnlineWithCard,
                  icon: Icons.credit_card_rounded,
                  enabled: true,
                  onTap: () => c.useWallet(false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          UButton(title: U.s.payNow, fullWidth: true, onTap: _submit),
        ],
      ),
    );
  }

  Widget _paymentOption(
    BuildContext context, {
    required bool selected,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UContainer(
      radius: 13,
      padding: const EdgeInsets.all(12),
      color: selected ? scheme.primaryContainer : scheme.surfaceContainer,
      border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant),
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: URow(
          children: <Widget>[
            Icon(icon, size: 19, color: selected ? scheme.primary : scheme.onSurfaceVariant),
            const SizedBox(width: 10),
            UColumn(
              expanded: 1,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                UTextTitleSmall(title, color: scheme.onSurface),
                const SizedBox(height: 3),
                UTextLabelSmall(subtitle, color: scheme.onSurfaceVariant),
              ],
            ),
            Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, size: 18, color: selected ? scheme.primary : scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (c.guests.isEmpty || c.guests.first.controllerName.text.trim().isEmpty) {
      UToast.error(message: U.s.thisFieldIsInvalid);
      return;
    }
    final bool payFromWallet = c.useWallet.value && c.canPayFromWallet(_total);

    ULoading.show();
    await UServices.hotel.bookHotelReservation(
      p: UHotelReservationBookParams(
        roomId: widget.availability.room.id,
        checkInDate: widget.checkInDate,
        checkOutDate: widget.checkOutDate,
        guestCount: widget.guestCount,
        guests: c.guestParams(),
        guestName: c.guests.first.controllerName.text.trim(),
        guestPhone: U.user.phoneNumber,
        notes: c.controllerNotes.text.trim().isEmpty ? null : c.controllerNotes.text.trim(),
        payFromWallet: payFromWallet,
      ),
      onOk: (UResponse<UHotelReservationResponse> response) async {
        ULoading.dismiss();
        final UHotelReservationResponse? reservation = response.result;
        if (reservation == null) {
          UToast.error(message: response.message);
          return;
        }
        if (payFromWallet) {
          UToast.success(message: U.s.yourReservationIsRegistered);
          await UNavigator.off(ReservationDetailPage(reservationId: reservation.id));
          return;
        }
        await _payWithGateway(reservation);
      },
      onError: (UEmptyResponse response) {
        ULoading.dismiss();
        UToast.error(message: response.message);
      },
      onException: (String exception) {
        ULoading.dismiss();
        UToast.error(message: exception);
      },
    );
  }

  Future<void> _payWithGateway(UHotelReservationResponse reservation) async {
    final UHotelInvoiceResponse? invoice = (reservation.invoices ?? <UHotelInvoiceResponse>[]).firstOrDefault();
    if (invoice == null) {
      await UNavigator.off(ReservationDetailPage(reservationId: reservation.id));
      return;
    }
    final bool paid = await UIpgFlow.pay(
      amount: invoice.debtAmount + invoice.penaltyAmount - invoice.creditorAmount,
      tag: TagTxn.hotelInvoice,
      invoiceId: invoice.id,
    );
    if (paid) UToast.success(message: U.s.yourReservationIsRegistered);
    await UNavigator.off(ReservationDetailPage(reservationId: reservation.id));
  }
}

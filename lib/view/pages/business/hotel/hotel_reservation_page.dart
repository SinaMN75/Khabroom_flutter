import "package:khabroom/main.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/utils/status_helpers.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:khabroom/view/pages/business/team/customers_page.dart";
import "package:u/utilities.dart";

/// One booking: the guest, the room, the bill, and the steps of a stay — confirm, check in, check out.
class HotelReservationPage extends StatefulWidget {
  const HotelReservationPage({required this.reservationId, super.key});

  final String reservationId;

  @override
  State<HotelReservationPage> createState() => _HotelReservationPageState();
}

class _HotelReservationPageState extends State<HotelReservationPage> {
  final URxState state = URxState();
  UHotelReservationResponse? r;
  List<UHotelInvoiceResponse> invoices = <UHotelInvoiceResponse>[];

  bool can(TagUser p) => AppWorkspace.can(p, placeId: r?.hotelId);

  bool has(TagHotelReservation t) => r?.tags.contains(t.number) ?? false;

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
    r = (await UServices.hotel.readHotelReservationById(p: UIdParams(id: widget.reservationId, selectorArgs: const UHotelReservationSelectorArgs(user: UUserSelectorArgs(), room: UHotelRoomSelectorArgs())))).$1?.result;
    if (r == null) {
      state.error();
      return;
    }
    invoices = (await UServices.hotel.readHotelInvoices(p: UHotelInvoiceReadParams(reservationId: r!.id, pageSize: 50, pageNumber: 1))).$1?.result ?? <UHotelInvoiceResponse>[];
    if (mounted) setState(() {});
    state.loaded();
  }

  Future<void> _do(Future<(dynamic, dynamic, String?)> call) async {
    if (await appSend(call)) await read();
  }

  static double _due(UHotelInvoiceResponse i) => i.debtAmount + i.penaltyAmount - i.creditorAmount - i.paidAmount;

  Future<void> _extend() async {
    DateTime? out = r!.checkOutDate.add(const Duration(days: 1));
    if (await AppForm.show(
      title: U.s.extendStay,
      onSubmit: () => appSend(UServices.hotel.extendReservation(p: UHotelReservationExtendParams(id: r!.id, checkOutDate: out!))),
      children: (BuildContext context, StateSetter setState) => <Widget>[UTextFieldDatePicker(labelText: U.s.newCheckOutDate, jalali: true, initialDate: out, onChange: (DateTime d, _) => out = d)],
    )) await read();
  }

  Future<void> _charge() async {
    final TextEditingController amount = TextEditingController();
    final TextEditingController note = TextEditingController();
    if (await AppForm.show(
      title: U.s.addToBill,
      help: "app.hotelBooking.charge",
      onSubmit: () => appSend(
        UServices.hotel.createHotelInvoice(
          p: UHotelInvoiceCreateParams(tags: <int>[TagHotelInvoice.notPaid.number, TagHotelInvoice.extra.number], debtAmount: tomanToRial(amount), reservationId: r!.id, dueDate: DateTime.now(), detail1: note.valueOrNull()),
        ),
      ),
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: note, labelText: U.s.whatIsItFor, hintText: U.s.forExampleRoomServiceOrMinibar),
        AppMoneyField(controller: amount, label: U.s.amount),
      ],
    )) await read();
    amount.dispose();
    note.dispose();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: Text(r?.jsonData.reservationCode ?? U.s.booking).help("app.hotelBooking.page", inline: true),
      actions: <Widget>[
        if (r != null && CustomersPage.allowed)
          IconButton(
            icon: const Icon(Icons.how_to_reg_outlined),
            tooltip: U.s.vipAndBlacklist,
            onPressed: () => CustomersPage.markUser(r!.userId, r!.jsonData.guestName ?? "${r!.user?.firstName ?? ""} ${r!.user?.lastName ?? ""}".trim()),
          ).help("app.hotelBooking.customer"),
        const UHelpActions("app.hotelBooking."),
      ],
    ),
    body: AppStateView(
      state: state,
      onRetry: read,
      onLoaded: (BuildContext context) {
        final UHotelReservationResponse x = r!;
        final ColorScheme scheme = Theme.of(context).colorScheme;
        final String guest = x.jsonData.guestName ?? "${x.user?.firstName ?? ""} ${x.user?.lastName ?? ""}".trim();
        final String? phone = x.jsonData.guestPhone ?? x.user?.phoneNumber;
        final double due = invoices.fold<double>(0, (double s, UHotelInvoiceResponse i) => s + (i.tags.contains(TagHotelInvoice.notPaid.number) ? _due(i) : 0));
        final bool manage = can(TagUser.permissionManageReservations);
        return AppPageBody(
          onRefresh: read,
          maxWidth: 860,
          children: <Widget>[
            AppCard(
              child: UColumn(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppTile(
                    icon: Icons.person_outline_rounded,
                    title: guest.isEmpty ? U.s.guest : guest,
                    subtitle: phone?.toPersianNumber(),
                    trailing: AppStatusChip(status: AppStatus.reservation(x.tags)),
                  ),
                  const Divider(),
                  AppInfoRow(label: U.s.room, value: "${x.room?.title ?? ""}${x.jsonData.roomNumber == null ? "" : " · ${x.jsonData.roomNumber}"}"),
                  AppInfoRow(label: U.s.checkInDate, value: x.checkInDate.toJalaliDate().toPersianNumber()),
                  AppInfoRow(label: U.s.checkOutDate, value: x.checkOutDate.toJalaliDate().toPersianNumber()),
                  AppInfoRow(label: U.s.guests, value: x.guestCount.toString().toPersianNumber()),
                  AppInfoRow(label: U.s.total, value: money(x.totalPrice)),
                  AppInfoRow(label: U.s.remaining, value: money(due), emphasize: true, valueColor: due > 0 ? scheme.error : null),
                  if (x.jsonData.notes != null) UTextBodySmall(x.jsonData.notes!, color: scheme.onSurfaceVariant).pOnly(top: 6),
                ],
              ),
            ).help("app.hotelBooking.summary"),
            const SizedBox(height: 12),
            if (manage)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  if (has(TagHotelReservation.pending)) UButton(title: U.s.confirm, icon: const Icon(Icons.check_rounded), onTap: () => _do(UServices.hotel.confirmHotelReservation(p: UIdParams(id: x.id)))),
                  if (has(TagHotelReservation.confirmed) || has(TagHotelReservation.pending))
                    UButton(title: U.s.checkIn, icon: const Icon(Icons.login_rounded), onTap: () => _do(UServices.hotel.checkInHotelReservation(p: UIdParams(id: x.id)))),
                  if (has(TagHotelReservation.checkedIn)) UButton(title: U.s.checkOut, icon: const Icon(Icons.logout_rounded), onTap: () => _do(UServices.hotel.checkOutHotelReservation(p: UIdParams(id: x.id)))),
                  if (has(TagHotelReservation.checkedIn) || has(TagHotelReservation.confirmed)) UButton(title: U.s.extendStay, type: UButtonType.outlined, onTap: _extend),
                  if (!has(TagHotelReservation.cancelled) && !has(TagHotelReservation.checkedOut)) UButton(title: U.s.addToBill, type: UButtonType.outlined, onTap: _charge),
                  if (has(TagHotelReservation.pending) || has(TagHotelReservation.confirmed))
                    UButton(
                      title: U.s.cancelBooking,
                      type: UButtonType.outlined,
                      foregroundColor: scheme.error,
                      onTap: () async {
                        if (await UNavigator.confirmAsync(title: U.s.cancelBooking, message: U.s.areYouSure, destructive: true)) await _do(UServices.hotel.cancelHotelReservation(p: UIdParams(id: x.id)));
                      },
                    ),
                ],
              ).help("app.hotelBooking.actions"),
            AppLabel(U.s.bill),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: UColumn(
                children: <Widget>[
                  for (final UHotelInvoiceResponse i in invoices)
                    AppTile(
                      icon: Icons.receipt_outlined,
                      title: "${i.jsonData.detail1 ?? (i.tags.contains(TagHotelInvoice.extra.number) ? U.s.extra : U.s.stay)} · ${money(i.debtAmount + i.penaltyAmount)}",
                      subtitle: i.paidAmount > 0 ? "${U.s.paid} ${money(i.paidAmount)}" : null,
                      trailing: AppStatusChip(status: AppStatus.hotelInvoice(i.tags, i.dueDate)),
                    ),
                ],
              ),
            ).help("app.hotelBooking.bill"),
          ],
        );
      },
    ),
  );
}

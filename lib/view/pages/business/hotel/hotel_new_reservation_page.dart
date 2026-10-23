import "package:khabroom/main.dart";
import "package:khabroom/utils/app_people.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// A booking taken at the desk or by phone: pick the dates, see which rooms are free and their price, then the guest.
class HotelNewReservationPage extends StatefulWidget {
  const HotelNewReservationPage({required this.hotelId, super.key});

  final String hotelId;

  @override
  State<HotelNewReservationPage> createState() => _HotelNewReservationPageState();
}

class _HotelNewReservationPageState extends State<HotelNewReservationPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController phone = TextEditingController();
  final TextEditingController name = TextEditingController();
  final TextEditingController guests = TextEditingController(text: "2");
  final TextEditingController notes = TextEditingController();
  DateTime checkIn = DateTime.now();
  DateTime checkOut = DateTime.now().add(const Duration(days: 1));
  List<UHotelRoomAvailabilityResponse> rooms = <UHotelRoomAvailabilityResponse>[];
  UHotelRoomAvailabilityResponse? picked;
  bool loading = false;
  bool busy = false;
  bool confirmed = true;

  @override
  void initState() {
    _search();
    super.initState();
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[phone, name, guests, notes]) c.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      loading = true;
      picked = null;
    });
    rooms = (await UServices.hotel.readHotelRoomAvailability(
      p: UHotelRoomAvailabilityParams(hotelId: widget.hotelId, checkInDate: checkIn, checkOutDate: checkOut, guestCount: int.tryParse(guests.numString()) ?? 1),
    )).$1?.result ?? <UHotelRoomAvailabilityResponse>[];
    if (mounted) setState(() => loading = false);
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (picked == null) {
      UToast.error(message: U.s.pickARoom);
      return;
    }
    setState(() => busy = true);
    final List<String> parts = name.text.trim().split(" ");
    final String? userId = await AppPeople.findOrCreate(phone: phone.text, firstName: parts.first, lastName: parts.length > 1 ? parts.sublist(1).join(" ") : null);
    if (userId == null) {
      setState(() => busy = false);
      return;
    }
    final bool ok = await appSend(
      UServices.hotel.createHotelReservation(
        p: UHotelReservationCreateParams(
          tags: <int>[confirmed ? TagHotelReservation.confirmed.number : TagHotelReservation.pending.number],
          checkInDate: checkIn,
          checkOutDate: checkOut,
          guestCount: int.tryParse(guests.numString()) ?? 1,
          userId: userId,
          roomId: picked!.room.id,
          totalPrice: picked!.totalPrice,
          guestName: name.valueOrNull(),
          guestPhone: phone.valueOrNull(),
          notes: notes.valueOrNull(),
        ),
      ),
    );
    if (ok) {
      UNavigator.back(true);
      return;
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UScaffold(
      appBar: AppBar(title: Text(U.s.newBooking).help("app.newBooking.page", inline: true), actions: const <Widget>[UHelpActions("app.newBooking.")]),
      body: Form(
        key: formKey,
        child: AppPageBody(
          maxWidth: AppResponsive.readableMaxWidth,
          children: <Widget>[
            AppSectionCard(
              title: U.s.when,
              icon: Icons.date_range_outlined,
              child: UColumn(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: <Widget>[
                  URow(
                    spacing: 10,
                    children: <Widget>[
                      Expanded(child: UTextFieldDatePicker(labelText: U.s.checkInDate, jalali: true, initialDate: checkIn, onChange: (DateTime d, _) {
                        checkIn = d;
                        if (!checkOut.isAfter(checkIn)) checkOut = checkIn.add(const Duration(days: 1));
                        _search();
                      })),
                      Expanded(child: UTextFieldDatePicker(labelText: U.s.checkOutDate, jalali: true, initialDate: checkOut, onChange: (DateTime d, _) {
                        checkOut = d;
                        _search();
                      })),
                    ],
                  ),
                  UTextField(controller: guests, labelText: U.s.guests, keyboardType: TextInputType.number, onFieldSubmitted: (_) => _search()),
                ],
              ),
            ).pOnly(bottom: 12),
            AppSectionCard(
              title: U.s.freeRooms,
              icon: Icons.king_bed_outlined,
              child: loading
                  ? const UProgressCircular(size: 28).alignAtCenter().pAll(20)
                  : rooms.where((UHotelRoomAvailabilityResponse x) => x.isBookable).isEmpty
                  ? UTextBodySmall(U.s.noRoomIsFreeForTheseDates, color: scheme.error, maxLines: 6)
                  : UColumn(
                      children: <Widget>[
                        for (final UHotelRoomAvailabilityResponse a in rooms.where((UHotelRoomAvailabilityResponse x) => x.isBookable))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            onTap: () => setState(() => picked = a),
                            leading: Icon(picked?.room.id == a.room.id ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: scheme.primary),
                            title: Text(a.room.title),
                            subtitle: Text("${a.availableQuantity.toString().toPersianNumber()} ${U.s.free} · ${a.nightCount.toString().toPersianNumber()} ${U.s.nights}"),
                            trailing: UTextTitleSmall(money(a.totalPrice)),
                          ),
                      ],
                    ),
            ).help("app.newBooking.rooms").pOnly(bottom: 12),
            AppSectionCard(
              title: U.s.guest,
              icon: Icons.person_outline_rounded,
              child: UColumn(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: <Widget>[
                  UTextField(controller: name, labelText: U.s.fullName, validator: UValidators.required<String>()),
                  UTextField(controller: phone, labelText: U.s.phoneNumber, keyboardType: TextInputType.phone, validator: UValidators.iranianPhone()),
                  UTextField(controller: notes, labelText: U.s.notes),
                  SwitchListTile(contentPadding: EdgeInsets.zero, value: confirmed, onChanged: (bool v) => setState(() => confirmed = v), title: Text(U.s.confirmedRightAway)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            UButton(title: picked == null ? U.s.saveBooking : "${U.s.saveBooking} · ${money(picked!.totalPrice)}", isLoading: busy, onTap: busy ? null : _save),
          ],
        ),
      ),
    );
  }
}

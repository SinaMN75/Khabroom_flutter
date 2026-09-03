import "package:u/utilities.dart";

class HotelDetailController extends UBaseController {
  final RxState hotelDetailState = RxState();
  final RxState availabilityState = RxState();

  late String hotelId;
  UHotelResponse? hotel;
  List<UHotelRoomAvailabilityResponse> availability = <UHotelRoomAvailabilityResponse>[];

  final Rxn<DateTime> checkInDate = Rxn<DateTime>();
  final Rxn<DateTime> checkOutDate = Rxn<DateTime>();
  final RxInt guestCount = 1.obs;
  final TextEditingController controllerCheckIn = TextEditingController();
  final TextEditingController controllerCheckOut = TextEditingController();

  bool get hasDates => checkInDate.value != null && checkOutDate.value != null;

  int get nightCount => hasDates ? checkOutDate.value!.difference(checkInDate.value!).inDays : 0;

  Future<void> init({required String hotelId}) async {
    this.hotelId = hotelId;
    final DateTime today = DateTime.now();
    checkInDate(DateTime(today.year, today.month, today.day).add(const Duration(days: 1)));
    checkOutDate(checkInDate.value!.add(const Duration(days: 1)));
    controllerCheckIn.text = checkInDate.value!.toJalaliDate();
    controllerCheckOut.text = checkOutDate.value!.toJalaliDate();
    await readHotel();
    await readAvailability();
  }

  Future<void> readHotel() async {
    hotelDetailState.loading();
    await UServices.hotel.readHotelById(
      p: UIdParams(
        id: hotelId,
        selectorArgs: const HotelSelectorArgs(
          media: MediaSelectorArgs(),
          rooms: HotelRoomSelectorArgs(media: MediaSelectorArgs()),
          comments: CommentSelectorArgs(user: UserSelectorArgs()),
        ),
      ),
      onOk: (UResponse<UHotelResponse> response) {
        hotel = response.result;
        hotelDetailState.loaded();
      },
      onError: (UEmptyResponse response) => hotelDetailState.error(),
      onException: (String exception) => hotelDetailState.error(),
    );
  }

  Future<void> readAvailability() async {
    if (!hasDates) return;
    availabilityState.loading();
    await UServices.hotel.readHotelRoomAvailability(
      p: UHotelRoomAvailabilityParams(
        hotelId: hotelId,
        checkInDate: checkInDate.value!,
        checkOutDate: checkOutDate.value!,
        guestCount: guestCount.value,
        selectorArgs: const HotelRoomSelectorArgs(media: MediaSelectorArgs()),
      ),
      onOk: (UResponse<List<UHotelRoomAvailabilityResponse>> response) {
        availability = response.result ?? <UHotelRoomAvailabilityResponse>[];
        availability.isEmpty ? availabilityState.emptying() : availabilityState.loaded();
      },
      onError: (UEmptyResponse response) => availabilityState.error(),
      onException: (String exception) => availabilityState.error(),
    );
  }

  Future<void> setCheckIn(DateTime date) async {
    checkInDate(DateTime(date.year, date.month, date.day));
    controllerCheckIn.text = checkInDate.value!.toJalaliDate();
    if (!checkOutDate.value!.isAfter(checkInDate.value!)) {
      checkOutDate(checkInDate.value!.add(const Duration(days: 1)));
      controllerCheckOut.text = checkOutDate.value!.toJalaliDate();
    }
    await readAvailability();
  }

  Future<void> setCheckOut(DateTime date) async {
    final DateTime picked = DateTime(date.year, date.month, date.day);
    if (!picked.isAfter(checkInDate.value!)) {
      UToast.error(message: U.s.thisFieldIsInvalid);
      return;
    }
    checkOutDate(picked);
    controllerCheckOut.text = picked.toJalaliDate();
    await readAvailability();
  }

  Future<void> changeGuestCount(int value) async {
    if (value < 1) return;
    guestCount(value);
    await readAvailability();
  }
}

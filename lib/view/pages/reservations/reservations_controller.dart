import "package:u/utilities.dart";

class ReservationsController extends UBaseController {
  final URxState reservationState = URxState();
  final URxInt selectedTab = 0.obs;

  List<UHotelReservationResponse> reservations = <UHotelReservationResponse>[];

  List<UHotelReservationResponse> get upcoming => reservations
      .where((UHotelReservationResponse i) => !i.tags.contains(TagHotelReservation.cancelled.number) && i.checkOutDate.isAfter(DateTime.now()))
      .toList();

  List<UHotelReservationResponse> get past => reservations
      .where((UHotelReservationResponse i) => i.tags.contains(TagHotelReservation.cancelled.number) || !i.checkOutDate.isAfter(DateTime.now()))
      .toList();

  Future<void> read() async {
    reservationState.loading();
    await UServices.hotel.readHotelReservations(
      p: UHotelReservationReadParams(
        userId: U.user.id,
        pageSize: 50,
        selectorArgs: const UHotelReservationSelectorArgs(
          hotel: UHotelSelectorArgs(media: UMediaSelectorArgs()),
          room: UHotelRoomSelectorArgs(),
          invoice: UHotelInvoiceSelectorArgs(),
        ),
      ),
      onOk: (UResponse<List<UHotelReservationResponse>> response) {
        reservations = (response.result ?? <UHotelReservationResponse>[])..sort((UHotelReservationResponse a, UHotelReservationResponse b) => b.checkInDate.compareTo(a.checkInDate));
        reservations.isEmpty ? reservationState.emptying() : reservationState.loaded();
      },
      onError: (UResponse<dynamic> response) => reservationState.error(),
      onException: (String exception) => reservationState.error(),
    );
  }
}

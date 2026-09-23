import "package:u/utilities.dart";

class HomeController extends UBaseController {
  final URxState hotelState = URxState();
  final URxState dormState = URxState();
  final URxState stayState = URxState();

  List<UHotelResponse> hotels = <UHotelResponse>[];
  List<UDormResponse> dorms = <UDormResponse>[];
  List<UHotelReservationResponse> upcomingReservations = <UHotelReservationResponse>[];
  List<UDormBedInvoiceResponse> unpaidInvoices = <UDormBedInvoiceResponse>[];

  // Tags picked in the filter chips above each list. The backend returns only the places that have all of them.
  final List<int> hotelFilters = <int>[];
  final List<int> dormFilters = <int>[];

  Future<void> init() async {
    await Future.wait(<Future<void>>[readHotels(), readDorms(), readMyStay()]);
  }

  Future<void> readHotels() async {
    hotelState.loading();
    await UServices.hotel.readHotels(
      p: UHotelReadParams(
        pageSize: 20,
        tags: hotelFilters,
        selectorArgs: const UHotelSelectorArgs(media: UMediaSelectorArgs(), rooms: UHotelRoomSelectorArgs(media: UMediaSelectorArgs())),
      ),
      onOk: (UResponse<List<UHotelResponse>> response) {
        hotels = response.result ?? <UHotelResponse>[];
        hotels.isEmpty ? hotelState.emptying() : hotelState.loaded();
      },
      onError: (UEmptyResponse response) => hotelState.error(),
      onException: (String exception) => hotelState.error(),
    );
  }

  Future<void> readDorms() async {
    dormState.loading();
    await UServices.hotel.readDorms(
      p: UDormReadParams(
        pageSize: 20,
        tags: dormFilters,
        selectorArgs: const UDormSelectorArgs(media: UMediaSelectorArgs(), beds: UDormBedSelectorArgs()),
      ),
      onOk: (UResponse<List<UDormResponse>> response) {
        dorms = response.result ?? <UDormResponse>[];
        dorms.isEmpty ? dormState.emptying() : dormState.loaded();
      },
      onError: (UEmptyResponse response) => dormState.error(),
      onException: (String exception) => dormState.error(),
    );
  }

  /// The one card at the top of the home page: the next stay, or the invoice that needs paying.
  Future<void> readMyStay() async {
    stayState.loading();
    await UServices.hotel.readHotelReservations(
      p: UHotelReservationReadParams(
        userId: U.user.id,
        pageSize: 5,
        selectorArgs: const UHotelReservationSelectorArgs(hotel: UHotelSelectorArgs(media: UMediaSelectorArgs()), room: UHotelRoomSelectorArgs(), invoice: UHotelInvoiceSelectorArgs()),
      ),
      onOk: (UResponse<List<UHotelReservationResponse>> response) async {
        final DateTime now = DateTime.now();
        upcomingReservations = (response.result ?? <UHotelReservationResponse>[])
            .where((UHotelReservationResponse i) => !i.tags.contains(TagHotelReservation.cancelled.number) && i.checkOutDate.isAfter(now))
            .toList();
        await _readUnpaidDormInvoices();
      },
      onError: (UResponse<dynamic> response) => stayState.error(),
      onException: (String exception) => stayState.error(),
    );
  }

  Future<void> _readUnpaidDormInvoices() async {
    await UServices.hotel.readDormBedInvoice(
      p: UDormBedInvoiceReadParams(
        pageSize: 20,
        isPaid: false,
        selectorArgs: const UDormBedInvoiceSelectorArgs(contract: UDormBedContractSelectorArgs(bed: UDormBedSelectorArgs(room: UDormRoomSelectorArgs(dorm: UDormSelectorArgs())))),
      ),
      onOk: (UResponse<List<UDormBedInvoiceResponse>> response) {
        unpaidInvoices = (response.result ?? <UDormBedInvoiceResponse>[]).where((UDormBedInvoiceResponse i) => i.tags.contains(TagDormBedInvoice.notPaid.number)).toList()
          ..sort((UDormBedInvoiceResponse a, UDormBedInvoiceResponse b) => a.dueDate.compareTo(b.dueDate));
        stayState.loaded();
      },
      onError: (UResponse<dynamic> response) => stayState.loaded(),
      onException: (String exception) => stayState.loaded(),
    );
  }
}

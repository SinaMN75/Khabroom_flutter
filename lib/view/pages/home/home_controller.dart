import "package:u/utilities.dart";

class HomeController extends UBaseController {
  final RxState hotelState = RxState();
  final RxState dormState = RxState();
  final RxState stayState = RxState();

  List<UHotelResponse> hotels = <UHotelResponse>[];
  List<UDormResponse> dorms = <UDormResponse>[];
  List<UHotelReservationResponse> upcomingReservations = <UHotelReservationResponse>[];
  List<UDormBedInvoiceResponse> unpaidInvoices = <UDormBedInvoiceResponse>[];

  Future<void> init() async {
    await Future.wait(<Future<void>>[readHotels(), readDorms(), readMyStay()]);
  }

  Future<void> readHotels() async {
    hotelState.loading();
    await UServices.hotel.readHotels(
      p: UHotelReadParams(
        pageSize: 20,
        selectorArgs: const HotelSelectorArgs(media: MediaSelectorArgs(), rooms: HotelRoomSelectorArgs(media: MediaSelectorArgs())),
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
        selectorArgs: const DormSelectorArgs(media: MediaSelectorArgs(), beds: DormBedSelectorArgs()),
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
        selectorArgs: const HotelReservationSelectorArgs(hotel: HotelSelectorArgs(media: MediaSelectorArgs()), room: HotelRoomSelectorArgs(), invoice: HotelInvoiceSelectorArgs()),
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
        selectorArgs: const InvoiceSelectorArgs(contract: ContractSelectorArgs(bed: DormBedSelectorArgs(room: DormRoomSelectorArgs(dorm: DormSelectorArgs())))),
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

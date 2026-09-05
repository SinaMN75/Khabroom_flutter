import "package:u/utilities.dart";

class ReservationDetailController extends UBaseController {
  final RxState detailState = RxState();

  late String reservationId;
  UHotelReservationResponse? reservation;

  UHotelInvoiceResponse? get invoice => (reservation?.invoices ?? <UHotelInvoiceResponse>[]).firstOrDefault();

  bool get isUnpaid => invoice != null && invoice!.tags.contains(TagHotelInvoice.notPaid.number);

  bool get canCancel =>
      reservation != null &&
      !reservation!.tags.contains(TagHotelReservation.cancelled.number) &&
      !reservation!.tags.contains(TagHotelReservation.checkedIn.number) &&
      !reservation!.tags.contains(TagHotelReservation.checkedOut.number);

  Future<void> init({required String reservationId}) async {
    this.reservationId = reservationId;
    await read();
  }

  Future<void> read() async {
    detailState.loading();
    await UServices.hotel.readHotelReservationById(
      p: UIdParams(
        id: reservationId,
        selectorArgs: const HotelReservationSelectorArgs(
          hotel: HotelSelectorArgs(media: MediaSelectorArgs()),
          room: HotelRoomSelectorArgs(),
          invoice: HotelInvoiceSelectorArgs(),
        ),
      ),
      onOk: (UResponse<UHotelReservationResponse> response) {
        reservation = response.result;
        detailState.loaded();
      },
      onError: (UResponse<dynamic> response) => detailState.error(),
      onException: (String exception) => detailState.error(),
    );
  }

  Future<void> payFromWallet() async {
    if (invoice == null) return;
    ULoading.show();
    await UServices.hotel.payHotelInvoice(
      p: UIdParams(id: invoice!.id),
      onOk: (UEmptyResponse response) async {
        ULoading.dismiss();
        UToast.success(message: response.message);
        await read();
      },
      onError: (UResponse<dynamic> response) {
        ULoading.dismiss();
        UToast.error(message: response.message);
      },
      onException: (String exception) {
        ULoading.dismiss();
        UToast.error(message: exception);
      },
    );
  }

  Future<void> payWithGateway() async {
    if (invoice == null) return;
    final bool paid = await UIpgFlow.pay(
      amount: invoice!.debtAmount + invoice!.penaltyAmount - invoice!.creditorAmount,
      tag: TagTxn.hotelInvoice,
      invoiceId: invoice!.id,
    );
    if (paid) await read();
  }

  Future<void> cancel() async {
    final bool confirmed = await UNavigator.confirmAsync(title: U.s.cancelReservation, message: U.s.cancelBeforeTheFreeWindowEndsAndTheFullAmountGoesBackToYourWallet, destructive: true);
    if (!confirmed) return;

    ULoading.show();
    await UServices.hotel.cancelHotelReservationByUser(
      p: UHotelReservationCancelParams(id: reservationId),
      onOk: (UEmptyResponse response) async {
        ULoading.dismiss();
        UToast.success(message: response.message);
        await read();
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
}

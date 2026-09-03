import "package:u/utilities.dart";

class GuestForm {
  GuestForm({String? fullName, String? nationalCode})
    : controllerName = TextEditingController(text: fullName ?? ""),
      controllerNationalCode = TextEditingController(text: nationalCode ?? "");

  final TextEditingController controllerName;
  final TextEditingController controllerNationalCode;
}

class BookingController extends UBaseController {
  final RxState walletState = RxState();
  final RxList<GuestForm> guests = RxList<GuestForm>();
  final RxBool useWallet = true.obs;
  final TextEditingController controllerNotes = TextEditingController();

  double walletBalance = 0;

  void init({required int guestCount}) {
    guests.value = <GuestForm>[
      GuestForm(fullName: "${U.user.firstName ?? ""} ${U.user.lastName ?? ""}".trim(), nationalCode: U.user.nationalCode),
      for (int i = 1; i < guestCount; i++) GuestForm(),
    ];
    readWallet();
  }

  Future<void> readWallet() async {
    walletState.loading();
    await UServices.wallet.readByUserId(
      p: UIdParams(id: U.user.id),
      onOk: (UResponse<List<UWalletResponse>> response) {
        walletBalance = response.result.primary().balance;
        walletState.loaded();
      },
      onError: (UEmptyResponse response) => walletState.error(),
      onException: (String exception) => walletState.error(),
    );
  }

  bool canPayFromWallet(double amount) => walletState.isLoaded() && walletBalance >= amount;

  List<UReservationGuestParams> guestParams() => <UReservationGuestParams>[
    for (final GuestForm form in guests)
      if (form.controllerName.text.trim().isNotEmpty)
        UReservationGuestParams(
          fullName: form.controllerName.text.trim(),
          nationalCode: form.controllerNationalCode.numString().isEmpty ? null : form.controllerNationalCode.numString(),
        ),
  ];
}

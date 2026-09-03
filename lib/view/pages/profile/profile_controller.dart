import "package:khabroom/view/pages/splash/splash_page.dart";
import "package:u/utilities.dart";

class ProfileController extends UBaseController {
  final RxState walletState = RxState();
  double walletBalance = 0;

  Future<void> init() async {
    await readWallet();
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

  Future<void> logout() async {
    final bool confirmed = await UNavigator.confirmAsync(title: U.s.logout, message: U.s.areYouSure, destructive: true);
    if (!confirmed) return;
    await ULocalStorage.clear();
    await UFileStorage.clear();
    await UNavigator.offAll(const SplashPage());
  }
}

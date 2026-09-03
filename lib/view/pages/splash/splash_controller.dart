import "package:khabroom/view/pages/login/login_mobile/login_mobile_page.dart";
import "package:khabroom/view/pages/main/main_page.dart";
import "package:u/utilities.dart";

class SplashController extends UBaseController {
  Future<void> init() async => delay(900, () async {
    if (!ULocalStorage.hasToken()) {
      await UNavigator.offAll(const LoginMobilePage());
      return;
    }
    await UServices.user.readById(
      p: UIdParams(
        id: ULocalStorage.getUserId() ?? "",
        selectorArgs: const UserSelectorArgs(wallet: WalletSelectorArgs()),
      ),
      onOk: (UResponse<UUserResponse> response) async {
        U.user = response.result!;
        await UNavigator.offAll(const MainPage());
      },
      onError: (UEmptyResponse response) {
        UToast.error(message: response.message);
        UNavigator.offAll(const LoginMobilePage());
      },
      onException: (String response) {
        UToast.error(message: response);
        UNavigator.offAll(const LoginMobilePage());
      },
    );
  });
}

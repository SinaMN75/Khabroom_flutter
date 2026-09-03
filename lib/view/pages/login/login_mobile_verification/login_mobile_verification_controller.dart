import "package:khabroom/view/pages/splash/splash_page.dart";
import "package:u/utilities.dart";

class LoginMobileVerificationController {
  late String mobile;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController controllerOtp = TextEditingController();

  void init({required String mobile}) {
    this.mobile = mobile;
  }

  Future<void> submit() async => UValidators.validateForm(
    key: formKey,
    action: () {
      if (controllerOtp.text.length < 6) {
        UToast.error(message: U.s.theEnteredVerificationCodeIsIncorrect);
        return;
      }
      ULoading.show();
      UServices.auth.verifyCodeForLogin(
        p: UVerifyMobileForLoginParams(
          phoneNumber: UPhoneNumberUtils.normalizePhone(mobile, countryCode: "98"),
          otp: controllerOtp.numString(),
        ),
        onOk: (UResponse<ULoginResponse> response) async {
          U.user = response.result!.user;
          ULoading.dismiss();
          await UNavigator.offAll(const SplashPage());
        },
        onError: (UEmptyResponse response) {
          ULoading.dismiss();
          UToast.error(message: response.message);
        },
        onException: (String response) {
          ULoading.dismiss();
          UToast.error(message: response);
        },
      );
    },
  );

  void sendAgain() {
    ULoading.show();
    UServices.auth.getVerificationCodeForLogin(
      p: UGetMobileVerificationCodeForLoginParams(phoneNumber: UPhoneNumberUtils.normalizePhone(mobile, countryCode: "98")),
      onOk: (UEmptyResponse response) {
        ULoading.dismiss();
        controllerOtp.clear();
        UToast.snackBar(message: response.message);
      },
      onError: (UEmptyResponse response) {
        ULoading.dismiss();
        UToast.error(message: response.message);
      },
      onException: (String response) {
        ULoading.dismiss();
        UToast.error(message: response);
      },
    );
  }
}

import "package:khabroom/view/pages/login/login_mobile_verification/login_mobile_verification_page.dart";
import "package:u/utilities.dart";

class LoginMobileController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController controllerMobile = TextEditingController(text: kDebugMode ? "09351902721" : "");

  Future<void> submit() async => UValidators.validateForm(
    key: formKey,
    action: () {
      ULoading.show();
      UServices.auth.getVerificationCodeForLogin(
        p: UGetMobileVerificationCodeForLoginParams(
          phoneNumber: UPhoneNumberUtils.normalizePhone(controllerMobile.text, countryCode: "98"),
        ),
        onOk: (UEmptyResponse response) {
          ULoading.dismiss();
          UToast.snackBar(message: response.message);
          UNavigator.push(LoginMobileVerificationPage(mobile: controllerMobile.text));
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
}

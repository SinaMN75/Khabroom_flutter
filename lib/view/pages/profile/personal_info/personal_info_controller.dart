import "package:u/utilities.dart";

class PersonalInfoController extends UBaseController {
  final TextEditingController controllerFirstName = TextEditingController(text: U.user.firstName ?? "");
  final TextEditingController controllerLastName = TextEditingController(text: U.user.lastName ?? "");
  final TextEditingController controllerNationalCode = TextEditingController(text: U.user.nationalCode ?? "");
  final TextEditingController controllerEmail = TextEditingController(text: U.user.email ?? "");

  void submit() => UValidators.validateForm(
    key: formKey,
    action: () {
      ULoading.show();
      UServices.user.update(
        p: UUserUpdateParams(
          id: U.user.id,
          firstName: controllerFirstName.text.trim(),
          lastName: controllerLastName.text.trim(),
          nationalCode: controllerNationalCode.numString(),
          email: controllerEmail.text.trim().isEmpty ? null : controllerEmail.text.trim(),
        ),
        onOk: (UEmptyResponse response) async {
          final (UResponse<UUserResponse>? ok, _, _) = await UServices.user.readById(p: UIdParams(id: U.user.id, selectorArgs: const UUserSelectorArgs(wallet: UWalletSelectorArgs())));
          if (ok?.result != null) U.user = ok!.result!;
          ULoading.dismiss();
          UToast.success(message: U.s.changesSaved);
          UNavigator.back();
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
    },
  );
}

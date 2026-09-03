import "package:khabroom/view/pages/login/login_mobile/login_mobile_controller.dart";
import "package:khabroom/view/widgets/widgets.dart";
import "package:u/utilities.dart";

class LoginMobilePage extends StatefulWidget {
  const LoginMobilePage({super.key});

  @override
  State<LoginMobilePage> createState() => _LoginMobilePageState();
}

class _LoginMobilePageState extends State<LoginMobilePage> {
  final LoginMobileController c = LoginMobileController();

  @override
  Widget build(BuildContext context) => UScaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppAuthHeader(
            title: U.s.loginToYourAccount,
            subtitle: U.s.pleaseEnterYourMobileNumberToLogIn,
          ).fadeSlideIn(),
          const SizedBox(height: 28),
          Form(
            key: c.formKey,
            child: UColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                UTextField(
                  labelText: U.s.mobileNumber,
                  controller: c.controllerMobile,
                  keyboardType: TextInputType.phone,
                  maxLength: 14,
                  autoFillHints: const <String>[AutofillHints.telephoneNumber],
                  validator: UValidators.number(minLength: 10, maxLength: 14),
                ).ltr().fadeSlideIn(milliseconds: 200),
                const SizedBox(height: 16),
                UButton(
                  title: U.s.continueWord,
                  fullWidth: true,
                  onTap: c.submit,
                ).fadeSlideIn(milliseconds: 400),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const AppLegalNote().fadeSlideIn(milliseconds: 600),
        ],
      ),
    ),
  );
}

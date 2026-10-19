import "package:khabroom/main.dart";
import "package:khabroom/utils/app_session.dart";
import "package:khabroom/view/widgets/widgets.dart";
import "package:u/utilities.dart";

/// Sign-in that opens over the current page; returns true once the user is signed in so the action they wanted can run.
class LoginSheet extends StatefulWidget {
  const LoginSheet({super.key});

  static Future<bool> show() async => await UNavigator.bottomSheet<bool>(const LoginSheet(), showDragHandle: true) ?? false;

  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController phone = TextEditingController(text: kDebugMode ? "09351902721" : "");
  final TextEditingController otp = TextEditingController();
  bool codeSent = false;
  bool busy = false;

  String get _normalized => UPhoneNumberUtils.normalizePhone(phone.text, countryCode: "98");

  @override
  void dispose() {
    phone.dispose();
    otp.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => busy = true);
    final (UEmptyResponse? ok, UEmptyResponse? error, String? exception) = await UServices.auth.getVerificationCodeForLogin(p: UGetMobileVerificationCodeForLoginParams(phoneNumber: _normalized));
    if (!mounted) return;
    setState(() {
      busy = false;
      codeSent = ok != null;
    });
    if (ok == null) UToast.error(message: error?.message ?? exception ?? U.s.error);
  }

  Future<void> _verify() async {
    if (otp.numString().length < 6) {
      UToast.error(message: U.s.theEnteredVerificationCodeIsIncorrect);
      return;
    }
    setState(() => busy = true);
    final (UResponse<ULoginResponse>? ok, UEmptyResponse? error, String? exception) = await UServices.auth.verifyCodeForLogin(
      p: UVerifyMobileForLoginParams(phoneNumber: _normalized, otp: otp.numString()),
    );
    if (ok?.result == null) {
      if (mounted) setState(() => busy = false);
      UToast.error(message: error?.message ?? exception ?? U.s.error);
      return;
    }
    U.user = ok!.result!.user;
    await AppSession.load();
    if (mounted) UNavigator.back(true);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: UColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const AppBrandMark().alignAtCenter(),
            const SizedBox(height: 14),
            UTextHeadlineSmall(codeSent ? U.s.enterTheCode : U.s.signInToContinue, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            UTextBodySmall(
              codeSent ? "${U.s.weSentACodeTo} ${phone.text.toPersianNumber()}" : U.s.signInWithYourPhoneNumberNoPasswordNeeded,
              color: scheme.onSurfaceVariant,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (!codeSent)
              UTextField(
                controller: phone,
                labelText: U.s.phoneNumber,
                keyboardType: TextInputType.phone,
                validator: UValidators.iranianPhone(),
              ).help("app.login.phone")
            else ...<Widget>[
              UOtpField(controller: otp, autoFocus: true, onCompleted: (_) => _verify()).alignAtCenter(),
              UButton(title: U.s.editPhoneNumber, type: UButtonType.text, onTap: () => setState(() => codeSent = false)),
            ],
            const SizedBox(height: 16),
            UButton(title: codeSent ? U.s.signIn : U.s.getCode, isLoading: busy, onTap: busy ? null : (codeSent ? _verify : _send)),
            const SizedBox(height: 10),
            GestureDetector(onTap: () => ULaunch.url(AppConstants.termsUrl), child: UTextBodySmall(U.s.bySigningInYouAcceptTheTerms, color: scheme.onSurfaceVariant, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}

import "package:khabroom/view/pages/login/login_mobile_verification/login_mobile_verification_controller.dart";
import "package:khabroom/view/widgets/widgets.dart";
import "package:u/utilities.dart";

class LoginMobileVerificationPage extends StatefulWidget {
  const LoginMobileVerificationPage({required this.mobile, super.key});

  final String mobile;

  @override
  State<LoginMobileVerificationPage> createState() => _LoginMobileVerificationPageState();
}

class _LoginMobileVerificationPageState extends State<LoginMobileVerificationPage> {
  final LoginMobileVerificationController c = LoginMobileVerificationController();

  @override
  void initState() {
    c.init(mobile: widget.mobile);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UScaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: UColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppAuthHeader(
              title: U.s.verificationCode,
              subtitle: U.s.weSentAVerificationCodeToThisNumber,
              trailing: UContainer(
                radius: 10,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                color: scheme.primaryContainer,
                child: UTextTitleSmall(widget.mobile.toPersianNumber(), color: scheme.onPrimaryContainer, textDirection: TextDirection.ltr),
              ),
            ).fadeSlideIn(),
            const SizedBox(height: 28),
            Form(
              key: c.formKey,
              child: UColumn(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  UOtpField(controller: c.controllerOtp).alignAtCenter().fadeSlideIn(milliseconds: 200),
                  const SizedBox(height: 20),
                  UButton(
                    title: U.s.confirmAndContinue,
                    fullWidth: true,
                    onTap: c.submit,
                  ).fadeSlideIn(milliseconds: 400),
                  const SizedBox(height: 4),
                  URow(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      UButton(
                        type: UButtonType.text,
                        counter: 60,
                        counterResetCounterOnTap: true,
                        title: U.s.resend,
                        onTap: c.sendAgain,
                      ),
                      UButton(
                        type: UButtonType.text,
                        title: U.s.changeMobileNumber,
                        textStyle: TextStyle(fontFamily: UFonts.vazir.fontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
                        onTap: () => UNavigator.back(),
                      ),
                    ],
                  ).fadeSlideIn(milliseconds: 600),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import "package:khabroom/view/pages/splash/splash_controller.dart";
import "package:khabroom/view/widgets/widgets.dart";
import "package:u/utilities.dart";

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final SplashController c = SplashController();

  @override
  void initState() {
    c.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    alignment: Alignment.center,
    body: const AppBrandMark(size: 96).fadeSlideIn(),
  );
}

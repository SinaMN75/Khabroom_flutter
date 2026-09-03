import "package:u/utilities.dart";

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.accommodation)),
    alignment: Alignment.center,
    body: UEmptyState(title: U.s.welcome),
  );
}

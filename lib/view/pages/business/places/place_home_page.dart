import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/pages/business/dorm/dorm_home_page.dart";
import "package:khabroom/view/pages/business/hotel/hotel_home_page.dart";
import "package:u/utilities.dart";

/// Opens a place in its own colour: a dorm or hotel home.
class PlaceHomePage extends StatelessWidget {
  const PlaceHomePage({required this.place, super.key});

  final AppPlace place;

  @override
  Widget build(BuildContext context) => Theme(
    data: place.kind.theme(context),
    child: switch (place.kind) {
      AppKind.dorm => DormHomePage(place: place),
      AppKind.hotel => HotelHomePage(place: place),
    },
  );
}

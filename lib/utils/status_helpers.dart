import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// Maps backend tags to the label and colour the user sees, so every screen agrees.
abstract class AppStatus {
  static (String, AppTone) reservation(List<int> tags) {
    if (tags.contains(TagHotelReservation.cancelled.number)) return (U.s.cancelled, AppTone.danger);
    if (tags.contains(TagHotelReservation.noShow.number)) return (U.s.noShow, AppTone.danger);
    if (tags.contains(TagHotelReservation.checkedOut.number)) return (U.s.checkedOut, AppTone.neutral);
    if (tags.contains(TagHotelReservation.checkedIn.number)) return (U.s.checkedIn, AppTone.positive);
    if (tags.contains(TagHotelReservation.confirmed.number)) return (U.s.confirmed, AppTone.positive);
    return (U.s.pending, AppTone.warning);
  }

  static (String, AppTone) hotelInvoice(List<int> tags, DateTime dueDate) {
    if (tags.contains(TagHotelInvoice.refunded.number)) return (U.s.refundAmount, AppTone.neutral);
    if (!tags.contains(TagHotelInvoice.notPaid.number)) return (U.s.paid, AppTone.positive);
    if (dueDate.isBefore(DateTime.now())) return (U.s.overdue, AppTone.danger);
    return (U.s.notPaid, AppTone.warning);
  }

  static (String, AppTone) dormInvoice(List<int> tags, DateTime dueDate) {
    if (!tags.contains(TagDormBedInvoice.notPaid.number)) return (U.s.paid, AppTone.positive);
    if (dueDate.isBefore(DateTime.now())) return (U.s.overdue, AppTone.danger);
    return (U.s.notPaid, AppTone.warning);
  }
}

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({required this.status, super.key});

  final (String, AppTone) status;

  @override
  Widget build(BuildContext context) => AppChip(label: status.$1, tone: status.$2);
}

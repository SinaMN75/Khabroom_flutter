import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:u/utilities.dart";

/// Records money received in person (cash, card machine or transfer) into one of the business's cash boxes or bank accounts.
abstract class ReceiveSheet {
  static Future<bool> show({required String title, required double due, required Future<(dynamic, dynamic, String?)> Function(UInvoiceReceiveParams p) receive, required String id}) async {
    final List<UAccountResponse> boxes = ((await UServices.accounting.readAccounts(p: UAccountReadParams(organizationId: AppWorkspace.org.id))).$1?.result ?? <UAccountResponse>[])
        .where((UAccountResponse a) => a.isMoneyBox)
        .toList();
    final TextEditingController amount = TextEditingController(text: rialToTomanText(due));
    String? accountId = boxes.firstOrNull?.id;
    return AppForm.show(
      title: title,
      help: "app.receive.page",
      submitTitle: U.s.recordPayment,
      onSubmit: () => appSend(receive(UInvoiceReceiveParams(id: id, amount: tomanToRial(amount), accountId: accountId))),
      children: (BuildContext context, StateSetter setState) => <Widget>[
        AppMoneyField(controller: amount, label: U.s.amount),
        if (boxes.isNotEmpty)
          UDropDownField<String?>(
            labelText: U.s.receivedInto,
            initialValue: accountId,
            items: <DropdownMenuItem<String?>>[for (final UAccountResponse a in boxes) DropdownMenuItem<String?>(value: a.id, child: Text(a.title))],
            onChanged: (String? v) => setState(() => accountId = v),
          ).help("app.receive.box"),
      ],
    );
  }
}

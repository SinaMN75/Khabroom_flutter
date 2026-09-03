import "package:u/utilities.dart";

class MyContractsController extends UBaseController {
  final RxState contractState = RxState();

  List<UDormBedContractResponse> contracts = <UDormBedContractResponse>[];
  Map<String, List<UDormBedInvoiceResponse>> invoicesByContract = <String, List<UDormBedInvoiceResponse>>{};

  Future<void> read() async {
    contractState.loading();
    await UServices.hotel.readDormBedContract(
      p: UDormBedContractReadParams(
        userId: U.user.id,
        pageSize: 30,
        selectorArgs: const ContractSelectorArgs(bed: DormBedSelectorArgs(room: DormRoomSelectorArgs(dorm: DormSelectorArgs()))),
      ),
      onOk: (UResponse<List<UDormBedContractResponse>> response) async {
        contracts = response.result ?? <UDormBedContractResponse>[];
        if (contracts.isEmpty) {
          contractState.emptying();
          return;
        }
        await _readInvoices();
      },
      onError: (UResponse<dynamic> response) => contractState.error(),
      onException: (String exception) => contractState.error(),
    );
  }

  Future<void> _readInvoices() async {
    await UServices.hotel.readDormBedInvoice(
      p: UDormBedInvoiceReadParams(
        userId: U.user.id,
        pageSize: 200,
        selectorArgs: const InvoiceSelectorArgs(contract: ContractSelectorArgs()),
      ),
      onOk: (UResponse<List<UDormBedInvoiceResponse>> response) {
        invoicesByContract = <String, List<UDormBedInvoiceResponse>>{};
        for (final UDormBedInvoiceResponse invoice in response.result ?? <UDormBedInvoiceResponse>[]) {
          final String? contractId = invoice.contract?.id;
          if (contractId == null) continue;
          invoicesByContract.putIfAbsent(contractId, () => <UDormBedInvoiceResponse>[]).add(invoice);
        }
        for (final List<UDormBedInvoiceResponse> list in invoicesByContract.values)
          list.sort((UDormBedInvoiceResponse a, UDormBedInvoiceResponse b) => a.dueDate.compareTo(b.dueDate));
        contractState.loaded();
      },
      onError: (UResponse<dynamic> response) => contractState.loaded(),
      onException: (String exception) => contractState.loaded(),
    );
  }

  Future<void> payFromWallet(UDormBedInvoiceResponse invoice) async {
    ULoading.show();
    await UServices.hotel.payDormBedInvoice(
      p: UIdParams(id: invoice.id),
      onOk: (UEmptyResponse response) async {
        ULoading.dismiss();
        UToast.success(message: response.message);
        await read();
      },
      onError: (UResponse<dynamic> response) {
        ULoading.dismiss();
        UToast.error(message: response.message);
      },
      onException: (String exception) {
        ULoading.dismiss();
        UToast.error(message: exception);
      },
    );
  }

  Future<void> payWithGateway(UDormBedInvoiceResponse invoice) async {
    final bool paid = await UIpgFlow.pay(
      amount: invoice.debtAmount + invoice.penaltyAmount - invoice.creditorAmount,
      tag: TagTxn.dormInvoice,
      invoiceId: invoice.id,
    );
    if (paid) await read();
  }
}

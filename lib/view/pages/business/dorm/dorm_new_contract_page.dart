import "package:khabroom/utils/app_people.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// A new resident: who, which bed, from when, and for how much. Bills are made automatically from the contract.
class DormNewContractPage extends StatefulWidget {
  const DormNewContractPage({required this.dormId, super.key, this.bed, this.userId, this.applicationId, this.start});

  final String dormId;
  final UDormBedResponse? bed;
  final String? userId;
  final String? applicationId;
  final DateTime? start;

  @override
  State<DormNewContractPage> createState() => _DormNewContractPageState();
}

class _DormNewContractPageState extends State<DormNewContractPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController phone = TextEditingController();
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController rent = TextEditingController();
  final TextEditingController deposit = TextEditingController();
  final TextEditingController penalty = TextEditingController(text: "1");
  final TextEditingController guardianName = TextEditingController();
  final TextEditingController guardianPhone = TextEditingController();
  List<UDormBedResponse> beds = <UDormBedResponse>[];
  UDormBedResponse? bed;
  UUserResponse? person;
  bool looked = false;
  TagDormBedContract type = TagDormBedContract.monthly;
  DateTime? start;
  DateTime? end;
  bool busy = false;

  @override
  void initState() {
    start = widget.start ?? DateTime.now();
    end = start!.add(const Duration(days: 180));
    _readBeds();
    super.initState();
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[phone, firstName, lastName, rent, deposit, penalty, guardianName, guardianPhone]) c.dispose();
    super.dispose();
  }

  Future<void> _readBeds() async {
    beds = ((await UServices.dorm.readDormBeds(
      p: UDormBedReadParams(dormId: widget.dormId, manage: true, pageSize: 300, pageNumber: 1, selectorArgs: const UDormBedSelectorArgs(room: UDormRoomSelectorArgs(), contract: UDormBedContractSelectorArgs())),
    )).$1?.result ?? <UDormBedResponse>[])
        .where((UDormBedResponse b) => b.id == widget.bed?.id || !(b.contracts ?? <UDormBedContractResponse>[]).any((UDormBedContractResponse x) => x.isActive && !x.tags.contains(TagDormBedContract.settled.number)))
        .toList();
    _pickBed(beds.where((UDormBedResponse b) => b.id == widget.bed?.id).firstOrNull ?? beds.firstOrNull);
  }

  void _pickBed(UDormBedResponse? b) {
    if (!mounted) return;
    setState(() {
      bed = b;
      rent.text = rialToTomanText(b?.monthlyRent);
      deposit.text = rialToTomanText(b?.deposit);
    });
  }

  Future<void> _lookup() async {
    if (phone.text.trim().length < 10) return;
    final UUserResponse? u = await AppPeople.find(phone.text);
    setState(() {
      person = u;
      looked = true;
    });
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (bed == null) {
      UToast.error(message: U.s.thereIsNoFreeBed);
      return;
    }
    setState(() => busy = true);
    final String? userId = widget.userId ?? person?.id ?? await AppPeople.findOrCreate(phone: phone.text, firstName: firstName.valueOrNull(), lastName: lastName.valueOrNull());
    if (userId == null) {
      setState(() => busy = false);
      return;
    }
    final bool ok = await appSend(
      UServices.dorm.createDormBedContract(
        p: UDormBedContractCreateParams(
          tags: <int>[type.number],
          startDate: start!,
          endDate: end!,
          userId: userId,
          bedId: bed!.id,
          rent: tomanToRial(rent),
          deposit: type == TagDormBedContract.daily ? null : tomanToRial(deposit),
          penaltyPrecentEveryDate: int.tryParse(penalty.numString()),
          guardianName: guardianName.valueOrNull(),
          guardianPhone: guardianPhone.valueOrNull(),
          applicationId: widget.applicationId,
        ),
      ),
    );
    if (ok) {
      UNavigator.back(true);
      return;
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UScaffold(
      appBar: AppBar(title: Text(U.s.newResident).help("app.newContract.page", inline: true), actions: const <Widget>[UHelpActions("app.newContract.")]),
      body: Form(
        key: formKey,
        child: AppPageBody(
          maxWidth: AppResponsive.readableMaxWidth,
          children: <Widget>[
            if (widget.userId == null)
              AppSectionCard(
                title: U.s.whoIsComing,
                icon: Icons.person_outline_rounded,
                child: UColumn(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    UTextField(
                      controller: phone,
                      labelText: U.s.phoneNumber,
                      keyboardType: TextInputType.phone,
                      validator: UValidators.iranianPhone(),
                      onChanged: (_) => setState(() => looked = false),
                      suffix: IconButton(icon: const Icon(Icons.search_rounded), onPressed: _lookup),
                      onFieldSubmitted: (_) => _lookup(),
                    ).help("app.newContract.phone"),
                    if (looked && person != null)
                      AppChip(label: "${person!.firstName ?? ""} ${person!.lastName ?? ""}".trim().isEmpty ? U.s.thisPersonHasAnAccount : "${person!.firstName ?? ""} ${person!.lastName ?? ""}", icon: Icons.verified_user_outlined, tone: AppTone.positive).pOnly(top: 8),
                    if (looked && person == null) ...<Widget>[
                      UTextBodySmall(U.s.newPersonTheyCanSignInLaterWithThisNumber, color: scheme.onSurfaceVariant).pOnly(top: 8, bottom: 8),
                      URow(
                        spacing: 10,
                        children: <Widget>[
                          Expanded(child: UTextField(controller: firstName, labelText: U.s.firstName, validator: UValidators.required<String>())),
                          Expanded(child: UTextField(controller: lastName, labelText: U.s.lastName, validator: UValidators.required<String>())),
                        ],
                      ),
                    ],
                  ],
                ),
              ).pOnly(bottom: 12),
            AppSectionCard(
              title: U.s.bedAndDates,
              icon: Icons.bed_outlined,
              child: UColumn(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: <Widget>[
                  if (beds.isEmpty) UTextBodySmall(U.s.thereIsNoFreeBed, color: scheme.error),
                  if (beds.isNotEmpty)
                    UDropDownField<String?>(
                      labelText: U.s.bed,
                      initialValue: bed?.id,
                      items: <DropdownMenuItem<String?>>[for (final UDormBedResponse b in beds) DropdownMenuItem<String?>(value: b.id, child: Text("${b.room?.title ?? ""} · ${b.title}"))],
                      onChanged: (String? v) => _pickBed(beds.where((UDormBedResponse b) => b.id == v).firstOrNull),
                    ),
                  SegmentedButton<TagDormBedContract>(
                    segments: <ButtonSegment<TagDormBedContract>>[
                      ButtonSegment<TagDormBedContract>(value: TagDormBedContract.monthly, label: Text(U.s.monthly)),
                      ButtonSegment<TagDormBedContract>(value: TagDormBedContract.daily, label: Text(U.s.daily)),
                    ],
                    selected: <TagDormBedContract>{type},
                    onSelectionChanged: (Set<TagDormBedContract> v) => setState(() => type = v.first),
                  ).help("app.newContract.type"),
                  URow(
                    spacing: 10,
                    children: <Widget>[
                      Expanded(child: UTextFieldDatePicker(labelText: U.s.from, jalali: true, initialDate: start, onChange: (DateTime d, _) => start = d)),
                      Expanded(child: UTextFieldDatePicker(labelText: U.s.until, jalali: true, initialDate: end, onChange: (DateTime d, _) => end = d)),
                    ],
                  ),
                ],
              ),
            ).pOnly(bottom: 12),
            AppSectionCard(
              title: U.s.money,
              icon: Icons.payments_outlined,
              child: UColumn(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: <Widget>[
                  AppMoneyField(controller: rent, label: type == TagDormBedContract.daily ? U.s.dailyRent : U.s.monthlyRent),
                  if (type != TagDormBedContract.daily) AppMoneyField(controller: deposit, label: U.s.deposit, required: false),
                  UTextField(controller: penalty, labelText: U.s.lateFeePercentPerDay, keyboardType: TextInputType.number).help("app.newContract.penalty"),
                ],
              ),
            ).pOnly(bottom: 12),
            AppSectionCard(
              title: U.s.guardianOptional,
              icon: Icons.family_restroom_outlined,
              child: URow(
                spacing: 10,
                children: <Widget>[
                  Expanded(child: UTextField(controller: guardianName, labelText: U.s.name)),
                  Expanded(child: UTextField(controller: guardianPhone, labelText: U.s.phoneNumber, keyboardType: TextInputType.phone)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            UButton(title: U.s.saveContract, isLoading: busy, onTap: busy ? null : _save),
            UTextBodySmall(U.s.billsAreMadeAutomaticallyFromTheContract, color: scheme.onSurfaceVariant, textAlign: TextAlign.center).pOnly(top: 8),
          ],
        ),
      ),
    );
  }
}

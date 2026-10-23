import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/pages/business/places/location_picker_page.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// Create or edit a dorm or hotel with everything a customer sees on its page.
abstract class PlaceForm {
  static Future<bool> show(AppKind kind, {AppPlace? place}) async => await UNavigator.push<bool>(PlaceFormPage(kind: kind, place: place)) ?? false;
}

class PlaceFormPage extends StatefulWidget {
  const PlaceFormPage({required this.kind, super.key, this.place});

  final AppKind kind;
  final AppPlace? place;

  @override
  State<PlaceFormPage> createState() => _PlaceFormPageState();
}

class _PlaceFormPageState extends State<PlaceFormPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final URxState state = URxState();
  final TextEditingController title = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController stars = TextEditingController();
  final TextEditingController checkIn = TextEditingController(text: "14:00");
  final TextEditingController checkOut = TextEditingController(text: "12:00");
  final TextEditingController freeHours = TextEditingController();
  final TextEditingController penaltyNights = TextEditingController();
  final TextEditingController policies = TextEditingController();
  final TextEditingController university = TextEditingController();
  final TextEditingController walkMinutes = TextEditingController();
  final TextEditingController visitingHours = TextEditingController();
  final TextEditingController curfew = TextEditingController();
  final TextEditingController minStay = TextEditingController();
  final TextEditingController howToGetThere = TextEditingController();
  final TextEditingController website = TextEditingController();
  final TextEditingController whatsapp = TextEditingController();
  final TextEditingController instagram = TextEditingController();
  final TextEditingController telegram = TextEditingController();
  String cityCode = "";
  List<int> tags = <int>[];
  List<String> highlights = <String>[];
  List<String> rules = <String>[];
  List<String> documents = <String>[];
  List<UPlaceNearby> nearby = <UPlaceNearby>[];
  List<UPlaceFaq> faqs = <UPlaceFaq>[];
  double? latitude;
  double? longitude;
  List<UMediaResponse> media = <UMediaResponse>[];
  UFilePickerController photos = UFilePickerController();
  bool busy = false;

  bool get isHotel => widget.kind == AppKind.hotel;

  bool get isNew => widget.place == null;

  int get _active => isHotel ? TagHotel.active.number : TagDorm.active.number;

  int get _inactive => isHotel ? TagHotel.inactive.number : TagDorm.inactive.number;

  @override
  void initState() {
    load();
    super.initState();
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[title, address, phone, description, stars, checkIn, checkOut, freeHours, penaltyNights, policies, university, walkMinutes, visitingHours, curfew, minStay, howToGetThere, website, whatsapp, instagram, telegram]) c.dispose();
    photos.dispose();
    state.dispose();
    super.dispose();
  }

  Future<void> load() async {
    state.loading();
    final String? id = widget.place?.id;
    if (id == null) {
      tags = <int>[if (isHotel) TagHotel.hotel.number else TagDorm.girls.number, _active];
      cityCode = UCountries.iran().provinces.first.cities.firstOrNull?.code ?? "";
    } else if (isHotel) {
      final UHotelResponse? h = (await UServices.hotel.readHotelById(p: UIdParams(id: id, selectorArgs: const UHotelSelectorArgs(media: UMediaSelectorArgs())))).$1?.result;
      if (h == null) {
        state.error();
        return;
      }
      final UHotelJson j = h.jsonData;
      _common(h.title, h.cityCode, h.address, h.phoneNumber, h.tags, h.media, j.description, j.policies, j.highlights, j.rules, j.howToGetThere, j.nearby, j.faqs, j.website, j.whatsapp, j.instagram, j.telegram, j.latitude, j.longitude);
      stars.text = h.stars == 0 ? "" : h.stars.toString();
      checkIn.text = j.checkInTime ?? "";
      checkOut.text = j.checkOutTime ?? "";
      freeHours.text = j.cancellationFreeHours == 0 ? "" : j.cancellationFreeHours.toString();
      penaltyNights.text = j.cancellationPenaltyNights == 0 ? "" : j.cancellationPenaltyNights.toString();
    } else {
      final UDormResponse? d = (await UServices.dorm.readDormById(p: UIdParams(id: id, selectorArgs: const UDormSelectorArgs(media: UMediaSelectorArgs())))).$1?.result;
      if (d == null) {
        state.error();
        return;
      }
      final UDormJson j = d.jsonData;
      _common(d.title, d.cityCode, d.address, d.phoneNumber, d.tags, d.media, j.description, j.policies, j.highlights, j.rules, j.howToGetThere, j.nearby, j.faqs, j.website, j.whatsapp, j.instagram, j.telegram, j.latitude, j.longitude);
      documents = List<String>.from(j.requiredDocuments);
      university.text = j.nearbyUniversity ?? "";
      walkMinutes.text = j.universityWalkMinutes?.toString() ?? "";
      visitingHours.text = j.visitingHours ?? "";
      curfew.text = j.curfewTime ?? "";
      minStay.text = j.minimumStayMonths?.toString() ?? "";
    }
    if (mounted) setState(() {});
    state.loaded();
  }

  void _common(
    String t,
    String city,
    String? addr,
    String? ph,
    List<int> tg,
    List<UMediaResponse>? m,
    String? desc,
    String? pol,
    List<String> hl,
    List<String> rl,
    String? how,
    List<UPlaceNearby> nb,
    List<UPlaceFaq> fq,
    String? web,
    String? wa,
    String? ig,
    String? tl,
    double? lat,
    double? lng,
  ) {
    title.text = t;
    cityCode = city;
    address.text = addr ?? "";
    phone.text = ph ?? "";
    tags = List<int>.from(tg);
    media = (m ?? <UMediaResponse>[]).sortedForGallery();
    photos.dispose();
    photos = UFilePickerController.fromMedia(media);
    description.text = desc ?? "";
    policies.text = pol ?? "";
    highlights = List<String>.from(hl);
    rules = List<String>.from(rl);
    howToGetThere.text = how ?? "";
    nearby = List<UPlaceNearby>.from(nb);
    faqs = List<UPlaceFaq>.from(fq);
    website.text = web ?? "";
    whatsapp.text = wa ?? "";
    instagram.text = ig ?? "";
    telegram.text = tl ?? "";
    latitude = lat;
    longitude = lng;
  }

  String? _text(TextEditingController c) => isNew ? c.text.trim().nullIfEmpty() : c.text.trim();

  int? _int(TextEditingController c) => int.tryParse(c.numString());

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (cityCode.isEmpty) {
      UToast.error(message: U.s.pleaseChooseTheCity);
      return;
    }
    setState(() => busy = true);
    final String? id = widget.place?.id;
    final String orgId = AppWorkspace.org.id;
    String? savedId = id;
    if (isHotel) {
      final UHotelUpdateParams p = UHotelUpdateParams(
        id: id ?? "",
        tags: tags,
        title: title.text.trim(),
        cityCode: cityCode,
        stars: _int(stars) ?? 0,
        address: _text(address),
        phoneNumber: _text(phone),
        description: _text(description),
        policies: _text(policies),
        checkInTime: _text(checkIn),
        checkOutTime: _text(checkOut),
        cancellationFreeHours: _int(freeHours) ?? 0,
        cancellationPenaltyNights: _int(penaltyNights) ?? 0,
        highlights: highlights,
        rules: rules,
        howToGetThere: _text(howToGetThere),
        nearby: nearby,
        faqs: faqs,
        website: _text(website),
        whatsapp: _text(whatsapp),
        instagram: _text(instagram),
        telegram: _text(telegram),
        latitude: latitude,
        longitude: longitude,
        organizationId: orgId,
      );
      if (id == null) {
        final (UResponse<String>? ok, UEmptyResponse? error, String? exception) = await UServices.hotel.createHotel(p: UHotelCreateParams.fromMap(p.toMap()..remove("id")));
        savedId = ok?.result;
        if (savedId == null) UToast.error(message: error?.message ?? exception ?? U.s.error);
      } else if (!await appSend(UServices.hotel.updateHotel(p: p), toast: false)) {
        savedId = null;
      }
    } else {
      final UDormUpdateParams p = UDormUpdateParams(
        id: id ?? "",
        tags: tags,
        title: title.text.trim(),
        cityCode: cityCode,
        address: _text(address),
        phoneNumber: _text(phone),
        description: _text(description),
        policies: _text(policies),
        highlights: highlights,
        rules: rules,
        requiredDocuments: documents,
        nearbyUniversity: _text(university),
        universityWalkMinutes: _int(walkMinutes),
        visitingHours: _text(visitingHours),
        curfewTime: _text(curfew),
        minimumStayMonths: _int(minStay),
        howToGetThere: _text(howToGetThere),
        nearby: nearby,
        faqs: faqs,
        website: _text(website),
        whatsapp: _text(whatsapp),
        instagram: _text(instagram),
        telegram: _text(telegram),
        latitude: latitude,
        longitude: longitude,
        organizationId: orgId,
      );
      if (id == null) {
        final (UResponse<String>? ok, UEmptyResponse? error, String? exception) = await UServices.dorm.createDorm(p: UDormCreateParams.fromMap(p.toMap()..remove("id")));
        savedId = ok?.result;
        if (savedId == null) UToast.error(message: error?.message ?? exception ?? U.s.error);
      } else if (!await appSend(UServices.dorm.updateDorm(p: p), toast: false)) {
        savedId = null;
      }
    }
    if (savedId == null) {
      if (mounted) setState(() => busy = false);
      return;
    }
    await UServices.media.syncGallery(photos, existing: media, hotelId: isHotel ? savedId : null, dormId: isHotel ? null : savedId);
    await AppWorkspace.loadPlaces();
    UToast.success(message: isNew ? U.s.sentForReviewItIsShownToCustomersOnceItIsApproved : U.s.done);
    UNavigator.back(true);
  }

  Future<void> _delete() async {
    final AppPlace p = widget.place!;
    if (!await UNavigator.confirmAsync(title: "${U.s.delete} ${p.title}", message: U.s.deletingAPlaceRemovesItsRoomsBookingsAndPhotosThisCannotBeUndone, destructive: true)) return;
    final bool ok = await appSend(isHotel ? UServices.hotel.deleteHotel(p: UIdParams(id: p.id)) : UServices.dorm.deleteDorm(p: UIdParams(id: p.id)));
    if (!ok) return;
    await AppWorkspace.loadPlaces();
    UNavigator.back(false);
    UNavigator.back();
  }

  Future<void> _pickLocation() async {
    final LatLng? point = await UNavigator.push<LatLng>(LocationPickerPage(latitude: latitude, longitude: longitude));
    if (point == null) return;
    setState(() {
      latitude = point.latitude;
      longitude = point.longitude;
    });
  }

  Widget _chips<T extends UNumericIdentifiable>(String label, List<T> options, {bool single = false}) => UTagChips<T>(title: label, options: options, tags: tags, single: single);

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Theme(
      data: widget.kind.theme(context),
      child: UScaffold(
        appBar: AppBar(
          title: Text(isNew ? "${U.s.newPlace} · ${widget.kind.title}" : "${U.s.edit} · ${widget.place!.title}").help("app.placeForm.page", inline: true),
          actions: <Widget>[
            if (!isNew && AppWorkspace.isOwner) IconButton(icon: Icon(Icons.delete_outline_rounded, color: scheme.error), tooltip: U.s.delete, onPressed: _delete),
            const UHelpActions("app.placeForm."),
          ],
        ),
        bottomNavigationBar: SafeArea(child: UButton(title: U.s.save, isLoading: busy, onTap: busy ? null : _save).pAll(12)),
        body: AppStateView(
          state: state,
          onRetry: load,
          onLoaded: (BuildContext context) => Form(
            key: formKey,
            child: AppPageBody(
              maxWidth: AppResponsive.readableMaxWidth,
              children: <Widget>[
                AppSectionCard(
                  title: U.s.aboutThisPlace,
                  icon: widget.kind.icon,
                  child: UColumn(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: <Widget>[
                      UTextField(controller: title, labelText: U.s.name, validator: UValidators.required<String>()),
                      if (isHotel) _chips<TagHotel>(U.s.propertyType, TagHotel.values.group(100), single: true) else _chips<TagDorm>(U.s.gender, TagDorm.values.group(100), single: true),
                      if (isHotel) UTextField(controller: stars, labelText: U.s.stars, keyboardType: TextInputType.number),
                      UTextField(controller: description, labelText: U.s.description, lines: 4),
                      UListEditor.strings(title: U.s.highlights, addLabel: U.s.addHighlight, items: highlights, onChanged: (List<String> v) => highlights = v).help("app.placeForm.highlights"),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: tags.contains(_active),
                        onChanged: (bool v) => setState(() {
                          tags.removeWhere((int t) => t == _active || t == _inactive);
                          tags.add(v ? _active : _inactive);
                        }),
                        title: Text(U.s.showToCustomers),
                        subtitle: Text(isNew ? U.s.shownAfterKhabroomApprovesIt : U.s.turnOffToHideItForAWhile),
                      ).help("app.placeForm.visible"),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppSectionCard(
                  title: U.s.photos,
                  icon: Icons.photo_library_outlined,
                  child: UColumn(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      UTextBodySmall(U.s.pickTheCoverPhotoItIsShownFirst, color: scheme.onSurfaceVariant, maxLines: 6).pOnly(bottom: 8),
                      UFilePicker.gallery(photos),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppSectionCard(
                  title: U.s.addressAndContact,
                  icon: Icons.place_outlined,
                  child: UColumn(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: <Widget>[
                      Builder(
                        builder: (BuildContext context) {
                          final UCountryCityInfo city = UCountries.infoByCode(cityCode);
                          return UCountryProvincePicker(
                            initialCountry: city.country,
                            initialProvince: city.province,
                            initialCity: city.city,
                            onProvinceChanged: (UProvince i) => cityCode = i.code,
                            onCityChanged: (UCity? i) => cityCode = i?.code ?? cityCode,
                          );
                        },
                      ).help("app.placeForm.city"),
                      UTextField(controller: address, labelText: U.s.address, lines: 2),
                      AppTile(
                        icon: Icons.map_outlined,
                        title: latitude == null ? U.s.pickTheLocationOnTheMap : U.s.locationIsSet,
                        subtitle: latitude == null ? U.s.customersCanOpenItInTheirMapApp : "${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}",
                        onTap: _pickLocation,
                      ).help("app.placeForm.location"),
                      UTextField(controller: howToGetThere, labelText: U.s.howToGetThere, lines: 2),
                      UListEditor.nearby(items: nearby, onChanged: (List<UPlaceNearby> v) => nearby = v),
                      UTextField(controller: phone, labelText: U.s.phoneNumber, keyboardType: TextInputType.phone),
                      UFieldPair(UTextField(controller: website, labelText: U.s.website, keyboardType: TextInputType.url), UTextField(controller: whatsapp, labelText: U.s.whatsapp)),
                      UFieldPair(UTextField(controller: instagram, labelText: U.s.instagram), UTextField(controller: telegram, labelText: U.s.telegram)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppSectionCard(
                  title: U.s.amenities,
                  icon: Icons.room_service_outlined,
                  child: UColumn(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: isHotel
                        ? <Widget>[_chips<TagHotel>(U.s.amenities, TagHotel.values.group(500)), _chips<TagHotel>(U.s.mealPlans, TagHotel.values.group(600))]
                        : <Widget>[
                            _chips<TagDorm>(U.s.acceptedResidents, TagDorm.values.group(300)),
                            _chips<TagDorm>(U.s.amenities, TagDorm.values.group(500)),
                            _chips<TagDorm>(U.s.includedInRent, TagDorm.values.group(700)),
                            _chips<TagDorm>(U.s.mealServices, TagDorm.values.group(600)),
                          ],
                  ),
                ).help("app.placeForm.amenities"),
                const SizedBox(height: 12),
                AppSectionCard(
                  title: U.s.rulesAndPolicies,
                  icon: Icons.gavel_outlined,
                  child: UColumn(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: <Widget>[
                      if (isHotel) ...<Widget>[
                        UFieldPair(UTextField(controller: checkIn, labelText: U.s.checkInTime), UTextField(controller: checkOut, labelText: U.s.checkOutTime)),
                        UFieldPair(
                          UTextField(controller: freeHours, labelText: U.s.freeCancellationUpToAFewHoursBeforeCheckIn, keyboardType: TextInputType.number),
                          UTextField(controller: penaltyNights, labelText: U.s.cancellationFee, keyboardType: TextInputType.number),
                        ).help("app.placeForm.cancellation"),
                        _chips<TagHotel>(U.s.policies, TagHotel.values.group(300)),
                      ] else ...<Widget>[
                        UFieldPair(UTextField(controller: university, labelText: U.s.nearbyUniversity), UTextField(controller: walkMinutes, labelText: U.s.universityWalkMinutes, keyboardType: TextInputType.number)),
                        UFieldPair(UTextField(controller: visitingHours, labelText: U.s.visitingHours), UTextField(controller: curfew, labelText: U.s.curfewTime)),
                        UTextField(controller: minStay, labelText: U.s.minimumStayMonths, keyboardType: TextInputType.number),
                        UListEditor.strings(title: U.s.requiredDocuments, addLabel: U.s.add, items: documents, onChanged: (List<String> v) => documents = v),
                      ],
                      UTextField(controller: policies, labelText: U.s.policies, lines: 3),
                      UListEditor.strings(title: U.s.rules, addLabel: U.s.add, items: rules, onChanged: (List<String> v) => rules = v),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppSectionCard(
                  title: U.s.faqs,
                  icon: Icons.quiz_outlined,
                  child: UListEditor.faqs(items: faqs, onChanged: (List<UPlaceFaq> v) => faqs = v),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:u/utilities.dart";

/// Create or edit a dorm, hotel or café: only the details a customer needs to choose it.
abstract class PlaceForm {
  static Future<bool> show(AppKind kind, {AppPlace? place}) async {
    final TextEditingController title = TextEditingController(text: place?.title);
    final TextEditingController address = TextEditingController(text: place?.address);
    final TextEditingController phone = TextEditingController(text: place?.hotel?.phoneNumber ?? place?.dorm?.phoneNumber ?? place?.cafe?.phoneNumber);
    final TextEditingController description = TextEditingController(text: place?.hotel?.jsonData.description ?? place?.dorm?.jsonData.description ?? place?.cafe?.jsonData.description);
    final TextEditingController stars = TextEditingController(text: place?.hotel?.stars.toString() ?? "");
    final TextEditingController checkIn = TextEditingController(text: place?.hotel?.jsonData.checkInTime ?? "14:00");
    final TextEditingController checkOut = TextEditingController(text: place?.hotel?.jsonData.checkOutTime ?? "12:00");
    final TextEditingController hours = TextEditingController(text: place?.cafe?.jsonData.openHours);
    String cityCode = place?.cityCode ?? "";
    bool visible = place?.active ?? true;
    bool girls = place?.tags.contains(TagDorm.girls.number) ?? true;
    TagCafe cafeType = TagCafe.values.where((TagCafe t) => t.number < 200 && (place?.tags.contains(t.number) ?? false)).firstOrNull ?? TagCafe.cafe;
    final String orgId = AppWorkspace.org.id;

    Future<bool> save() async {
      if (cityCode.isEmpty) {
        UToast.error(message: U.s.pleaseChooseTheCity);
        return false;
      }
      final List<int> status = <int>[visible ? TagHotel.active.number : TagHotel.inactive.number];
      final List<int> notStatus = <int>[visible ? TagHotel.inactive.number : TagHotel.active.number];
      final bool ok = switch (kind) {
        AppKind.dorm => place == null
            ? await appSend(
                UServices.dorm.createDorm(
                  p: UDormCreateParams(
                    tags: <int>[girls ? TagDorm.girls.number : TagDorm.boys.number, ...status],
                    title: title.text.trim(),
                    cityCode: cityCode,
                    organizationId: orgId,
                    address: address.valueOrNull(),
                    phoneNumber: phone.valueOrNull(),
                    description: description.valueOrNull(),
                  ),
                ),
              )
            : await appSend(
                UServices.dorm.updateDorm(
                  p: UDormUpdateParams(
                    id: place.id,
                    title: title.text.trim(),
                    cityCode: cityCode,
                    address: address.text.trim(),
                    phoneNumber: phone.text.trim(),
                    description: description.text.trim(),
                    addTags: <int>[girls ? TagDorm.girls.number : TagDorm.boys.number, ...status],
                    removeTags: <int>[girls ? TagDorm.boys.number : TagDorm.girls.number, ...notStatus],
                  ),
                ),
              ),
        AppKind.hotel => place == null
            ? await appSend(
                UServices.hotel.createHotel(
                  p: UHotelCreateParams(
                    tags: <int>[TagHotel.hotel.number, ...status],
                    title: title.text.trim(),
                    cityCode: cityCode,
                    organizationId: orgId,
                    stars: int.tryParse(stars.numString()) ?? 0,
                    address: address.valueOrNull(),
                    phoneNumber: phone.valueOrNull(),
                    description: description.valueOrNull(),
                    checkInTime: checkIn.valueOrNull(),
                    checkOutTime: checkOut.valueOrNull(),
                  ),
                ),
              )
            : await appSend(
                UServices.hotel.updateHotel(
                  p: UHotelUpdateParams(
                    id: place.id,
                    title: title.text.trim(),
                    cityCode: cityCode,
                    stars: int.tryParse(stars.numString()),
                    address: address.text.trim(),
                    phoneNumber: phone.text.trim(),
                    description: description.text.trim(),
                    checkInTime: checkIn.text.trim(),
                    checkOutTime: checkOut.text.trim(),
                    addTags: status,
                    removeTags: notStatus,
                  ),
                ),
              ),
        AppKind.cafe => place == null
            ? await appSend(
                UServices.cafe.createCafe(
                  p: UCafeCreateParams(
                    tags: <int>[cafeType.number, ...status],
                    title: title.text.trim(),
                    cityCode: cityCode,
                    organizationId: orgId,
                    address: address.valueOrNull(),
                    phoneNumber: phone.valueOrNull(),
                    description: description.valueOrNull(),
                    openHours: hours.valueOrNull(),
                  ),
                ),
              )
            : await appSend(
                UServices.cafe.updateCafe(
                  p: UCafeUpdateParams(
                    id: place.id,
                    title: title.text.trim(),
                    cityCode: cityCode,
                    address: address.text.trim(),
                    phoneNumber: phone.text.trim(),
                    description: description.text.trim(),
                    openHours: hours.text.trim(),
                    addTags: <int>[cafeType.number, ...status],
                    removeTags: <int>[...TagCafe.values.where((TagCafe t) => t.number < 200 && t != cafeType).map((TagCafe t) => t.number), ...notStatus],
                  ),
                ),
              ),
      };
      if (ok) await AppWorkspace.loadPlaces();
      return ok;
    }

    final UCountryCityInfo city = UCountries.infoByCode(cityCode);
    return AppForm.show(
      title: place == null ? "${U.s.newPlace} · ${kind.title}" : "${U.s.edit} · ${place.title}",
      help: "app.placeForm.page",
      onSubmit: save,
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: title, labelText: U.s.name, validator: UValidators.required<String>()),
        UCountryProvincePicker(
          initialCountry: city.country,
          initialProvince: city.province,
          initialCity: city.city,
          onProvinceChanged: (UProvince i) => cityCode = i.code,
          onCityChanged: (UCity? i) => cityCode = i?.code ?? cityCode,
        ).help("app.placeForm.city"),
        UTextField(controller: address, labelText: U.s.address, lines: 2),
        UTextField(controller: phone, labelText: U.s.phoneNumber, keyboardType: TextInputType.phone),
        if (kind == AppKind.dorm)
          SegmentedButton<bool>(
            segments: <ButtonSegment<bool>>[ButtonSegment<bool>(value: true, label: Text(TagDorm.girls.localizedTitle)), ButtonSegment<bool>(value: false, label: Text(TagDorm.boys.localizedTitle))],
            selected: <bool>{girls},
            onSelectionChanged: (Set<bool> v) => setState(() => girls = v.first),
          ),
        if (kind == AppKind.hotel) ...<Widget>[
          UTextField(controller: stars, labelText: U.s.stars, keyboardType: TextInputType.number),
          URow(
            spacing: 10,
            children: <Widget>[
              Expanded(child: UTextField(controller: checkIn, labelText: U.s.checkInTime)),
              Expanded(child: UTextField(controller: checkOut, labelText: U.s.checkOutTime)),
            ],
          ),
        ],
        if (kind == AppKind.cafe) ...<Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final TagCafe t in TagCafe.values.where((TagCafe t) => t.number < 200)) ChoiceChip(label: Text(t.localizedTitle), selected: cafeType == t, onSelected: (_) => setState(() => cafeType = t)),
            ],
          ),
          UTextField(controller: hours, labelText: U.s.openHours, hintText: U.s.forExampleEveryDay8To24),
        ],
        UTextField(controller: description, labelText: U.s.aboutThisPlace, lines: 3),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: visible,
          onChanged: (bool v) => setState(() => visible = v),
          title: Text(U.s.showToCustomers),
          subtitle: Text(place == null ? U.s.shownAfterKhabroomApprovesIt : U.s.turnOffToHideItForAWhile),
        ).help("app.placeForm.visible"),
      ],
    );
  }
}

import "package:khabroom/main.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/pages/hotel/booking/booking_page.dart";
import "package:khabroom/view/pages/hotel/hotel_detail/hotel_detail_controller.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:khabroom/view/widgets/review_widgets.dart";
import "package:u/utilities.dart";

class HotelDetailPage extends StatefulWidget {
  const HotelDetailPage({required this.hotelId, super.key});

  final String hotelId;

  @override
  State<HotelDetailPage> createState() => _HotelDetailPageState();
}

class _HotelDetailPageState extends State<HotelDetailPage> {
  final HotelDetailController c = HotelDetailController();

  @override
  void initState() {
    c.init(hotelId: widget.hotelId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.hotels)),
    body: Obx(() {
      if (c.hotelDetailState.isLoading() || c.hotelDetailState.isInitial())
        return const UProgressCircular(size: 34, strokeWidth: 3).alignAtCenter();
      if (c.hotelDetailState.isError() || c.hotel == null) return UErrorRetry(onTap: c.readHotel);

      final UHotelResponse hotel = c.hotel!;
      return SingleChildScrollView(
        padding: AppResponsive.pagePadding(context),
        child: AppContent(
          child: AppDetailLayout(
            content: _content(context, hotel),
            side: _bookingCard(context, hotel),
            compactSideFirst: true,
          ),
        ),
      );
    }),
  );

  Widget _content(BuildContext context, UHotelResponse hotel) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          padding: EdgeInsets.zero,
          clip: true,
          child: UColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppCoverImage(media: hotel.media, height: AppResponsive.isCompact(context) ? 200 : 280, fallbackIcon: Icons.apartment_rounded),
              UColumn(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  URow(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      UTextHeadlineSmall(hotel.title, color: scheme.onSurface, expanded: 1),
                      if (hotel.stars > 0) AppChip(label: "${hotel.stars.toString().toPersianNumber()} ${U.s.stars}", icon: Icons.star_rounded, tone: AppTone.warning),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppRating(score: hotel.averageScore, count: hotel.commentCount),
                  if (hotel.address != null) ...<Widget>[
                    const SizedBox(height: 10),
                    URow(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(Icons.location_on_outlined, size: 15, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        UTextBodySmall(hotel.address!, color: scheme.onSurfaceVariant, expanded: 1),
                      ],
                    ),
                  ],
                ],
              ).pAll(16),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (hotel.jsonData.description != null) ...<Widget>[
          AppSectionCard(
            title: U.s.aboutThisPlace,
            icon: Icons.info_outline_rounded,
            child: UTextBodyMedium(hotel.jsonData.description!, color: scheme.onSurface),
          ),
          const SizedBox(height: 16),
        ],
        if (hotel.jsonData.amenities.isNotEmpty) ...<Widget>[
          AppSectionCard(
            title: U.s.amenities,
            icon: Icons.check_circle_outline_rounded,
            child: AppChipList(items: hotel.jsonData.amenities),
          ),
          const SizedBox(height: 16),
        ],
        AppSectionCard(
          title: U.s.roomsAndBeds,
          icon: Icons.bed_outlined,
          child: _rooms(context),
        ),
        const SizedBox(height: 16),
        AppSectionCard(
          title: U.s.cancellationPolicy,
          icon: Icons.event_busy_outlined,
          child: UColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppInfoRow(label: U.s.freeCancellationUntilHoursBeforeCheckIn, value: "${hotel.jsonData.cancellationFreeHours.toString().toPersianNumber()} ${U.s.hour}"),
              AppInfoRow(label: U.s.cancellationPenalty, value: "${hotel.jsonData.cancellationPenaltyNights.toString().toPersianNumber()} ${U.s.night}"),
              const SizedBox(height: 4),
              UTextBodySmall(U.s.cancellationRefundNote, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
        if (hotel.jsonData.rules.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          AppSectionCard(title: U.s.rules, icon: Icons.gavel_rounded, child: AppBulletList(items: hotel.jsonData.rules)),
        ],
        const SizedBox(height: 16),
        AppSectionCard(
          title: U.s.contactInformation,
          icon: Icons.support_agent_outlined,
          child: UColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (hotel.jsonData.checkInTime != null) AppInfoRow(label: U.s.checkIn, value: hotel.jsonData.checkInTime!),
              if (hotel.jsonData.checkOutTime != null) AppInfoRow(label: U.s.checkOut, value: hotel.jsonData.checkOutTime!),
              if (hotel.phoneNumber != null)
                UButton(
                  title: U.s.callTheHotel,
                  type: UButtonType.outlined,
                  icon:const Icon(Icons.call_outlined),
                  fullWidth: true,
                  onTap: () => ULaunch.call(hotel.phoneNumber!),
                ).pOnly(top: 8),
              if (hotel.jsonData.latitude != null && hotel.jsonData.longitude != null)
                UButton(
                  title: U.s.directions,
                  type: UButtonType.text,
                  icon: const Icon(Icons.map_outlined),
                  fullWidth: true,
                  onTap: () => ULaunch.map(hotel.jsonData.latitude!, hotel.jsonData.longitude!),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ReviewSection(
          comments: hotel.comments ?? <UCommentResponse>[],
          hotelId: hotel.id,
          onSubmitted: c.readHotel,
        ),
      ],
    );
  }

  Widget _rooms(BuildContext context) => Obx(() {
    if (!c.hasDates) return UTextBodySmall(U.s.selectYourDatesToSeePrices, color: Theme.of(context).colorScheme.onSurfaceVariant);
    if (c.availabilityState.isLoading()) return const UProgressCircular(size: 28, strokeWidth: 3).alignAtCenter().pSymmetric(vertical: 20);
    if (c.availabilityState.isError()) return UErrorRetry(onTap: c.readAvailability);
    if (c.availability.isEmpty) return AppEmpty(title: U.s.noRoomsAvailableForTheseDates, icon: Icons.bed_outlined);

    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final UHotelRoomAvailabilityResponse item in c.availability)
          _RoomTile(
            item: item,
            onBook: item.isBookable
                ? () => UNavigator.push(
                    BookingPage(
                      hotel: c.hotel!,
                      availability: item,
                      checkInDate: c.checkInDate.value!,
                      checkOutDate: c.checkOutDate.value!,
                      guestCount: c.guestCount.value,
                    ),
                  )
                : null,
          ).pOnly(bottom: 12),
      ],
    );
  });

  /// Dates and guest count live in one card that stays beside the content on desktop.
  Widget _bookingCard(BuildContext context, UHotelResponse hotel) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          URow(
            children: <Widget>[
              UColumn(
                expanded: 1,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UTextLabelSmall(U.s.startingFrom, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 2),
                  UTextTitleLarge(money(hotel.minPricePerNight), color: scheme.onSurface),
                ],
              ),
              UTextLabelSmall(U.s.perNight, color: scheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 16),
          UTextTitleSmall(U.s.selectDates, color: scheme.onSurface),
          const SizedBox(height: 10),
          URow(
            children: <Widget>[
              UTextFieldDatePicker(
                expanded: 1,
                jalali: true,
                labelText: U.s.checkInDate,
                controller: c.controllerCheckIn,
                initialDate: c.checkInDate.value,
                onChange: (DateTime d, Jalali j) => c.setCheckIn(d),
              ),
              const SizedBox(width: 10),
              UTextFieldDatePicker(
                expanded: 1,
                jalali: true,
                labelText: U.s.checkOutDate,
                controller: c.controllerCheckOut,
                initialDate: c.checkOutDate.value,
                onChange: (DateTime d, Jalali j) => c.setCheckOut(d),
              ),
            ],
          ),
          const SizedBox(height: 14),
          UTextTitleSmall(U.s.guestCount, color: scheme.onSurface),
          const SizedBox(height: 8),
          Obx(
            () => URow(
              children: <Widget>[
                UButton(type: UButtonType.icon, icon: const Icon(Icons.remove_rounded), onTap: () => c.changeGuestCount(c.guestCount.value - 1)),
                UTextTitleMedium(c.guestCount.value.toString().toPersianNumber(), color: scheme.onSurface, textAlign: TextAlign.center, expanded: 1),
                UButton(type: UButtonType.icon, icon: const Icon(Icons.add_rounded), onTap: () => c.changeGuestCount(c.guestCount.value + 1)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Obx(
            () => AppInfoRow(
              label: U.s.nightsCountLabel,
              value: "${c.nightCount.toString().toPersianNumber()} ${U.s.night}",
              emphasize: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.item, required this.onBook});

  final UHotelRoomAvailabilityResponse item;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final UHotelRoomResponse room = item.room;

    return UContainer(
      radius: 14,
      padding: const EdgeInsets.all(14),
      color: scheme.surfaceContainer,
      border: Border.all(color: scheme.outlineVariant),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          URow(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UColumn(
                expanded: 1,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UTextTitleSmall(room.title, color: scheme.onSurface),
                  const SizedBox(height: 6),
                  URow(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.person_outline_rounded, size: 13, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      UTextBodySmall("${U.s.roomCapacity}: ${room.capacity.toString().toPersianNumber()}", color: scheme.onSurfaceVariant),
                      if (room.jsonData.bedType != null) ...<Widget>[
                        const SizedBox(width: 10),
                        UTextBodySmall(room.jsonData.bedType!, color: scheme.onSurfaceVariant),
                      ],
                    ],
                  ),
                ],
              ),
              AppPrice(amount: item.totalPrice, caption: "${item.nightCount.toString().toPersianNumber()} ${U.s.night}"),
            ],
          ),
          if (room.jsonData.amenities.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            AppChipList(items: room.jsonData.amenities.take(4).toList()),
          ],
          const SizedBox(height: 12),
          if (onBook == null)
            AppChip(label: item.fitsGuestCount ? U.s.roomIsFullyBooked : U.s.guestCountExceedsCapacity, tone: AppTone.danger)
          else
            UButton(title: U.s.reserveThisRoom, fullWidth: true, onTap: onBook),
        ],
      ),
    );
  }
}

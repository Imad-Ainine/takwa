import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:takwa/core/providers/database_providers.dart';
import 'package:takwa/core/theme/ramadan_theme.dart';
import 'package:takwa/core/widgets/app_bar_widget.dart';
import 'package:takwa/core/widgets/custom_leading_button.dart';
import 'package:takwa/core/widgets/custom_pattern_background.dart';
import 'package:takwa/core/widgets/primary_button.dart';
import 'package:takwa/core/widgets/takwa_tappable.dart';
import 'package:takwa/features/prayer/providers/mosque_provider.dart';
import 'package:takwa/features/prayer/data/mosque_repository.dart';
import 'package:takwa/core/notifications/notifications_service.dart';
import 'package:intl/intl.dart';
import 'package:takwa/core/theme/app_theme.dart';
import 'package:takwa/core/widgets/takwa_loading_indicator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:takwa/l10n/app_localizations.dart';

class MosquesScreen extends ConsumerStatefulWidget {
  const MosquesScreen({super.key});

  @override
  ConsumerState<MosquesScreen> createState() => _MosquesScreenState();
}

class _MosquesScreenState extends ConsumerState<MosquesScreen> {
  String _cityName = lookupAppLocalizations(
    const Locale('ar'),
  ).overlayServiceDefaultCity;
  Position? _currentPosition;
  final Geocoding geocoding = Geocoding();

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
      }
      
      List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        setState(() {
          _cityName =
              placemarks.first.locality ??
              placemarks.first.subAdministrativeArea ??
              _cityName;
        });
      }
    } catch (e) {
      final settings = ref.read(settingsDaoProvider);
      final city = await settings.get('cityName');
      if (city != null && mounted) {
        setState(() {
          _cityName = city;
        });
      }
    }
  }

  void _openMap(double lat, double lon) async {
    Uri url;
    if (lat == 0 && lon == 0) {
      if (_currentPosition != null) {
        url = Uri.parse(
          'https://www.google.com/maps/search/mosque/@${_currentPosition!.latitude},${_currentPosition!.longitude},15z',
        );
      } else {
        url = Uri.parse('https://www.google.com/maps/search/mosque');
      }
    } else {
      url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon',
      );
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.mosquesCannotOpenMaps),
          ),
        );
      }
    }
  }

  void _callPhone(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.mosquesCannotMakeCall),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRamadan = ref.watch(ramadanModeProvider).value ?? false;
    final style = AdaptiveStyle(context, isRamadan);
    final prayersAsyncValue = ref.watch(prayerTimesProvider);
    // This screen passes its own `child:` into AppBarWidget instead of using
    // its built-in title, so it doesn't get that widget's brightness-aware
    // titleColor (see app_bar_widget.dart) — it was hardcoding Colors.white
    // here instead, invisible in light mode where showBackground's gradient
    // leans light. Mirrors the same dark-mode-only condition.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerFg = isDark ? Colors.white : context.colors.textPrimary;

    // If you haven't secured a location yet, show a loader instead of querying the API
    if (_currentPosition == null) {
      return Scaffold(
        backgroundColor: style.bg,
        body: const Center(child: TakwaLoadingIndicator()),
      );
    }

    // Once position is secured, watch the provider.
    final mosquesAsyncValue = ref.watch(nearbyMosquesProvider);

    String nextPrayerTime = '--:--';
    prayersAsyncValue.whenData((prayers) {
      final next = PrayerTimesService.nextPrayer(prayers);
      if (next != null) {
        nextPrayerTime = DateFormat('hh:mm a').format(next.time);
      }
    });

    return Scaffold(
      backgroundColor: style.bg,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPatternBackground(pattern: BackgroundPattern.adhkar),
          ),
          Column(
            children: [
              AppBarWidget(
                title: l10n.mosquesNearbyTitle,
                height: 380,
                showBackground: true,
                child: Column(
                  children: [
                    // AppBar replacement
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CustomLeadingButton(),
                          Text(
                            l10n.mosquesNearbyTitle,
                            style: style.amiri(
                              22,
                              color: headerFg,
                              weight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    // Current Location Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: headerFg,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            l10n.mosquesCurrentLocationLabel(_cityName),
                            style: style.naskh(
                              14,
                              color: headerFg,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Hero Map Section
                    Container(
                      margin: const EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 8,
                        bottom: 24,
                      ),
                      height: 120,
                      width: 200,
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 80,
                            color: headerFg.withValues(alpha: 0.24),
                          ),
                          Icon(
                            Icons.location_on_rounded,
                            size: 48,
                            color: headerFg,
                          ),
                          Positioned(
                            bottom: 4,
                            left: 12,
                            child: SizedBox(
                              width: 180,
                              child: PrimaryButton(
                                onTap: () async => _openMap(0, 0),
                                label: l10n.mosquesViewOnMapButton,
                                isBg: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: mosquesAsyncValue.when(
                  data: (mosques) {
                    if (mosques.isEmpty) {
                      return _buildEmptyState(style, l10n);
                    }
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(
                        top: 8,
                        bottom: 24,
                        left: 16,
                        right: 16,
                      ),
                      itemCount: mosques.length + 1, // +1 for the Hadith footer
                      itemBuilder: (context, index) {
                        if (index == mosques.length) {
                          return _buildHadithFooter(style, l10n);
                        }
                        final mosque = mosques[index];
                        return _buildEnhancedMosqueCard(
                          mosque,
                          index + 1,
                          nextPrayerTime,
                          style,
                          l10n,
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: TakwaLoadingIndicator()),
                  error: (err, stack) => _buildErrorState(err, style, l10n),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMosqueCard(
    Mosque mosque,
    int index,
    String nextPrayerTime,
    AdaptiveStyle style,
    AppLocalizations l10n,
  ) {
    String formattedDistance;
    if (mosque.distance < 1000) {
      formattedDistance = l10n.mosquesDistanceMeters(
        mosque.distance.toStringAsFixed(0),
      );
    } else {
      formattedDistance = l10n.mosquesDistanceKm(
        (mosque.distance / 1000).toStringAsFixed(1),
      );
    }

    final hasPhone = mosque.phone.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: style.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: style.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Index Badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: style.gold,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: style.naskh(
                        16,
                        color: Colors.white,
                        weight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    mosque.name,
                    style: style.amiri(
                      20,
                      color: style.text,
                      weight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Distance Text
                Text(
                  formattedDistance,
                  style: style.naskh(
                    14,
                    color: style.gold,
                    weight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Address Row
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: style.textSec,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    mosque.address,
                    style: style.naskh(13, color: style.textSec),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Next Prayer Row
            Row(
              children: [
                Icon(Icons.access_time_rounded, size: 16, color: style.textSec),
                const SizedBox(width: 6),
                Text(
                  l10n.mosquesNextPrayerLabel(nextPrayerTime),
                  style: style.naskh(13, color: style.textSec),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TakwaTappable(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _openMap(mosque.lat, mosque.lon);
                    },
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: style.gold,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.directions_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            l10n.mosquesDirectionsButton,
                            style: style.naskh(
                              14,
                              color: Colors.white,
                              weight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (hasPhone) const SizedBox(width: AppSpacing.md),
                if (hasPhone)
                  Expanded(
                    child: TakwaTappable(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _callPhone(mosque.phone);
                      },
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: style.bg,
                          border: Border.all(color: style.gold),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.call_outlined,
                              color: style.gold,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              l10n.mosquesCallButton,
                              style: style.naskh(
                                14,
                                color: style.gold,
                                weight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHadithFooter(AdaptiveStyle style, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8D595)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFD4AF37),
                size: 16,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.mosquesHadithSectionTitle,
                style: style.naskh(
                  14,
                  color: const Color(0xFF8B7322),
                  weight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFD4AF37),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'عن أبي هريرة رضي الله عنه عن النبي ﷺ قال: "من غدا إلى المسجد، أو راح، أعد الله له في الجنة نزلا، كلما غدا، أو راح"',
            style: style.amiri(
              18,
              color: const Color(0xFF5E4E16),
              weight: FontWeight.w600,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'متفق عليه',
            style: style.naskh(
              12,
              color: const Color(0xFF8B7322).withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AdaptiveStyle style, AppLocalizations l10n) {
    return Center(
      child: Text(
        l10n.mosquesEmptyState,
        style: style.naskh(16, color: style.textSec),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildErrorState(
    Object err,
    AdaptiveStyle style,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 48,
              color: style.gold.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              err.toString().replaceAll('Exception: ', ''),
              style: style.naskh(16, color: style.textSec),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: 200,
              child: PrimaryButton(
                onTap: () async => ref.refresh(nearbyMosquesProvider),
                label: l10n.prayerScreenRetryButton,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/ios_theme.dart';
import '../../../core/di/service_locator.dart';
import '../../../services/driver_api_service.dart';
import '../../../services/auth_service.dart';
import '../bloc/route_bloc.dart';
import '../bloc/driver_api_bloc.dart';
import '../widgets/route_map.dart';
import '../widgets/stops_list.dart';
import '../widgets/order_details_sheet.dart';
import '../widgets/delivery_completion_sheet.dart';
import '../widgets/shift_control_panel.dart';
import '../models/delivery_stop.dart';

/// Main route screen for drivers
/// Shows map with route and list of delivery stops
class RouteScreen extends StatelessWidget {
  const RouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            final authService = getIt<AuthService>();
            final driverId = authService.userId ?? 'unknown';
            return RouteBloc()..add(LoadRoute(driverId));
          },
        ),
        BlocProvider(
          create: (context) {
            final authService = getIt<AuthService>();
            final driverId = authService.userId ?? 'unknown';
            return DriverApiBloc(
              getIt<DriverApiService>(),
              driverId,
            )..add(LoadDriverRoute(driverId));
          },
        ),
      ],
      child: const _RouteScreenContent(),
    );
  }
}

class _RouteScreenContent extends StatelessWidget {
  const _RouteScreenContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSTheme.bgPrimary,
      body: BlocConsumer<RouteBloc, RouteState>(
        listener: (context, state) {
          if (state.error != null) {
            _showError(context, state.error!);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Map layer
              RouteMap(
                routePoints: state.routeGeometry,
                stops: state.stops,
                currentLocation: state.currentLocation,
                needsRecenter: state.needsRecenter,
                onStopTap: (stop) => _onStopTap(context, stop),
              ),
              
              // Loading overlay
              if (state.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(IOSTheme.systemBlue),
                    ),
                  ),
                ),
              
              // Stops list sheet
              if (state.stops.isNotEmpty)
                StopsList(
                  stops: state.stops,
                  completedCount: state.completedStops,
                  routeInfo: state.routeInfo,
                  currentStop: state.nextStop,
                  onStopTap: (stop) => _onStopTap(context, stop),
                  onOpenInNavigator: () => _openNavigator(state.nextStop),
                ),
              
              // Top bar with back button and title
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          GlassContainer(
                            padding: const EdgeInsets.all(8),
                            borderRadius: IOSTheme.radiusMd,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: IOSTheme.labelPrimary,
                              ),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassContainer(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_shipping_outlined,
                                    size: 20,
                                    color: IOSTheme.labelSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Маршрут доставки',
                                    style: IOSTheme.headline,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Shift control panel for clock in/out
                      ShiftControlPanel(
                        onStatusChanged: () {
                          // Handle shift status changes if needed globally
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onStopTap(BuildContext context, DeliveryStop stop) {
    IOSTheme.mediumImpact();
    
    if (stop.status == StopStatus.pending) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (bottomSheetContext) => OrderDetailsSheet(
          stop: stop,
          onComplete: () {
            // Show the photo proof sheet after checklist is verified
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (photoContext) => DeliveryCompletionSheet(
                stop: stop,
                onComplete: (proof) {
                  context.read<RouteBloc>().add(MarkStopCompleted(stop.id, proof));
                  _promptNextStopNavigation(context);
                },
              ),
            );
          },
        ),
      );
    }
  }

  void _promptNextStopNavigation(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!context.mounted) return;
      final state = context.read<RouteBloc>().state;
      if (state.nextStop != null) {
        IOSTheme.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.navigation, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Следующая точка: ${state.nextStop!.address}',
                    style: IOSTheme.bodyMedium.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'Поехали',
              textColor: IOSTheme.systemTeal,
              onPressed: () => _openNavigator(state.nextStop),
            ),
            backgroundColor: IOSTheme.labelPrimary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(IOSTheme.radiusMd),
            ),
          ),
        );
      }
    });
  }

  void _openNavigator(DeliveryStop? stop) async {
    if (stop == null) return;
    IOSTheme.lightImpact();

    final lat = stop.location.latitude;
    final lng = stop.location.longitude;

    debugPrint('Opening navigator to: ${stop.address} ($lat, $lng)');

    // Try Yandex Navigator app (deep link)
    final yandexNaviUri = Uri.parse(
      'yandexnavi://build_route_on_map?lat_to=$lat&lon_to=$lng&zoom=16',
    );
    // Fallback: Yandex Maps web (works in browser if app not installed)
    final yandexMapsUri = Uri.parse(
      'https://yandex.uz/maps/?rtext=~$lat,$lng&rtt=auto',
    );

    if (await canLaunchUrl(yandexNaviUri)) {
      await launchUrl(yandexNaviUri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(yandexMapsUri, mode: LaunchMode.externalApplication);
    }
  }

  void _showError(BuildContext context, String error) {
    IOSTheme.error();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: IOSTheme.systemRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(IOSTheme.radiusMd),
        ),
      ),
    );
  }
}



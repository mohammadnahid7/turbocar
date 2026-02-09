/// Saved Page
/// Simple list display of saved cars from SecureStore with guest sync banner
/// NO API calls, NO refresh, NO loading indicators
/// SecureStore is the single source of truth
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/saved_cars_provider.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/router/route_names.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/car_list_item.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../../core/services/notification_service.dart';

class SavedPage extends ConsumerStatefulWidget {
  const SavedPage({super.key});

  @override
  ConsumerState<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends ConsumerState<SavedPage> {
  // Flag to prevent showing dialog multiple times
  bool _isDialogShowing = false;

  @override
  Widget build(BuildContext context) {
    final savedCarsState = ref.watch(savedCarsProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorDark,
      appBar: CustomAppBar(
        title: StringConstants.savedCars,
        isMainNavPage: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(savedCarsProvider.notifier).refresh();
        },
        child: Column(
          children: [
            // Show sync banner for guests
            if (authState.isGuest) _buildSyncBanner(context),
            // Saved cars list
            Expanded(child: _buildSavedCarsList(context, ref, savedCarsState)),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Listen to notification stream
    NotificationService().onNotificationReceived.listen((message) {
      if (message.data['type'] == 'price_change') {
        final carId = message.data['car_id'];
        final newPrice = double.tryParse(message.data['new_price'] ?? '');

        if (carId != null && newPrice != null) {
          // Update provider
          ref.read(savedCarsProvider.notifier).updateCarPrice(carId, newPrice);
        }
      }
    });
  }

  /// Build the sync banner for guest users
  Widget _buildSyncBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              StringConstants.loginToSync,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.push(RouteNames.login),
            child: const Text(StringConstants.login),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, car) {
    // Prevent showing dialog if already showing
    if (_isDialogShowing) return;

    _isDialogShowing =
        true; //////////////////////////////////////////////////////////////////////////////

    ConfirmationDialog.show(
      context,
      title: StringConstants.removeFromSaved,
      content: Text('Remove "${car.title}" from saved cars?'),
      onConfirm: () async {
        // Remove from SecureStore (and server in background)
        await ref.read(savedCarsProvider.notifier).removeSavedCar(car.id);

        // Show toast
        if (context.mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(StringConstants.removedFromSaved),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      onCancel: () {
        // Reset flag when dialog is cancelled
      },
    ).then((_) {
      // Reset flag after dialog closes (either confirm or cancel)
      _isDialogShowing = false;
    });
  }

  Widget _buildSavedCarsList(
    BuildContext context,
    WidgetRef ref,
    SavedCarsState state,
  ) {
    // Empty state
    if (state.cars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              StringConstants.noSavedCars,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    // Car list - simple ListView, no pull-to-refresh
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: state.cars.length,
      itemBuilder: (context, index) {
        final car = state.cars[index];
        return CarListItem(
          car: car,
          showSaveButton: false,
          showDeleteButton: true,
          onTap: () {
            context.push('/post/${car.id}');
          },
          onDelete: () => _showDeleteConfirmation(context, ref, car),
        );
      },
    );
  }
}

/// My Cars Page
/// Page displaying user's posted cars
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:turbo_car/presentation/widgets/common/custom_app_bar.dart';
import 'package:turbo_car/presentation/widgets/common/car_list_item.dart';
import 'package:turbo_car/data/providers/auth_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/router/route_names.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/providers.dart';
import '../../../data/models/car_model.dart';
import 'package:dio/dio.dart';

// State for my cars
class MyCarsState {
  final List<CarModel> cars;
  final bool isLoading;
  final String? error;

  MyCarsState({this.cars = const [], this.isLoading = false, this.error});

  MyCarsState copyWith({
    List<CarModel>? cars,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MyCarsState(
      cars: cars ?? this.cars,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Provider for my cars
class MyCarsNotifier extends StateNotifier<MyCarsState> {
  final DioClient _dioClient;

  MyCarsNotifier(this._dioClient) : super(MyCarsState());

  Future<void> fetchCars() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _dioClient.dio.get(ApiConstants.myListings);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final carsJson = data['data'] as List<dynamic>;
        final cars = carsJson
            .map((json) => CarModel.fromJson(json as Map<String, dynamic>))
            .toList();

        state = state.copyWith(cars: cars, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to load cars');
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['error'] ?? 'Failed to load cars',
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'An error occurred');
    }
  }

  Future<void> deleteCar(String carId) async {
    try {
      await _dioClient.dio.delete('${ApiConstants.cars}/$carId');
      // Refresh list after delete
      await fetchCars();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete car');
    }
  }
}

// Provider instance
final myCarsProvider = StateNotifierProvider<MyCarsNotifier, MyCarsState>((
  ref,
) {
  final dioClient = ref.watch(dioClientProvider);
  return MyCarsNotifier(dioClient);
});

class MyCarsPage extends ConsumerStatefulWidget {
  const MyCarsPage({super.key});

  @override
  ConsumerState<MyCarsPage> createState() => _MyCarsPageState();
}

class _MyCarsPageState extends ConsumerState<MyCarsPage> {
  @override
  void initState() {
    super.initState();
    // Fetch cars on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myCarsProvider.notifier).fetchCars();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final myCarsState = ref.watch(myCarsProvider);

    // If not authenticated, show login prompt
    if (!authState.isAuthenticated) {
      return Scaffold(
        backgroundColor: Theme.of(context).primaryColorDark,
        appBar: CustomAppBar(title: StringConstants.myCarsTitle),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.car_rental,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Please login to view your cars',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorDark,
      appBar: CustomAppBar(title: StringConstants.myCarsTitle),
      body: myCarsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : myCarsState.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    myCarsState.error!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        ref.read(myCarsProvider.notifier).fetchCars(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : myCarsState.cars.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    StringConstants.noCarsPosted,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.go(RouteNames.home),
                    icon: const Icon(Icons.add),
                    label: const Text('Post a Car'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 16),
              itemCount: myCarsState.cars.length,
              itemBuilder: (context, index) {
                final car = myCarsState.cars[index];
                return CarListItem(
                  car: car,
                  showSaveButton: false,
                  showDeleteButton: true,
                  onTap: () => context.push('/post/${car.id}'),
                  onDelete: () async {
                    // Show confirmation dialog
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Car'),
                        content: const Text(
                          'Are you sure you want to delete this car listing?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await ref.read(myCarsProvider.notifier).deleteCar(car.id);
                    }
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(RouteNames.home),
        child: const Icon(Icons.add),
      ),
    );
  }
}

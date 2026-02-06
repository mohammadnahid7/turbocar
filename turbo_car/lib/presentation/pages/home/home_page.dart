/// Home Page
/// Main page displaying car listings with search and filters
/// Data fetching happens after page initialization (like useEffect in React)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:turbo_car/core/theme/app_colors.dart';
import 'package:turbo_car/presentation/widgets/common/custom_button.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/car_provider.dart';
import '../../../data/providers/saved_cars_provider.dart';
import '../../../data/providers/navigation_provider.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/router/route_names.dart';
import '../../widgets/common/car_list_item.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/specific/filter_bottom_sheet.dart';
import '../../widgets/specific/image_carousel.dart';
import '../../widgets/specific/company_button_group.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  bool _hasFetchedInitialData = false;
  int _lastVisibleIndex = -1;

  @override
  void initState() {
    super.initState();
    // Data fetching will happen after first build (like useEffect)
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch data after widget is built (similar to useEffect in React)
  void _fetchDataIfNeeded({bool forceRefresh = false}) {
    if (!_hasFetchedInitialData || forceRefresh) {
      _hasFetchedInitialData = true;
      // Fetch data in background - page is already displayed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(carListProvider.notifier)
              .fetchCars(
                refresh: forceRefresh,
                showCachedWhileLoading: !forceRefresh,
              );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final carState = ref.watch(carListProvider);
    final navigationState = ref.watch(navigationProvider);

    // Fetch data when this page becomes visible (index 0 = Home)
    // Only fetch if we're switching TO this page, not if we're already on it
    if (navigationState.currentIndex == 0 && _lastVisibleIndex != 0) {
      _fetchDataIfNeeded(forceRefresh: _hasFetchedInitialData);
      _lastVisibleIndex = 0;
    } else if (navigationState.currentIndex != 0) {
      _lastVisibleIndex = navigationState.currentIndex;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 30),
            // Top Section (Welcome)
            Padding(
              padding: const EdgeInsets.fromLTRB(25.0, 10, 15.0, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hello, ${authState.user?.name ?? "Guest"}',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.lightBackground,
                          ),
                        ),
                        Text(
                          'Welcome to TurboCar',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.lightBackground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CustomButton.icon(
                    backgroundColor: Theme.of(context).dividerColor,
                    // borderSide: BorderSide(color: AppColors.lightBackground),
                    iconSize: 25,
                    icon: Icons.notifications,
                    onPressed: () {
                      context.push(RouteNames.notification);
                    },
                  ),
                ],
              ),
            ),
            // Bottom Section (White Background, Rounded Corners)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColorDark,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: Column(
                    children: [
                      // Search bar and filter button (stays at top, doesn't scroll)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          14.0,
                          16.0,
                          14.0,
                          16.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _searchController,
                                hint: StringConstants.search,
                                prefixIcon: const Icon(Icons.search),
                                textInputAction: TextInputAction.search,
                                onSubmitted: (value) {
                                  if (value.isEmpty) {
                                    ref
                                        .read(carListProvider.notifier)
                                        .fetchCars(refresh: true);
                                  } else {
                                    ref
                                        .read(carListProvider.notifier)
                                        .searchCars(value);
                                  }
                                },
                              ),
                            ),
                            CustomButton.icon(
                              backgroundColor: Theme.of(context).cardColor,
                              icon: Icons.filter_list,
                              borderSide: BorderSide(
                                color: Theme.of(context).dividerColor,
                              ),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) =>
                                      const FilterBottomSheet(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // Scrollable content with sticky header
                      Expanded(child: _buildStickyScrollView(carState)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the CustomScrollView with sticky header behavior
  Widget _buildStickyScrollView(CarListState carState) {
    final hasData = carState.cars.isNotEmpty || carState.hasCachedData;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(carListProvider.notifier).fetchCars(refresh: true);
      },
      child: CustomScrollView(
        slivers: [
          // Carousel - scrolls away normally
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: const ImageCarousel(images: ["aa", "bb", "cc"]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),

          // Company button group - STICKS at top when scrolled
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyCompanyHeaderDelegate(
              minHeight: 58,
              maxHeight: 58,
              child: Container(
                color: Theme.of(context).primaryColorDark,
                child: CompanyButtonGroup(),
              ),
            ),
          ),

          // Car list content
          _buildCarListSliver(carState, hasData, ref.watch(savedCarsProvider)),

          // Bottom padding for floating nav bar
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  /// Build the car list as a Sliver
  Widget _buildCarListSliver(
    CarListState carState,
    bool hasData,
    SavedCarsState savedCarsState,
  ) {
    // Loading state (no cached data)
    if (carState.isLoading && !hasData) {
      return const SliverFillRemaining(
        child: LoadingIndicator(message: StringConstants.loading),
      );
    }

    // Error state (no cached data)
    if (carState.error != null && !hasData) {
      return SliverFillRemaining(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text("No Car Found")],
        ),
      );
    }

    // Empty state
    if (carState.cars.isEmpty && !carState.isLoading) {
      return SliverFillRemaining(
        child: Center(child: Text(StringConstants.noCarsFound)),
      );
    }

    // Car list
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        addAutomaticKeepAlives:
            true, // Keep widgets alive to prevent image reloads
        (context, index) {
          if (index == carState.cars.length) {
            // Load more indicator
            if (carState.hasMore && !carState.isLoading) {
              Future.microtask(
                () => ref.read(carListProvider.notifier).loadMore(),
              );
            }
            return carState.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink();
          }

          final car = carState.cars[index];
          // Check if car is locally saved (SecureStore is source of truth)
          final isSaved = savedCarsState.isCarSaved(car.id);
          final displayCar = car.copyWith(isFavorited: isSaved);
          print(displayCar);

          return CarListItem(
            key: ValueKey(displayCar.id),
            car: displayCar,
            showSaveButton: true,
            onTap: () {
              context.push('/post/${displayCar.id}');
            },
            onSave: () async {
              final isCurrentlySaved = displayCar.isFavorited;
              // Optimistic update locally
              // ref.read(carListProvider.notifier).toggleLocalFavorite(car.id); // Not needed as we rely on SavedCarsProvider

              // Call API/Storage
              await ref
                  .read(savedCarsProvider.notifier)
                  .toggleSave(displayCar.id, car: displayCar);

              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isCurrentlySaved
                          ? StringConstants.removedFromSaved
                          : StringConstants.addedToSaved,
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          );
        },
        childCount: carState.cars.length + (carState.hasMore ? 1 : 0),
      ),
    );
  }
}

/// Delegate for sticky company button header
class _StickyCompanyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _StickyCompanyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyCompanyHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

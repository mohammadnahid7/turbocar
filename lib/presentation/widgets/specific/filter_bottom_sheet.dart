/// Filter Bottom Sheet
/// Filter options bottom sheet for car listings
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/custom_button.dart';
import '../../../data/providers/filter_provider.dart';
import '../../../data/providers/car_provider.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/app_constants.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  final List<String> categories = [
    StringConstants.sedan,
    StringConstants.suv,
    StringConstants.sports,
    StringConstants.hatchback,
    StringConstants.coupe,
    StringConstants.convertible,
    StringConstants.truck,
    StringConstants.van,
  ];
  final List<String> sortOptions = [
    StringConstants.priceHighToLow,
    StringConstants.priceLowToHigh,
    StringConstants.mileage,
    StringConstants.year,
  ];

  RangeValues _priceRange = RangeValues(
    AppConstants.minPrice.toDouble(),
    AppConstants.maxPrice.toDouble(),
  );

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(filterProvider);
    final carState = ref.watch(carListProvider);

    // Get unique cities from current car list
    final availableCities =
        carState.cars
            .where((car) => car.city.isNotEmpty)
            .map((car) => car.city)
            .toSet()
            .toList()
          ..sort();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColorDark,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        top: 10,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fixed Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                StringConstants.filter,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (filterState.hasFilters)
                TextButton(
                  onPressed: () {
                    ref.read(filterProvider.notifier).resetFilters();
                    ref.read(carListProvider.notifier).resetFilters();
                  },
                  child: Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // City dropdown (dynamic from car list)
                  if (availableCities.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue: filterState.city,
                      decoration: InputDecoration(
                        labelText: StringConstants.city,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Cities'),
                        ),
                        ...availableCities.map((city) {
                          return DropdownMenuItem(
                            value: city,
                            child: Text(city),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        ref.read(filterProvider.notifier).updateCity(value);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Category button group
                  Text(
                    StringConstants.category,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      final isSelected = filterState.model == category;
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          ref
                              .read(filterProvider.notifier)
                              .updateModel(selected ? category : null);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Price range slider
                  Text(
                    StringConstants.priceRange,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: AppConstants.minPrice.toDouble(),
                    max: AppConstants.maxPrice.toDouble(),
                    divisions: (AppConstants.maxPrice / AppConstants.priceStep)
                        .toInt(),
                    labels: RangeLabels(
                      '₩${(_priceRange.start / 10000).toInt()}만',
                      '₩${(_priceRange.end / 10000).toInt()}만',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _priceRange = values;
                      });
                      ref
                          .read(filterProvider.notifier)
                          .updatePriceRange(values.start, values.end);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Min: ₩${(_priceRange.start / 10000).toInt()}만'),
                      Text('Max: ₩${(_priceRange.end / 10000).toInt()}만'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sort options
                  Text(
                    StringConstants.sortBy,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sortOptions.map((option) {
                      final isSelected = filterState.sortBy == option;
                      return FilterChip(
                        label: Text(option),
                        selected: isSelected,
                        onSelected: (selected) {
                          ref
                              .read(filterProvider.notifier)
                              .updateSortBy(selected ? option : null);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Fixed Buttons (Footer)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton.outline(
                    onPressed: () {
                      ref.read(filterProvider.notifier).resetFilters();
                      ref.read(carListProvider.notifier).resetFilters();
                      Navigator.pop(context);
                    },
                    text: StringConstants.reset,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    onPressed: () {
                      // Apply filters to car list
                      final filters = ref.read(filterProvider).toQueryParams();
                      ref.read(carListProvider.notifier).applyFilters(filters);
                      Navigator.pop(context);
                    },
                    text: StringConstants.apply,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

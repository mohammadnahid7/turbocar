/// Company Button Group
/// Horizontal scrollable company filter buttons
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/filter_provider.dart';
import '../../../data/providers/car_provider.dart';
import '../../../core/constants/car_brands.dart';

class CompanyButtonGroup extends ConsumerWidget {
  const CompanyButtonGroup({super.key});

  // Use brands from constants plus All and Others
  static List<String> get companies => [
    'All',
    ...CarBrands.validBrands.take(18), // Show top 18
    'Others',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(filterProvider);

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: companies.length,
        itemBuilder: (context, index) {
          final company = companies[index];
          final isAll = company == 'All';
          final isSelected = isAll
              ? filterState.make == null
              : filterState.make == company;

          return Padding(
            padding: const EdgeInsets.only(right: 5),
            child: OutlinedButton(
              onPressed: () {
                if (company == 'Others') {
                  _showAllBrands(context, ref);
                  return;
                }

                // Update filter state
                final newMake = (isAll || isSelected) ? null : company;
                ref.read(filterProvider.notifier).updateMake(newMake);

                // Apply filters to car list
                final filters = ref.read(filterProvider).toQueryParams();
                ref.read(carListProvider.notifier).applyFilters(filters);
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                foregroundColor: isSelected
                    ? Colors.white
                    : Theme.of(context).appBarTheme.foregroundColor,
                textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isAll && company != 'Others') ...[
                    Image.asset(
                      CarBrands.getLogoPath(company) ?? '',
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(company),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAllBrands(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Brand',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: CarBrands.validBrands.length,
                itemBuilder: (context, index) {
                  final brand = CarBrands.validBrands[index];
                  return InkWell(
                    onTap: () {
                      ref.read(filterProvider.notifier).updateMake(brand);
                      final filters = ref.read(filterProvider).toQueryParams();
                      ref.read(carListProvider.notifier).applyFilters(filters);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            CarBrands.getLogoPath(brand) ?? '',
                            width: 40,
                            height: 40,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.directions_car),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            brand,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter Provider
/// State management for car filters using Riverpod
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Filter State
class FilterState {
  final String? city;
  final String? make;
  final String? model;
  final double? priceMin;
  final double? priceMax;
  final String? sortBy;

  FilterState({
    this.city,
    this.make,
    this.model,
    this.priceMin,
    this.priceMax,
    this.sortBy,
  });

  FilterState copyWith({
    String? city,
    String? make,
    String? model,
    double? priceMin,
    double? priceMax,
    String? sortBy,
  }) {
    return FilterState(
      city: city ?? this.city,
      make: make ?? this.make,
      model: model ?? this.model,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (city != null) params['city'] = city;
    if (make != null) params['make'] = make;
    if (model != null) params['model'] = model;
    if (priceMin != null) params['min_price'] = priceMin;
    if (priceMax != null) params['max_price'] = priceMax;

    // Map sort options
    if (sortBy != null) {
      if (sortBy == 'Price: High to Low') {
        params['sort_by'] = 'price_desc';
      } else if (sortBy == 'Price: Low to High') {
        params['sort_by'] = 'price_asc';
      } else if (sortBy == 'Year') {
        params['sort_by'] = 'year_desc';
      }
    }
    return params;
  }

  bool get hasFilters =>
      city != null ||
      make != null ||
      model != null ||
      priceMin != null ||
      priceMax != null ||
      sortBy != null;
}

// Filter Notifier
class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(FilterState());

  void updateCity(String? city) {
    state = FilterState(
      city: city,
      make: state.make,
      model: state.model,
      priceMin: state.priceMin,
      priceMax: state.priceMax,
      sortBy: state.sortBy,
    );
  }

  void updateMake(String? make) {
    state = FilterState(
      city: state.city,
      make: make,
      model: state.model,
      priceMin: state.priceMin,
      priceMax: state.priceMax,
      sortBy: state.sortBy,
    );
  }

  void updateModel(String? model) {
    state = FilterState(
      city: state.city,
      make: state.make,
      model: model,
      priceMin: state.priceMin,
      priceMax: state.priceMax,
      sortBy: state.sortBy,
    );
  }

  void updatePriceRange(double? min, double? max) {
    state = FilterState(
      city: state.city,
      make: state.make,
      model: state.model,
      priceMin: min,
      priceMax: max,
      sortBy: state.sortBy,
    );
  }

  void updateSortBy(String? sortBy) {
    state = FilterState(
      city: state.city,
      make: state.make,
      model: state.model,
      priceMin: state.priceMin,
      priceMax: state.priceMax,
      sortBy: sortBy,
    );
  }

  void resetFilters() {
    state = FilterState();
  }
}

// Filter Provider
final filterProvider = StateNotifierProvider<FilterNotifier, FilterState>((
  ref,
) {
  return FilterNotifier();
});

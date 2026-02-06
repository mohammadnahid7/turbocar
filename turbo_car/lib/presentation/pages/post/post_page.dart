/// Post Page
/// Page for posting a new car listing with complete form
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/post_car_provider.dart';
import '../../../data/providers/car_provider.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/constants/car_brands.dart';
import '../../../core/router/route_names.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_dropdown.dart';
import '../../widgets/common/image_picker_grid.dart';
import '../../../core/constants/korean_cities.dart';
import 'package:dropdown_search/dropdown_search.dart';

class PostPage extends ConsumerStatefulWidget {
  const PostPage({super.key});

  @override
  ConsumerState<PostPage> createState() => _PostPageState();
}

class _PostPageState extends ConsumerState<PostPage> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  late TextEditingController _carNameController;
  late TextEditingController _carModelController;
  late TextEditingController _mileageController;
  late TextEditingController _yearController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _colorController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;

  @override
  void initState() {
    super.initState();
    _carNameController = TextEditingController();
    _carModelController = TextEditingController();
    _mileageController = TextEditingController();
    _yearController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _colorController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
  }

  @override
  void dispose() {
    _carNameController.dispose();
    _carModelController.dispose();
    _mileageController.dispose();
    _yearController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _colorController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  // Car type options
  static const List<String> _carTypes = [
    'Sedan',
    'SUV',
    'Van',
    'Hatchback',
    'Coupe',
    'Truck',
    'Sports',
    'Convertible',
  ];

  // Fuel type options with backend mapping
  static const Map<String, String> _fuelTypes = {
    'Gasoline': 'petrol',
    'Electric': 'electric',
    'Diesel': 'diesel',
  };

  // Condition options
  static const List<String> _conditions = ['excellent', 'good', 'fair'];

  // Transmission options
  static const List<String> _transmissions = ['automatic', 'manual'];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final postState = ref.watch(postCarProvider);
    final postNotifier = ref.read(postCarProvider.notifier);

    // Listen for success/error messages
    ref.listen<PostCarState>(postCarProvider, (previous, next) {
      if (next.successMessage != null && previous?.successMessage == null) {
        // Navigate to success page
        context.go(RouteNames.postSuccess);
        // Refresh car list
        ref.read(carListProvider.notifier).fetchCars(refresh: true);
        // Clear form
        _clearForm();
        postNotifier.clearForm();
      }
      if (next.error != null && previous?.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    // If guest or not authenticated, show login prompt
    if (authState.isGuest || !authState.isAuthenticated) {
      return Scaffold(
        backgroundColor: Theme.of(context).primaryColorDark,
        appBar: CustomAppBar(
          title: StringConstants.postCarTitle,
          isMainNavPage: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  StringConstants.pleaseLoginToPost,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: StringConstants.loginOrSignup,
                  onPressed: () => context.push(RouteNames.login),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Authenticated user - show post form
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorDark,
      appBar: CustomAppBar(
        title: StringConstants.postCarTitle,
        isMainNavPage: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Car Type Dropdown (full width)
              CustomDropdown<String>(
                label: StringConstants.selectCarType,
                value: postState.carType.isEmpty ? null : postState.carType,
                items: _carTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) => postNotifier.updateCarType(value ?? ''),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please select a car type'
                    : null,
              ),
              const SizedBox(height: 16),

              // Row 2: Car Name (left) | Car Model (right)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: postState.carName.isEmpty
                          ? null
                          : postState.carName,
                      decoration: InputDecoration(
                        labelText: 'Car Brand',
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      items: CarBrands.validBrands.map((brand) {
                        final logoPath = CarBrands.getLogoPath(brand);
                        return DropdownMenuItem<String>(
                          value: brand,
                          child: Row(
                            children: [
                              if (logoPath != null) ...[
                                Image.asset(
                                  logoPath,
                                  width: 24,
                                  height: 24,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.directions_car,
                                        size: 24,
                                      ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Text(brand),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          postNotifier.updateCarName(value ?? ''),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: StringConstants.carModelLabel,
                      controller: _carModelController,
                      onChanged: (value) => postNotifier.updateCarModel(value),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 3: Fuel Type Radio Buttons (full width)
              Text(
                StringConstants.fuelType,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).appBarTheme.foregroundColor?.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _fuelTypes.entries
                      .map(
                        (entry) => _buildFuelRadio(
                          entry.key,
                          entry.value,
                          postState.fuelType,
                          postNotifier,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Row 4: Mileage (left) | Year (right)
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: StringConstants.mileageLabel,
                      controller: _mileageController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          postNotifier.updateMileage(int.tryParse(value)),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: StringConstants.yearLabel,
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          postNotifier.updateYear(int.tryParse(value)),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final year = int.tryParse(value);
                        if (year == null || year < 1900) return 'Invalid year';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Row 5: Image Upload (full width)
              ImagePickerGrid(
                images: postState.images,
                minImages: 1,
                maxImages: 10,
                onImageAdded: (image) => postNotifier.addImage(image),
                onImageRemoved: (index) => postNotifier.removeImage(index),
              ),
              const SizedBox(height: 16),

              // Row 6: Price (left) | Chat Only Checkbox (right)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: StringConstants.priceLabel,
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) =>
                          postNotifier.updatePrice(double.tryParse(value)),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) return 'Invalid price';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          value: postState.chatOnly,
                          onChanged: (value) =>
                              postNotifier.updateChatOnly(value ?? false),
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                        Expanded(
                          child: Text(
                            StringConstants.chatOnlyLabel,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).appBarTheme.foregroundColor,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // // Additional fields section
              // Text(
              //   'Additional Details',
              //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
              //     color: Theme.of(context).appBarTheme.foregroundColor,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              // const SizedBox(height: 12),

              // // Condition & Transmission dropdowns
              // Row(
              //   children: [
              //     Expanded(
              //       child: CustomDropdown<String>(
              //         hint: StringConstants.conditionLabel,
              //         value: postState.condition.isEmpty
              //             ? null
              //             : postState.condition,
              //         items: _conditions
              //             .map(
              //               (c) => DropdownMenuItem(
              //                 value: c,
              //                 child: Text(c[0].toUpperCase() + c.substring(1)),
              //               ),
              //             )
              //             .toList(),
              //         onChanged: (value) =>
              //             postNotifier.updateCondition(value ?? 'good'),
              //       ),
              //     ),
              //     const SizedBox(width: 12),
              //     Expanded(
              //       child: CustomDropdown<String>(
              //         hint: StringConstants.transmissionLabel,
              //         value: postState.transmission.isEmpty
              //             ? null
              //             : postState.transmission,
              //         items: _transmissions
              //             .map(
              //               (t) => DropdownMenuItem(
              //                 value: t,
              //                 child: Text(t[0].toUpperCase() + t.substring(1)),
              //               ),
              //             )
              //             .toList(),
              //         onChanged: (value) =>
              //             postNotifier.updateTransmission(value ?? 'automatic'),
              //       ),
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 16),

              // // Color field
              // CustomTextField(
              //   hint: StringConstants.colorLabel,
              //   controller: _colorController,
              //   onChanged: (value) => postNotifier.updateColor(value),
              //   validator: (value) =>
              //       value == null || value.isEmpty ? 'Required' : null,
              // ),
              // const SizedBox(height: 16),

              // City & State
              Row(
                children: [
                  Expanded(
                    child: DropdownSearch<String>(
                      items: (filter, loadProps) => koreanCities,
                      decoratorProps: DropDownDecoratorProps(
                        decoration: InputDecoration(
                          labelText: StringConstants.cityLabel,
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          decoration: InputDecoration(
                            hintText: 'Search city...',
                            prefixIcon: Icon(Icons.search),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                        ),
                        menuProps: MenuProps(
                          borderRadius: BorderRadius.circular(12),
                          backgroundColor: Theme.of(context).cardColor,
                        ),
                      ),
                      selectedItem: postState.city.isEmpty
                          ? null
                          : postState.city,
                      onChanged: (value) {
                        if (value != null) {
                          postNotifier.updateCity(value);
                        }
                      },
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                  // const SizedBox(width: 12),
                  // Expanded(
                  //   child: CustomTextField(
                  //     hint: StringConstants.stateLabel,
                  //     controller: _stateController,
                  //     onChanged: (value) => postNotifier.updateState(value),
                  //     validator: (value) =>
                  //         value == null || value.isEmpty ? 'Required' : null,
                  //   ),
                  // ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              CustomTextField(
                hint: StringConstants.descriptionLabel,
                controller: _descriptionController,
                maxLines: 4,
                borderRadius: 10,
                onChanged: (value) => postNotifier.updateDescription(value),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (value.length < 20) return 'Min 20 characters';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Row 7: Post Button (full width)
              CustomButton(
                text: StringConstants.postButton,
                isLoading: postState.isLoading,
                onPressed: () => _submitForm(postNotifier),
              ),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFuelRadio(
    String label,
    String value,
    String selectedValue,
    PostCarNotifier notifier,
  ) {
    final isSelected = selectedValue == value;
    return GestureDetector(
      onTap: () => notifier.updateFuelType(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).appBarTheme.foregroundColor?.withOpacity(0.5),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).appBarTheme.foregroundColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitForm(PostCarNotifier notifier) {
    if (_formKey.currentState?.validate() ?? false) {
      notifier.submitCar();
    }
  }

  void _clearForm() {
    _carNameController.clear();
    _carModelController.clear();
    _mileageController.clear();
    _yearController.clear();
    _priceController.clear();
    _descriptionController.clear();
    _colorController.clear();
    _cityController.clear();
    _stateController.clear();
  }
}

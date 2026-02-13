/// Car Brands Constants
/// List of valid car brands with logo asset paths
library;

class CarBrand {
  final String name;
  final String logoAsset;

  const CarBrand(this.name, this.logoAsset);
}

class CarBrands {
  /// List of valid car brand names
  static const List<String> validBrands = [
    'Hyundai',
    'Kia',
    'Genesis',
    'Chevrolet',
    'Renault Korea',
    'Mercedes Benz',
    'BMW',
    'Audi',
    'Land Rover',
    'Tesla',
    'Volkswagen',
    'Volvo',
    'Lexus',
    'Toyota',
    'Honda',
    'Ford',
    'Jeep',
    'Porsche',
  ];

  /// List of car brands with logo assets
  static const List<CarBrand> brands = [
    CarBrand('Hyundai', 'assets/logos/hyundai.png'),
    CarBrand('Kia', 'assets/logos/kia.png'),
    CarBrand('Genesis', 'assets/logos/genesis.png'),
    CarBrand('Chevrolet', 'assets/logos/chevrolet.png'),
    CarBrand('Renault Korea', 'assets/logos/renault.png'),
    CarBrand('Mercedes Benz', 'assets/logos/mercedes.png'),
    CarBrand('BMW', 'assets/logos/bmw.png'),
    CarBrand('Audi', 'assets/logos/audi.png'),
    CarBrand('Land Rover', 'assets/logos/landrover.png'),
    CarBrand('Tesla', 'assets/logos/tesla.png'),
    CarBrand('Volkswagen', 'assets/logos/volkswagen.png'),
    CarBrand('Volvo', 'assets/logos/volvo.png'),
    CarBrand('Lexus', 'assets/logos/lexus.png'),
    CarBrand('Toyota', 'assets/logos/toyota.png'),
    CarBrand('Honda', 'assets/logos/honda.png'),
    CarBrand('Ford', 'assets/logos/ford.png'),
    CarBrand('Jeep', 'assets/logos/jeep.png'),
    CarBrand('Porsche', 'assets/logos/porsche.png'),
  ];

  /// Check if a brand is valid
  static bool isValid(String brand) {
    return validBrands.contains(brand) || brand == 'Other';
  }

  /// Get logo asset path for a brand
  static String? getLogoPath(String brandName) {
    try {
      return brands.firstWhere((b) => b.name == brandName).logoAsset;
    } catch (_) {
      return null;
    }
  }
}

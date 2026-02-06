# Additional Bug Fixes - Instructions for Antigravity Claude

## Overview

The user has reported 5 additional issues/enhancements that need implementation. Each requires careful analysis and proper implementation without assuming project structure.

---

## Bug 1: Fix Filter Bottom Sheet Overflow and Functionality

### Current Problems
1. "Column overflowed by 59 pixels" error in filter bottom sheet
2. City dropdown should only show cities from current car list (not all 150+ cities)
3. Category/other filters should only show options present in current cars
4. Price filters (high/low, range) need to work
5. Apply button should actually filter the car list

### Implementation Instructions

#### Step 1: Fix Overflow Error

**Analyze the Filter Bottom Sheet:**
1. Locate the filter bottom sheet widget
2. Identify which column/widget is overflowing
3. Common causes:
   - Fixed height content exceeding screen space
   - No scrolling enabled
   - Too many widgets in a Column without constraints

**Fix Approaches:**

**Option A: Make Content Scrollable**
- Wrap the Column with SingleChildScrollView
- Set proper constraints on BottomSheet height
- Example structure:
  ```
  BottomSheet(
    child: SingleChildScrollView(
      child: Column(
        children: [...filter options]
      )
    )
  )
  ```

**Option B: Use Flexible/Expanded Properly**
- Ensure dropdowns don't have fixed heights that cause overflow
- Use Flexible or Expanded where appropriate
- Remove hardcoded heights if present

**Option C: Adjust BottomSheet Height**
- Increase maxChildSize in DraggableScrollableSheet if used
- Or set appropriate height in showModalBottomSheet

**Step 2: Implement Dynamic City List**

**Current Issue:** Shows all 150+ cities regardless of actual cars

**Required Solution:** Only show cities where cars exist

**Implementation:**

1. **Get unique cities from current car list:**
   - When loading cars, extract unique city values
   - Store in a Set or List for filter options
   - Update whenever car list changes

2. **Filter logic:**
   ```
   In car list state/controller:
   
   List<Car> cars = [...all cars from API];
   
   Set<String> getAvailableCities() {
     return cars.map((car) => car.city).toSet();
   }
   
   List<String> cityFilterOptions = getAvailableCities().toList();
   ```

3. **Update city dropdown in filter sheet:**
   - Replace hardcoded city list with dynamic `cityFilterOptions`
   - Sort alphabetically for better UX
   - Update when car list changes

**Step 3: Implement Dynamic Category/Make Options**

**Same approach as cities:**

1. **Extract unique makes/brands:**
   ```
   Set<String> getAvailableMakes() {
     return cars.map((car) => car.make).toSet();
   }
   ```

2. **Extract unique fuel types:**
   ```
   Set<String> getAvailableFuelTypes() {
     return cars.map((car) => car.fuelType).toSet();
   }
   ```

3. **Extract unique conditions:**
   ```
   Set<String> getAvailableConditions() {
     return cars.where((car) => car.condition != null)
       .map((car) => car.condition!)
       .toSet();
   }
   ```

4. **Update all filter dropdowns:**
   - Use these dynamic lists instead of static ones
   - Only show options that exist in current data

**Step 4: Implement Price Sorting**

**Price High to Low / Low to High:**

1. **Add sort option in filter sheet:**
   - Radio buttons or dropdown: "Price: Low to High" / "Price: High to Low"
   - Store selected sort order in state

2. **Apply sorting to car list:**
   ```
   When applying filter:
   
   if (sortOrder == 'low_to_high') {
     filteredCars.sort((a, b) => a.price.compareTo(b.price));
   } else if (sortOrder == 'high_to_low') {
     filteredCars.sort((a, b) => b.price.compareTo(a.price));
   }
   ```

**Step 5: Implement Price Range Filter**

**Add price range slider:**

1. **Find min and max prices from car list:**
   ```
   double minPrice = cars.map((c) => c.price).reduce(min);
   double maxPrice = cars.map((c) => c.price).reduce(max);
   ```

2. **Add RangeSlider widget in filter sheet:**
   - Min value: `minPrice`
   - Max value: `maxPrice`
   - Current range: user-selected values
   - Show selected range as text (e.g., "$10,000 - $50,000")

3. **Apply price range filter:**
   ```
   filteredCars = cars.where((car) => 
     car.price >= selectedMinPrice && 
     car.price <= selectedMaxPrice
   ).toList();
   ```

**Step 6: Implement Complete Filter Logic**

**When "Apply" button is clicked:**

1. **Collect all filter criteria:**
   - Selected cities
   - Selected makes/brands
   - Selected fuel types
   - Selected conditions
   - Price range (min/max)
   - Sort order

2. **Apply filters sequentially:**
   ```
   Start with all cars:
   List<Car> filtered = List.from(allCars);
   
   If city filter selected:
     filtered = filtered.where((car) => selectedCities.contains(car.city));
   
   If make filter selected:
     filtered = filtered.where((car) => selectedMakes.contains(car.make));
   
   If fuel type filter selected:
     filtered = filtered.where((car) => selectedFuelTypes.contains(car.fuelType));
   
   If condition filter selected:
     filtered = filtered.where((car) => car.condition != null && 
       selectedConditions.contains(car.condition));
   
   Apply price range:
     filtered = filtered.where((car) => 
       car.price >= minPrice && car.price <= maxPrice);
   
   Apply sorting:
     if (sortOrder == 'low_to_high') filtered.sort(...);
   ```

3. **Update UI with filtered results:**
   - Update state/provider with filtered list
   - Close bottom sheet
   - Show filtered cars on homepage

4. **Handle empty results:**
   - If `filtered.isEmpty`, show "No cars match your filters"
   - Offer "Clear Filters" option

**Step 7: Add Clear/Reset Filters**

1. **Add "Clear Filters" button in bottom sheet**
2. **On click:**
   - Reset all filter selections to default
   - Reset price range to full range
   - Reset sort order
   - Show all cars

**Step 8: Persist Filter State**

**Optional but recommended:**

1. Store filter criteria in state management
2. When returning to homepage, filters remain applied
3. Show active filter indicator (e.g., "3 filters active")
4. Clear on logout or app restart

**Questions to Ask:**
- "Should filters be ANDed (all conditions must match) or ORed (any condition matches)?"
- "Should price range show won (₩) or dollar ($) symbol?"
- "Should we save last used filters for next app session?"

---

## Bug 2: Implement Working Search Bar

### Current Problem
Search bar exists but doesn't function.

### Required Solution
- User types search query in search bar
- User presses Enter/submit
- Show only cars where title contains the search keyword
- No real-time search (only on Enter)

### Implementation Instructions

**Step 1: Locate Search Bar Widget**

1. Find the search bar/TextField on homepage
2. Check if it's in AppBar or separate widget
3. Identify current implementation (if any)

**Step 2: Add Search Functionality**

**Update TextField:**

1. **Add TextEditingController:**
   ```
   Create controller to get search text:
   final searchController = TextEditingController();
   ```

2. **Add onSubmitted callback:**
   ```
   TextField(
     controller: searchController,
     onSubmitted: (value) {
       _performSearch(value);
     },
     decoration: InputDecoration(
       hintText: 'Search cars...',
       suffixIcon: IconButton(
         icon: Icon(Icons.search),
         onPressed: () {
           _performSearch(searchController.text);
         },
       ),
     ),
   )
   ```

**Step 3: Implement Search Logic**

**Create search function:**

```
void _performSearch(String query) {
  if (query.isEmpty) {
    // Show all cars
    setState(() {
      displayedCars = allCars;
    });
    return;
  }
  
  // Filter cars by title containing query (case-insensitive)
  final results = allCars.where((car) {
    return car.title.toLowerCase().contains(query.toLowerCase());
  }).toList();
  
  setState(() {
    displayedCars = results;
    currentSearchQuery = query;
  });
  
  // Show result count
  if (results.isEmpty) {
    // Show "No results found for '{query}'"
  }
}
```

**Step 4: Handle Search State**

1. **Track search state:**
   - Store current search query
   - Know if search is active
   - Show clear/cancel button when searching

2. **Add clear search functionality:**
   ```
   void _clearSearch() {
     searchController.clear();
     setState(() {
       displayedCars = allCars;
       currentSearchQuery = null;
     });
   }
   ```

3. **Show clear button when searching:**
   ```
   suffixIcon: currentSearchQuery != null
     ? IconButton(
         icon: Icon(Icons.clear),
         onPressed: _clearSearch,
       )
     : Icon(Icons.search)
   ```

**Step 5: Improve Search Experience**

**Enhancements:**

1. **Search across multiple fields:**
   ```
   Search in: title, make, model, description
   
   car.title.contains(query) ||
   car.make.contains(query) ||
   car.model.contains(query) ||
   car.description.contains(query)
   ```

2. **Show search indicator:**
   - While searching (if API search), show loading
   - After search, show "X results for 'query'"

3. **Handle no results:**
   - Show empty state with suggestion
   - "Try different keywords" or "Clear filters"

4. **Combine with filters:**
   - Search should work with active filters
   - Apply filters first, then search within results

**Step 6: Optional Backend Search**

**If car list is very large:**

1. **Create API endpoint:**
   - `GET /api/cars/search?q={query}`
   - Backend searches database
   - Returns matching cars

2. **Call from Flutter:**
   ```
   Future<List<Car>> searchCars(String query) async {
     final response = await api.get('/cars/search?q=$query');
     return (response.data as List).map((json) => Car.fromJson(json)).toList();
   }
   ```

3. **Benefits:**
   - Faster for large datasets
   - Can search across more complex criteria
   - Reduces data transfer

**Questions to Ask:**
- "Should search work with current filters, or reset filters when searching?"
- "Search only in title, or also in make/model/description?"
- "Should we implement backend search API or client-side filtering?"

---

## Bug 3: Post Page Improvements

### Bug 3A: City Field as Searchable Dropdown

**Current Problem:** City is a text input field

**Required Solution:**
- Dropdown with search bar at top
- Search bar is fixed (doesn't scroll)
- City list scrolls below search bar
- Only predefined cities acceptable

**Implementation Instructions:**

**Step 1: Choose Implementation Approach**

**Option A: Use Package (Recommended)**
- Package: `dropdown_search` or `searchable_dropdown`
- Benefits: Built-in search, scrolling, customization
- Easy to implement

**Option B: Custom Implementation**
- Build custom bottom sheet/dialog
- Fixed search TextField at top
- Scrollable ListView below
- More control but more work

**Step 2: Implement with dropdown_search Package**

1. **Add package to pubspec.yaml:**
   ```
   dependencies:
     dropdown_search: ^latest_version
   ```

2. **Replace city TextField:**
   ```
   Use DropdownSearch<String> widget:
   
   DropdownSearch<String>(
     items: koreanCitiesList, // Full list of Korean cities
     dropdownDecoratorProps: DropDownDecoratorProps(
       decoration: InputDecoration(
         labelText: "City",
         hintText: "Select your city",
       ),
     ),
     popupProps: PopupProps.menu(
       showSearchBox: true, // Enable search
       searchFieldProps: TextFieldProps(
         decoration: InputDecoration(
           hintText: "Search city...",
         ),
       ),
     ),
     onChanged: (value) {
       setState(() => selectedCity = value);
     },
   )
   ```

**Step 3: Create Korean Cities List**

**Decide on city list source:**

**Option A: Hardcoded list in code**
```
Create constant list of major Korean cities:

const List<String> koreanCities = [
  'Seoul',
  'Busan',
  'Incheon',
  'Daegu',
  'Daejeon',
  'Gwangju',
  'Ulsan',
  'Suwon',
  // ... more cities (ask user for full list or major ones only)
];
```

**Option B: Load from JSON asset**
```
Create assets/data/korean_cities.json:
{
  "cities": ["Seoul", "Busan", ...]
}

Load in app:
final cities = await loadCitiesFromAsset();
```

**Option C: Fetch from API**
```
GET /api/cities endpoint returns:
{
  "cities": ["Seoul", "Busan", ...]
}

Benefits: Can update without app update
```

**Step 4: Validate City Selection**

**Frontend validation:**
```
On form submit:
if (selectedCity == null || !koreanCities.contains(selectedCity)) {
  Show error: "Please select a valid city"
  return;
}
```

**Backend validation:**
```
In car creation endpoint:
if (!isValidCity(car.city)) {
  return 400 Bad Request: "Invalid city"
}

func isValidCity(city string) bool {
  validCities := []string{"Seoul", "Busan", ...}
  return contains(validCities, city)
}
```

**Step 5: Ensure Consistency Across App**

1. **Post page:** Searchable dropdown (implemented above)
2. **Filter page:** Regular dropdown (from available cities in cars)
3. **Car details:** Display city name (no input)
4. **Backend:** Validate against same city list

**Create shared constant:**
```
In a constants file:

class AppConstants {
  static const List<String> koreanCities = [
    'Seoul', 'Busan', ...
  ];
}

Use everywhere:
- Post page dropdown
- Backend validation
- Anywhere cities are referenced
```

---

### Bug 3B: Car Brand/Make as Dropdown with Logos

**Current Problem:** Car make/brand is text input

**Required Solution:**
- Dropdown with specific car brands only
- Each brand shows logo on the left
- Only these brands acceptable in app and server

**Implementation Instructions:**

**Step 1: Define Car Brands List**

**Create structured data:**

```
class CarBrand {
  final String name;
  final String logoAsset; // or logoUrl
  
  const CarBrand(this.name, this.logoAsset);
}

const List<CarBrand> carBrands = [
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
```

**Step 2: Obtain Car Brand Logos**

**Where to get logos:**

1. **Free sources:**
   - Car manufacturer websites (official logos)
   - Icons8, Flaticon (search "car logos")
   - Wikipedia (brand logos)

2. **Format:**
   - PNG with transparent background
   - Square aspect ratio (1:1)
   - Size: 512x512 or similar
   - Optimize file size

3. **Add to project:**
   ```
   Create folder: assets/logos/
   Add files: hyundai.png, kia.png, etc.
   
   Update pubspec.yaml:
   flutter:
     assets:
       - assets/logos/
   ```

**Step 3: Implement Dropdown with Logos**

**Replace make/brand TextField:**

```
Use DropdownButtonFormField with custom items:

DropdownButtonFormField<String>(
  decoration: InputDecoration(
    labelText: 'Car Brand',
  ),
  value: selectedBrand,
  items: carBrands.map((brand) {
    return DropdownMenuItem<String>(
      value: brand.name,
      child: Row(
        children: [
          Image.asset(
            brand.logoAsset,
            width: 32,
            height: 32,
          ),
          SizedBox(width: 12),
          Text(brand.name),
        ],
      ),
    );
  }).toList(),
  onChanged: (value) {
    setState(() => selectedBrand = value);
  },
)
```

**Step 4: Validate Brand Selection**

**Frontend:**
```
On submit:
if (selectedBrand == null || !carBrands.any((b) => b.name == selectedBrand)) {
  Show error: "Please select a car brand"
}
```

**Backend:**
```
Create validation function:

func isValidCarBrand(brand string) bool {
  validBrands := []string{
    "Hyundai", "Kia", "Genesis", "Chevrolet",
    "Renault Korea", "Mercedes Benz", "BMW", "Audi",
    "Land Rover", "Tesla", "Volkswagen", "Volvo",
    "Lexus", "Toyota", "Honda", "Ford", "Jeep", "Porsche",
  }
  return contains(validBrands, brand)
}

In car creation endpoint:
if !isValidCarBrand(car.Make) {
  return 400: "Invalid car brand"
}
```

**Step 5: Ensure Consistency**

**Create shared constant for brand names:**

```
In constants file:

class CarBrands {
  static const List<String> validBrands = [
    'Hyundai', 'Kia', 'Genesis', 'Chevrolet',
    'Renault Korea', 'Mercedes Benz', 'BMW', 'Audi',
    'Land Rover', 'Tesla', 'Volkswagen', 'Volvo',
    'Lexus', 'Toyota', 'Honda', 'Ford', 'Jeep', 'Porsche',
  ];
}

Use in:
- Flutter app (post page, filters, brand buttons)
- Backend validation
- Database constraints (optional ENUM)
```

**Step 6: Consider "Other" Option**

**If user's car brand not in list:**

1. **Add "Other" option:**
   ```
   CarBrand('Other', 'assets/logos/other.png'),
   ```

2. **Show text field if "Other" selected:**
   ```
   if (selectedBrand == 'Other') {
     Show TextField to enter custom brand
   }
   ```

3. **Handle in backend:**
   - Accept "Other" as valid brand
   - Store custom brand in separate field if needed

**Questions to Ask:**
- "Should we add an 'Other' option for brands not in the list?"
- "Do you have logo files, or should I help find/download them?"
- "Should the brand list be fetched from API or hardcoded in app?"

---

## Bug 4: Homepage Brand Filter Buttons

### Current Problem
Brand buttons exist but don't work properly or don't match the correct brand list.

### Required Solution
- Brand buttons should match the same 18 brands from post page
- Clicking a brand filters cars to show only that brand
- Add "Others" button for cars with brands not in the main list
- Buttons should be functional

### Implementation Instructions

**Step 1: Update Brand Button List**

1. **Find homepage brand buttons**
2. **Replace with the same 18 brands:**
   ```
   Use CarBrands.validBrands constant (same as post page)
   
   final List<String> brandButtons = [
     'Hyundai', 'Kia', 'Genesis', 'Chevrolet',
     'Renault Korea', 'Mercedes Benz', 'BMW', 'Audi',
     'Land Rover', 'Tesla', 'Volkswagen', 'Volvo',
     'Lexus', 'Toyota', 'Honda', 'Ford', 'Jeep', 'Porsche',
     'Others', // Add this
   ];
   ```

3. **Ensure consistency:**
   - Use same constant as post page dropdown
   - Don't duplicate brand lists

**Step 2: Implement Brand Filtering**

**On brand button click:**

```
void filterByBrand(String brand) {
  if (brand == 'Others') {
    // Show cars with brands NOT in main list
    final filteredCars = allCars.where((car) {
      return !CarBrands.validBrands.contains(car.make);
    }).toList();
    
    setState(() {
      displayedCars = filteredCars;
      selectedBrand = 'Others';
    });
  } else {
    // Show cars with selected brand
    final filteredCars = allCars.where((car) {
      return car.make == brand;
    }).toList();
    
    setState(() {
      displayedCars = filteredCars;
      selectedBrand = brand;
    });
  }
}
```

**Step 3: Visual Feedback**

**Show which brand is selected:**

1. **Highlight selected button:**
   ```
   Button appearance:
   - Selected: Different color/background
   - Unselected: Default appearance
   
   Container(
     decoration: BoxDecoration(
       color: selectedBrand == brand ? primaryColor : Colors.grey[200],
       borderRadius: BorderRadius.circular(20),
     ),
     child: Text(
       brand,
       style: TextStyle(
         color: selectedBrand == brand ? Colors.white : Colors.black,
       ),
     ),
   )
   ```

2. **Show count:**
   ```
   Display number of cars for each brand:
   
   "Hyundai (15)" // 15 cars available
   "Kia (8)"
   "Others (3)"
   ```

**Step 4: Add "All" or "Clear" Option**

**Allow user to see all cars again:**

1. **Add "All" button at start:**
   ```
   ['All', 'Hyundai', 'Kia', ...]
   ```

2. **On click:**
   ```
   if (brand == 'All') {
     setState(() {
       displayedCars = allCars;
       selectedBrand = null;
     });
   }
   ```

**Step 5: Handle Empty Results**

**If no cars for selected brand:**

```
if (filteredCars.isEmpty) {
  Show message: "No {brand} cars available"
  Show button: "View all cars"
}
```

**Step 6: Optimize Brand Buttons Layout**

**If 19 buttons (18 brands + Others) don't fit:**

**Option A: Horizontal Scrolling**
```
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: brandButtons.map((brand) => 
      BrandButton(brand)
    ).toList(),
  ),
)
```

**Option B: Show Most Popular**
```
Show only 5-6 most popular brands as buttons
Add "More" dropdown for rest
```

**Option C: Wrap Layout**
```
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: brandButtons.map((brand) => 
    BrandButton(brand)
  ).toList(),
)
```

**Step 7: Combine with Other Filters**

**If user has filters active:**

1. **Apply brand filter on top of existing filters:**
   ```
   Start with: filteredByPrice/Location/etc.
   Then: Filter by brand
   ```

2. **Or reset other filters when brand selected:**
   ```
   Clicking brand clears price/location filters
   Shows only brand-filtered results
   ```

**Questions to Ask:**
- "Should brand filtering work with other active filters, or reset them?"
- "How should we handle brands with 0 cars - hide button or disable it?"
- "Should 'Others' be a separate button or grouped differently?"

---

## Bug 5: User Profile Settings/Edit Page

### Current Problem
No profile edit functionality exists.

### Required Solution
Create new profile settings page with:
- Profile image with upload button
- Editable: Name, DOB, Gender
- Read-only: Phone, Email
- Save button (shows only when changes made)
- Update profile on server

### Implementation Instructions

**Step 1: Create Profile Settings Page**

1. **Create new page/screen:**
   - Name: ProfileSettingsPage, EditProfilePage, or similar
   - Add to navigation routes

2. **Navigate from profile page:**
   - Find edit button in profile page
   - On click: Navigate to settings page
   ```
   Navigator.push(
     context,
     MaterialPageRoute(
       builder: (context) => ProfileSettingsPage(),
     ),
   );
   ```

**Step 2: Design Page Layout**

**Top to bottom structure:**

1. **AppBar:**
   - Title: "Edit Profile" or "Profile Settings"
   - Back button
   - Optional: Save button here instead of bottom

2. **Profile Image Section:**
   - Circular profile image (current or default)
   - "Change Photo" button below or overlay icon
   - On tap: Open image picker

3. **Editable Fields:**
   - Name (TextField with current value)
   - Date of Birth (DatePicker or TextField with calendar icon)
   - Gender (Dropdown: Male, Female, Other, Prefer not to say)

4. **Read-only Fields:**
   - Phone Number (disabled TextField or just display text)
   - Email (disabled TextField or just display text)

5. **Save Button:**
   - Bottom of screen or in AppBar
   - Enabled/visible only when changes detected
   - Loading indicator when saving

**Step 3: Fetch Current User Profile**

**On page load:**

1. **Call API to get user details:**
   ```
   Endpoint: GET /api/users/me or /api/users/{userId}
   
   Response:
   {
     "id": "...",
     "name": "John Doe",
     "email": "john@example.com",
     "phone": "+821012345678",
     "date_of_birth": "1990-05-15",
     "gender": "male",
     "profile_image": "https://..."
   }
   ```

2. **Populate fields with current data:**
   ```
   nameController.text = user.name;
   selectedDOB = DateTime.parse(user.dateOfBirth);
   selectedGender = user.gender;
   profileImageUrl = user.profileImage;
   phoneNumber = user.phone; // Display only
   email = user.email; // Display only
   ```

**Step 4: Implement Profile Image Upload**

**When "Change Photo" clicked:**

1. **Show image source options:**
   ```
   Bottom sheet or dialog:
   - Take Photo (camera)
   - Choose from Gallery
   - Cancel
   ```

2. **Pick image:**
   ```
   Use image_picker package:
   
   final ImagePicker picker = ImagePicker();
   final XFile? image = await picker.pickImage(
     source: ImageSource.gallery, // or .camera
     maxWidth: 1024,
     maxHeight: 1024,
     imageQuality: 85,
   );
   ```

3. **Upload to server:**
   ```
   Option A: Upload immediately
   - Send to API: POST /api/users/me/profile-image
   - Get back image URL
   - Update user profile with new URL
   
   Option B: Upload on save
   - Store image locally first
   - Upload when user clicks "Save Changes"
   - Update profile with image URL + other fields
   ```

4. **Update UI:**
   ```
   setState(() {
     profileImageFile = File(image.path);
     hasChanges = true; // Show save button
   });
   ```

**Step 5: Implement Editable Fields**

**Name Field:**
```
TextFormField(
  controller: nameController,
  decoration: InputDecoration(
    labelText: 'Name',
  ),
  onChanged: (value) {
    setState(() => hasChanges = true);
  },
)
```

**Date of Birth Field:**
```
GestureDetector(
  onTap: () async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDOB ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        selectedDOB = date;
        hasChanges = true;
      });
    }
  },
  child: AbsorbPointer(
    child: TextFormField(
      decoration: InputDecoration(
        labelText: 'Date of Birth',
        suffixIcon: Icon(Icons.calendar_today),
      ),
      controller: TextEditingController(
        text: selectedDOB != null 
          ? DateFormat('yyyy-MM-dd').format(selectedDOB!)
          : '',
      ),
    ),
  ),
)
```

**Gender Field:**
```
DropdownButtonFormField<String>(
  value: selectedGender,
  decoration: InputDecoration(
    labelText: 'Gender',
  ),
  items: ['Male', 'Female', 'Other', 'Prefer not to say']
    .map((gender) => DropdownMenuItem(
      value: gender.toLowerCase(),
      child: Text(gender),
    ))
    .toList(),
  onChanged: (value) {
    setState(() {
      selectedGender = value;
      hasChanges = true;
    });
  },
)
```

**Step 6: Implement Read-only Fields**

**Phone Number (Read-only):**
```
TextFormField(
  initialValue: phoneNumber,
  decoration: InputDecoration(
    labelText: 'Phone Number',
    enabled: false, // Grayed out
  ),
  readOnly: true,
)

// Or just display as text:
ListTile(
  leading: Icon(Icons.phone),
  title: Text('Phone Number'),
  subtitle: Text(phoneNumber),
)
```

**Email (Read-only):**
```
TextFormField(
  initialValue: email,
  decoration: InputDecoration(
    labelText: 'Email',
    enabled: false,
  ),
  readOnly: true,
)
```

**Step 7: Implement Change Detection**

**Track if any field changed:**

```
State variables:
- bool hasChanges = false;
- Original values for comparison

On any field change:
- Set hasChanges = true

To be precise, compare values:
bool hasChanges() {
  return nameController.text != originalName ||
         selectedDOB != originalDOB ||
         selectedGender != originalGender ||
         profileImageFile != null;
}
```

**Step 8: Implement Save Functionality**

**When "Save Changes" clicked:**

1. **Validate fields:**
   ```
   if (nameController.text.trim().isEmpty) {
     Show error: "Name cannot be empty"
     return;
   }
   
   if (selectedDOB == null) {
     Show error: "Please select date of birth"
     return;
   }
   ```

2. **Upload profile image (if changed):**
   ```
   String? newProfileImageUrl;
   
   if (profileImageFile != null) {
     Show loading indicator
     
     newProfileImageUrl = await uploadProfileImage(profileImageFile);
     
     if (newProfileImageUrl == null) {
       Show error: "Failed to upload image"
       return;
     }
   }
   ```

3. **Update user profile via API:**
   ```
   Call: PUT /api/users/me or PATCH /api/users/{userId}
   
   Request body:
   {
     "name": nameController.text,
     "date_of_birth": selectedDOB.toIso8601String(),
     "gender": selectedGender,
     "profile_image": newProfileImageUrl ?? currentProfileImageUrl
   }
   ```

4. **Handle response:**
   ```
   Success:
   - Show success message: "Profile updated successfully"
   - Update local user state/cache
   - Navigate back to profile page
   - Refresh profile page with new data
   
   Error:
   - Show error message from API
   - Keep user on edit page
   - Allow retry
   ```

**Step 9: Create Backend API Endpoints**

**Endpoint 1: Get Current User Profile**
```
GET /api/users/me

Headers:
- Authorization: Bearer {token}

Response:
{
  "id": "...",
  "name": "...",
  "email": "...",
  "phone": "...",
  "date_of_birth": "1990-05-15",
  "gender": "male",
  "profile_image": "https://..."
}
```

**Endpoint 2: Update User Profile**
```
PUT /api/users/me or PATCH /api/users/{userId}

Headers:
- Authorization: Bearer {token}

Request body:
{
  "name": "New Name",
  "date_of_birth": "1990-05-15",
  "gender": "male",
  "profile_image": "https://..."
}

Response:
{
  "success": true,
  "user": { updated user object }
}
```

**Endpoint 3: Upload Profile Image**
```
POST /api/users/me/profile-image

Headers:
- Authorization: Bearer {token}
- Content-Type: multipart/form-data

Request body:
- image: [file]

Response:
{
  "image_url": "https://pub-xxx.r2.dev/profiles/user-123.jpg"
}
```

**Step 10: Implement Backend Logic**

**Profile Image Upload:**

1. **Receive image file**
2. **Validate:**
   - File type (only images: jpg, png, webp)
   - File size (max 5MB)

3. **Process image:**
   - Resize to standard size (e.g., 512x512)
   - Optimize quality

4. **Upload to Cloudflare R2:**
   - Path: `profiles/{userId}.jpg`
   - Overwrite existing if present

5. **Return public URL**

**Update Profile:**

1. **Validate request:**
   - Name not empty
   - DOB is valid date
   - Gender is valid option

2. **Update database:**
   ```
   UPDATE users
   SET 
     name = $1,
     date_of_birth = $2,
     gender = $3,
     profile_image = $4,
     updated_at = NOW()
   WHERE id = $5
   ```

3. **Return updated user object**

**Step 11: Handle Edge Cases**

1. **Unsaved changes warning:**
   ```
   If user clicks back with unsaved changes:
   - Show dialog: "Discard changes?"
   - Options: "Discard" / "Keep Editing"
   ```

2. **Network error during save:**
   ```
   - Show error message
   - Keep changes in form
   - Allow retry
   ```

3. **Image upload fails:**
   ```
   - Show specific error
   - Keep other changes
   - Allow saving without image update
   - Or retry just image upload
   ```

4. **Invalid data:**
   ```
   - Show validation errors
   - Highlight problematic fields
   - Don't submit to server
   ```

**Questions to Ask:**
- "Should profile image be uploaded immediately or only when saving all changes?"
- "What is the maximum file size for profile images?"
- "Should we support removing profile image (set to default/null)?"
- "Are there any other user fields that should be editable (address, bio, etc.)?"

---

## Implementation Priority

**Recommended order:**

1. **Bug 2: Search bar** (quick win, improves UX)
2. **Bug 3B: Car brand dropdown** (required for consistency)
3. **Bug 4: Brand filter buttons** (uses same brands as 3B)
4. **Bug 3A: City dropdown** (important for data quality)
5. **Bug 1: Filter bottom sheet** (more complex, but important)
6. **Bug 5: Profile settings** (new feature, can be last)

---

## Testing Checklist

**Bug 1 - Filter Bottom Sheet:**
- [ ] No overflow errors on any screen size
- [ ] All filters visible and accessible
- [ ] City dropdown shows only cities from current cars
- [ ] Price low-to-high sorting works
- [ ] Price high-to-low sorting works
- [ ] Price range slider works
- [ ] Apply button filters results correctly
- [ ] Clear filters resets to all cars
- [ ] No cars message shows when filters too restrictive

**Bug 2 - Search Bar:**
- [ ] Typing in search bar works
- [ ] Pressing Enter triggers search
- [ ] Search finds cars by title
- [ ] Search is case-insensitive
- [ ] Clear button appears when searching
- [ ] Clear button resets to all cars
- [ ] No results message shows when appropriate
- [ ] Search works with active filters

**Bug 3A - City Dropdown:**
- [ ] Shows dropdown on click
- [ ] Search bar at top is fixed
- [ ] City list scrolls below search
- [ ] Searching filters city list
- [ ] Selecting city populates field
- [ ] Only valid cities accepted
- [ ] Backend rejects invalid cities

**Bug 3B - Brand Dropdown:**
- [ ] Shows all 18 brands
- [ ] Each brand has logo displayed
- [ ] Logos load correctly
- [ ] Selecting brand works
- [ ] Only valid brands accepted
- [ ] Backend rejects invalid brands

**Bug 4 - Brand Filter Buttons:**
- [ ] Shows all 18 brand buttons + Others
- [ ] Buttons are scrollable/wrappable
- [ ] Clicking brand filters cars
- [ ] Selected brand is highlighted
- [ ] "Others" shows non-listed brands
- [ ] "All" or clear shows all cars
- [ ] Empty state shows if no cars for brand

**Bug 5 - Profile Settings:**
- [ ] Page loads with current user data
- [ ] Can change profile image
- [ ] Image uploads successfully
- [ ] Name field is editable
- [ ] DOB picker works
- [ ] Gender dropdown works
- [ ] Phone is read-only
- [ ] Email is read-only
- [ ] Save button shows only when changed
- [ ] Save updates profile on server
- [ ] Success message shows after save
- [ ] Profile page reflects changes
- [ ] Unsaved changes warning works

---

## Questions for User

Before implementing, clarify:

1. **Bug 1:**
   - "Should filter options be ANDed (all must match) or ORed (any can match)?"
   - "Should active filters persist after app restart?"

2. **Bug 2:**
   - "Search only in car title, or also make/model/description?"
   - "Should search work with filters or reset them?"

3. **Bug 3A:**
   - "Full list of Korean cities or just major ones (50-100)?"
   - "Should we support other countries' cities in future?"

4. **Bug 3B:**
   - "Do you have logo files ready, or should I help find them?"
   - "Should we add 'Other' option for unlisted brands?"

5. **Bug 4:**
   - "How should brand buttons be laid out if they don't fit on screen?"
   - "Should brand filtering combine with other filters?"

6. **Bug 5:**
   - "What other user fields should be editable (if any)?"
   - "Should profile image upload immediately or on save?"
   - "Maximum file size for profile images?"

---

These instructions provide comprehensive guidance for fixing all 5 reported issues while adapting to the existing project structure.

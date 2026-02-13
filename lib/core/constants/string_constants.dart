/// String Constants
/// Contains all UI text strings, error messages, validation messages, etc.
library;

class StringConstants {
  // App Name
  static const String appName = 'TurboCar';

  // Common
  static const String loading = 'Wait bro...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String share = 'Share';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String apply = 'Apply';
  static const String reset = 'Reset';
  static const String close = 'Close';
  static const String back = 'Back';
  static const String next = 'Next';
  static const String done = 'Done';
  static const String retry = 'Retry';

  // Authentication
  static const String login = 'Login';
  static const String signup = 'Sign Up';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String loginWithGoogle = 'Login with Google';
  static const String continueAsGuest = 'Continue as Guest';
  static const String name = 'Name';
  static const String firstName = 'First Name';
  static const String lastName = 'Last Name';
  static const String dateOfBirth = 'Date of Birth';
  static const String gender = 'Gender';
  static const String phone = 'Phone Number';

  // Home Page
  static const String home = 'Home';
  static const String welcome = 'Welcome';
  static const String notifications = 'Notifications';
  static const String noCarsFound = 'No cars found';
  static const String pullToRefresh = 'Pull to refresh';

  // Saved Page
  static const String saved = 'Saved';
  static const String savedCars = 'Saved Cars';
  static const String noSavedCars = 'No saved cars yet';
  static const String pleaseLoginToSave = 'Please login to save cars';
  static const String removeFromSaved = 'Remove from Saved';
  static const String addedToSaved = 'Added to favorites';
  static const String removedFromSaved = 'Removed from favorites';

  // Profile Page
  static const String profile = 'Profile';
  static const String myCars = 'My Cars';
  static const String darkMode = 'Dark Mode';
  static const String language = 'Language';
  static const String changePassword = 'Change Password';
  static const String contactUs = 'Contact Us';
  static const String aboutUs = 'About Us';
  static const String editProfile = 'Edit Profile';
  static const String logoutConfirmation = 'Are you sure you want to logout?';
  static const String logoutSuccess = 'Logged out successfully';

  // My Cars Page
  static const String myCarsTitle = 'My Cars';
  static const String noCarsPosted = "You haven't posted any cars yet";
  static const String postCar = 'Post Car';
  static const String deleteCarConfirmation =
      'Are you sure you want to delete this car?';

  // Change Password Page
  static const String changePasswordTitle = 'Change Password';
  static const String currentPassword = 'Current Password';
  static const String newPassword = 'New Password';
  static const String confirmNewPassword = 'Confirm New Password';
  static const String passwordChangedSuccess = 'Password changed successfully';

  // Contact Us Page
  static const String contactUsTitle = 'Contact Us';
  static const String call = 'Call';
  static const String emailUs = 'Email Us';
  static const String phoneNumber = 'Phone Number';

  // About Us Page
  static const String aboutUsTitle = 'About Us';
  static const String termsAndConditions = 'Terms and Conditions';
  static const String privacyPolicy = 'Privacy Policy';

  // Post Page
  static const String postCarTitle = 'Post Car';
  static const String postFeatureComingSoon = 'Post feature coming soon';
  static const String carType = 'Car Type';
  static const String carName = 'Car Name';
  static const String carModelLabel = 'Car Model';
  static const String fuelType = 'Fuel Type';
  static const String mileageLabel = 'Mileage (km)';
  static const String yearLabel = 'Year';
  static const String priceLabel = 'Price';
  static const String descriptionLabel = 'Description';
  static const String conditionLabel = 'Condition';
  static const String transmissionLabel = 'Transmission';
  static const String colorLabel = 'Color';
  static const String cityLabel = 'City';
  static const String addressLabel = 'Address';
  static const String stateLabel = 'State';
  static const String chatOnlyLabel = 'Chat only (no calls)';
  static const String postButton = 'Post';
  static const String carPostedSuccess = 'Car posted successfully!';
  static const String fillRequiredFields = 'Please fill in all required fields';
  static const String descriptionMinLength =
      'Description must be at least 20 characters';
  static const String addPhotos = 'Add Photos';
  static const String selectCarType = 'Select car type';
  static const String selectCondition = 'Select condition';
  static const String selectTransmission = 'Select transmission';
  static const String gasoline = 'Gasoline';
  static const String electric = 'Electric';
  static const String diesel = 'Diesel';
  static const String excellent = 'Excellent';
  static const String good = 'Good';
  static const String fair = 'Fair';
  static const String automatic = 'Automatic';
  static const String manual = 'Manual';

  // Show Post Page
  static const String carDetails = 'Car Details';
  static const String carDetailsComingSoon = 'Car details coming soon';

  // Chat Page
  static const String chat = 'Chat';
  static const String chats = 'Chats';
  static const String chatFeatureComingSoon = 'Chat feature coming soon';

  // Notification Page
  static const String notificationPageTitle = 'Notifications';
  static const String notificationFeatureComingSoon =
      'Notifications feature coming soon';

  // Filter
  static const String city = 'City';
  static const String category = 'Category';
  static const String priceRange = 'Price Range';
  static const String sortBy = 'Sort By';
  static const String priceHighToLow = 'Price: High to Low';
  static const String priceLowToHigh = 'Price: Low to High';
  static const String mileage = 'Mileage';
  static const String year = 'Year';

  // Validation Messages
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Please enter a valid email';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort =
      'Password must be at least 8 characters';
  static const String passwordMustContainUppercase =
      'Password must contain at least one uppercase letter';
  static const String passwordMustContainLowercase =
      'Password must contain at least one lowercase letter';
  static const String passwordMustContainNumber =
      'Password must contain at least one number';
  static const String passwordMustContainSpecialChar =
      'Password must contain at least one special character';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String nameRequired = 'Name is required';
  static const String phoneRequired = 'Phone number is required';
  static const String phoneInvalid = 'Please enter a valid phone number';
  static const String dateOfBirthRequired = 'Date of birth is required';
  static const String ageTooYoung = 'You must be at least 18 years old';

  // Error Messages
  static const String networkError =
      'Network error. Please check your internet connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unauthorizedError = 'Unauthorized. Please login again.';
  static const String notFoundError = 'Resource not found.';
  static const String unknownError = 'An unknown error occurred.';
  static const String loginError = 'Invalid email or password';
  static const String signupError = 'Sign up failed. Please try again.';

  // Success Messages
  static const String loginSuccess = 'Logged in successfully';
  static const String signupSuccess = 'Account created successfully';
  static const String profileUpdated = 'Profile updated successfully';
  static const String carSaved = 'Car saved to favorites';
  static const String carUnsaved = 'Car removed from favorites';
  static const String carDeleted = 'Car deleted successfully';

  // Gender Options
  static const String male = 'Male';
  static const String female = 'Female';
  static const String other = 'Other';

  // Car Categories
  static const String sedan = 'Sedan';
  static const String suv = 'SUV';
  static const String sports = 'Sports';
  static const String hatchback = 'Hatchback';
  static const String coupe = 'Coupe';
  static const String convertible = 'Convertible';
  static const String truck = 'Truck';
  static const String van = 'Van';

  // Guest Mode
  static const String guest = 'Guest';
  static const String pleaseLoginToPost = 'Please login to post a car';
  static const String pleaseLoginToChat = 'Please login to access chats';
  static const String loginToSync =
      'Login to sync your saved cars across devices';
  static const String loginOrSignup = 'Login / Sign Up';
  static const String welcomeBack = 'Welcome Back';
  static const String signInToAccount = 'Sign in to your account';
  static const String createAccount = 'Create Account';
  static const String signUpToGetStarted = 'Sign up to get started';
  static const String orContinueWith = 'Or continue with';
  static const String emailOrPhone = 'Email or Phone';
  static const String enterEmailOrPhone = 'Enter your email or phone';

  // Password Requirements
  static const String minEightCharacters = 'Min 8 characters';
  static const String oneUppercase = 'One uppercase letter';
  static const String oneLowercase = 'One lowercase letter';
  static const String oneNumber = 'One number';
  static const String oneSpecialChar = 'One special character';
}

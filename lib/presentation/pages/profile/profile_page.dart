/// Profile Page
/// User profile and settings page with guest mode support
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/theme_provider.dart';
import '../../../core/constants/string_constants.dart';
import '../../../core/router/route_names.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/specific/language_selector_modal.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);

    // If guest, show limited profile
    if (authState.isGuest) {
      return _buildGuestProfile(context, ref, themeMode);
    }

    // If not authenticated and not guest, show login prompt
    if (!authState.isAuthenticated) {
      return Scaffold(
        backgroundColor: Theme.of(context).primaryColorDark,
        appBar: CustomAppBar(
          title: StringConstants.profile,
          isMainNavPage: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 64),
              const SizedBox(height: 16),
              Text(StringConstants.pleaseLoginToSave),
              const SizedBox(height: 24),
              CustomButton(
                text: StringConstants.loginOrSignup,
                onPressed: () => context.push(RouteNames.login),
              ),
            ],
          ),
        ),
      );
    }

    // Authenticated user profile
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorDark,
      appBar: CustomAppBar(title: StringConstants.profile, isMainNavPage: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              // Profile header card
              Card(
                elevation: 0,
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: authState.user?.profilePicture != null
                            ? NetworkImage(authState.user!.profilePicture!)
                            : null,
                        child: authState.user?.profilePicture == null
                            ? const Icon(Icons.person, size: 30)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          authState.user?.name ?? '',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {
                          context.push(RouteNames.profileSettings);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16), // Gap between cards
              // Settings card
              Card(
                elevation: 0,
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text(StringConstants.darkMode),
                      leading: const Icon(Icons.dark_mode_outlined),
                      trailing: Switch(
                        value: themeMode == ThemeMode.dark,
                        onChanged: (value) {
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text(StringConstants.myCars),
                      leading: const Icon(Icons.car_rental_outlined),
                      onTap: () {
                        context.push(RouteNames.myCars);
                      },
                    ),
                    ListTile(
                      title: const Text(StringConstants.language),
                      leading: const Icon(Icons.language_outlined),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('English'),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => LanguageSelectorModal(
                            currentLanguage: 'English',
                            onLanguageSelected: (language) {},
                          ),
                        );
                      },
                    ),
                    ListTile(
                      title: const Text(StringConstants.changePassword),
                      leading: const Icon(Icons.lock_outline),
                      onTap: () {
                        context.push(RouteNames.changePassword);
                      },
                    ),
                    ListTile(
                      title: const Text(StringConstants.contactUs),
                      leading: const Icon(Icons.contact_page_outlined),
                      onTap: () {
                        context.push(RouteNames.contactUs);
                      },
                    ),
                    ListTile(
                      title: const Text(StringConstants.aboutUs),
                      leading: const Icon(Icons.info_outline),
                      onTap: () {
                        context.push(RouteNames.aboutUs);
                      },
                    ),
                    ListTile(
                      title: const Text(
                        StringConstants.logout,
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      leading: const Icon(Icons.logout, color: Colors.red),
                      onTap: () {
                        ConfirmationDialog.show(
                          context,
                          title: StringConstants.logout,
                          content: const Text(
                            StringConstants.logoutConfirmation,
                          ),
                          onConfirm: () async {
                            await ref.read(authProvider.notifier).logout();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Guest profile with limited options
  Widget _buildGuestProfile(
    BuildContext context,
    WidgetRef ref,
    ThemeMode themeMode,
  ) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorDark,
      appBar: CustomAppBar(title: StringConstants.profile, isMainNavPage: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              // Guest header card
              Card(
                elevation: 0,
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        child: Icon(Icons.person, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        StringConstants.guest,
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 16),
                      // Login / Sign Up button for guests
                      Expanded(
                        child: CustomButton(
                          text: StringConstants.loginOrSignup,
                          onPressed: () => context.push(RouteNames.login),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16), // Gap between cards
              // Settings card
              Card(
                elevation: 0,
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text(StringConstants.darkMode),
                      trailing: Switch(
                        value: themeMode == ThemeMode.dark,
                        onChanged: (value) {
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text(StringConstants.language),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('English'),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => LanguageSelectorModal(
                            currentLanguage: 'English',
                            onLanguageSelected: (language) {},
                          ),
                        );
                      },
                    ),
                    ListTile(
                      title: const Text(StringConstants.contactUs),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        context.push(RouteNames.contactUs);
                      },
                    ),
                    ListTile(
                      title: const Text(StringConstants.aboutUs),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        context.push(RouteNames.aboutUs);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: authState.user?.profilePicture != null
                ? NetworkImage(authState.user!.profilePicture!)
                : null,
            child: authState.user?.profilePicture == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            authState.user?.name ?? '',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // TODO: Navigate to edit profile
            },
            child: const Text(StringConstants.editProfile),
          ),
        ],
      ),
    );
  }
}

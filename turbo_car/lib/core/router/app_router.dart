/// App Router
/// Navigation configuration using go_router
/// Main navigation uses IndexedStack for instant switching
library;

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/pages/main_navigation_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/register_page.dart';
import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/notification/notification_page.dart';
import '../../presentation/pages/show_post/show_post_page.dart';
import '../../presentation/pages/post/post_page.dart';
import '../../presentation/pages/post/post_success_page.dart';
import '../../presentation/pages/profile/my_cars_page.dart';
import '../../presentation/pages/profile/change_password_page.dart';
import '../../presentation/pages/profile/contact_us_page.dart';
import '../../presentation/pages/profile/about_us_page.dart';
import '../../presentation/pages/profile/profile_settings_page.dart';
import '../../presentation/pages/chat/chat_room_screen.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/chat_room_data.dart';
import '../../data/models/car_model.dart';
import 'auth_router_notifier.dart';
import 'route_names.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Use the controlled notifier that only fires on auth STATUS changes
  // This prevents router rebuilds during loading/error states
  final authNotifier = ref.watch(authRouterNotifierProvider);

  return GoRouter(
    initialLocation: RouteNames.root,
    // CRITICAL: Use refreshListenable instead of rebuilding entire router
    // This ensures pages are not rebuilt during loading/error states
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // Read current auth state (not watch - we use refreshListenable for reactivity)
      final isAuthenticated = authNotifier.isAuthenticated;
      final isGuest = authNotifier.isGuest;
      final isInitialized = authNotifier.isInitialized;
      final isOnLoginPage = state.uri.path == RouteNames.login;
      final isOnRegisterPage = state.uri.path == RouteNames.register;
      final isOnSplashPage = state.uri.path == RouteNames.splash;

      // If not initialized, go to splash
      if (!isInitialized) {
        return RouteNames.splash;
      }

      // If initialized and still on splash, go to root decision logic
      if (isInitialized && isOnSplashPage) {
        return isAuthenticated || isGuest ? RouteNames.home : RouteNames.login;
      }

      // If not authenticated and not guest, redirect to login
      // But allow register page
      if (!isAuthenticated && !isGuest && !isOnLoginPage && !isOnRegisterPage) {
        return RouteNames.login;
      }

      // If authenticated and trying to access login/register, redirect to home
      if (isAuthenticated && (isOnLoginPage || isOnRegisterPage)) {
        return RouteNames.home;
      }

      // If on root path, check auth status
      if (state.uri.path == RouteNames.root) {
        return isAuthenticated || isGuest ? RouteNames.home : RouteNames.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      // Main navigation page with bottom nav (handles home, saved, post, chat, profile)
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        builder: (context, state) => const MainNavigationPage(),
      ),
      GoRoute(
        path: RouteNames.saved,
        name: 'saved',
        redirect: (context, state) => RouteNames.home, // Redirect to main nav
      ),
      GoRoute(
        path: RouteNames.chat,
        name: 'chat',
        redirect: (context, state) => RouteNames.home, // Redirect to main nav
      ),
      GoRoute(
        path: RouteNames.post,
        name: 'post',
        redirect: (context, state) => RouteNames.home, // Redirect to main nav
      ),
      GoRoute(
        path: RouteNames.profile,
        name: 'profile',
        redirect: (context, state) => RouteNames.home, // Redirect to main nav
      ),
      // Other routes that still use navigation
      GoRoute(
        path: RouteNames.notification,
        name: 'notification',
        builder: (context, state) => const NotificationPage(),
      ),
      GoRoute(
        path: '/post/:id',
        name: 'showPost',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ShowPostPage(carId: id);
        },
      ),
      // Chat room route for individual conversations
      GoRoute(
        path: '/chat/:id',
        name: 'chatRoom',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra;
          // Support both ConversationModel (from chat list) and ChatRoomData (from car details)
          if (extra is ConversationModel) {
            return ChatRoomScreen(conversationId: id, conversation: extra);
          } else if (extra is ChatRoomData) {
            return ChatRoomScreen(
              conversationId: extra.isPending ? null : id,
              chatRoomData: extra,
            );
          }
          return ChatRoomScreen(conversationId: id);
        },
      ),
      // Pending chat route (for lazy conversation creation)
      GoRoute(
        path: '/chat/new',
        name: 'chatRoomPending',
        builder: (context, state) {
          final chatRoomData = state.extra as ChatRoomData?;
          return ChatRoomScreen(chatRoomData: chatRoomData);
        },
      ),
      GoRoute(
        path: RouteNames.postSuccess,
        name: 'postSuccess',
        builder: (context, state) => const PostSuccessPage(),
      ),
      GoRoute(
        path: '/edit-car',
        name: 'editCar',
        builder: (context, state) {
          final car = state.extra as CarModel?;
          return PostPage(carToEdit: car);
        },
      ),
      GoRoute(
        path: RouteNames.myCars,
        name: 'myCars',
        builder: (context, state) => const MyCarsPage(),
      ),
      GoRoute(
        path: RouteNames.changePassword,
        name: 'changePassword',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: RouteNames.contactUs,
        name: 'contactUs',
        builder: (context, state) => const ContactUsPage(),
      ),
      GoRoute(
        path: RouteNames.aboutUs,
        name: 'aboutUs',
        builder: (context, state) => const AboutUsPage(),
      ),
      GoRoute(
        path: RouteNames.profileSettings,
        name: 'profileSettings',
        builder: (context, state) => const ProfileSettingsPage(),
      ),
    ],
  );
});

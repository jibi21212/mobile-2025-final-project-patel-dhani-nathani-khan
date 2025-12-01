import 'package:go_router/go_router.dart';

import 'features/auth/auth_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/details/task_details_screen.dart';
import 'features/list/task_list_screen.dart';
import 'features/settings/settings_screen.dart';
import 'services/auth_service.dart';

GoRouter createRouter(AuthService authService) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authService,
    redirect: (context, state) {
      final signedIn = authService.isSignedIn;
      final loggingIn = state.matchedLocation == '/auth';
      if (!signedIn && !loggingIn) return '/auth';
      if (signedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (ctx, st) => const AuthScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (ctx, st) => const TaskListScreen(),
        routes: [
          GoRoute(
            path: 'task/:id',
            builder: (ctx, st) => TaskDetailsScreen(
              taskId: int.parse(st.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: 'settings',
            builder: (ctx, st) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'dashboard',
            builder: (ctx, st) => const DashboardScreen(),
          ),
        ],
      ),
    ],
  );
}

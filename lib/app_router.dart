import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/list/task_list_screen.dart';
import 'features/details/task_details_screen.dart';
import 'features/settings/settings_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (ctx, st) => const TaskListScreen(),
      routes: [
        GoRoute(
          path: 'task/:id',
          builder: (ctx, st) => TaskDetailsScreen(taskId: int.parse(st.pathParameters['id']!)),
        ),
        GoRoute(
          path: 'settings',
          builder: (ctx, st) => const SettingsScreen(),
        ),
        // Future: GoRoute(path: 'whiteboard', builder: ...)
      ],
    ),
  ],
);

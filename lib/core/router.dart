import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/welcome_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/signup_page.dart';
import '../screens/home_page.dart';
import '../screens/add_expense_page.dart';
import '../screens/add_income_page.dart';
import '../screens/statistics_page.dart';// 👈 Import income page

final supabase = Supabase.instance.client;

final GoRouter router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final session = supabase.auth.currentSession;
    final loggedIn = session != null;
    final location = state.uri.path;

    // ❌ Not logged in → only allow welcome, login, signup
    if (!loggedIn &&
        location != '/' &&
        location != '/login' &&
        location != '/signup') {
      return '/login';
    }

    // ✅ Logged in → prevent going back to auth pages
    if (loggedIn &&
        (location == '/' || location == '/login' || location == '/signup')) {
      return '/home';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const WelcomePage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),

    // 🔹 Connect Expense and Income pages
    GoRoute(path: '/add-expense', builder: (context, state) => const AddExpensePage()),
    GoRoute(path: '/add-income', builder: (context, state) => const AddIncomePage()),
    GoRoute(path: '/statistics', builder: (context, state) => const StatisticsPage(),),
  ],
);

import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Color palette
  final Color color0 = const Color(0xFFC080D); // orange/pink
  final Color color1 = Colors.black; // black background
  final Color color2 = const Color(0xFF38263F); // dark purple
  final Color color3 = const Color(0xFF52425C); // medium purple
  final Color color4 = const Color(0xFF7A6284); // light purple

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color1,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // App Logo/Title
            const Icon(
              Icons.forum_outlined,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome to ASKA!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: color2,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: color0,
                  borderRadius: BorderRadius.circular(25),
                ),
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: Colors.white,
                unselectedLabelColor: color4,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
                tabs: const [
                  Tab(text: 'Sign In'),
                  Tab(text: 'Sign Up'),
                ],
              ),
            ),

            // Tab Bar Views
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Login Tab
                    LoginScreen(),
                    // Signup Tab
                    SignupScreen(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

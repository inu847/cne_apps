import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  final AuthService _authService = AuthService();
  
  // Theme colors
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color darkBlack = Color(0xFF212121);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    // Fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Scale animation controller
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // Scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
  }

  void _startSplashSequence() async {
    // Start animations
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _scaleController.forward();
    
    // Wait for animations to complete and check auth status
    await Future.delayed(const Duration(milliseconds: 2500));
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() async {
    try {
      final user = await _authService.getCurrentUser();
      
      if (!mounted) return;
      
      if (user != null) {
        // User is logged in, navigate to home screen
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                HomeScreen(user: user),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      } else {
        // User is not logged in, navigate to login
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      // Error checking auth, navigate to login
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width >= 650;
    
    return Scaffold(
      backgroundColor: darkBlack,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              darkBlack,
              darkBlack.withOpacity(0.9),
              primaryGreen.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo and Animation Section
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Logo
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: lightBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: primaryGreen.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Image.asset(
                                      'assets/images/logo-landscape.png',
                                      height: isTablet ? 100 : 80,
                                      width: isTablet ? 200 : 160,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 30),
                                  
                                  // App Name
                                  Text(
                                    'DompetKasir',
                                    style: TextStyle(
                                      fontSize: isTablet ? 32 : 28,
                                      fontWeight: FontWeight.bold,
                                      color: lightBlue,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 10),
                                  
                                  // Subtitle
                                  Text(
                                    'Point of Sale System',
                                    style: TextStyle(
                                      fontSize: isTablet ? 18 : 16,
                                      color: lightBlue.withOpacity(0.8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 40),
                                  
                                  // Lottie Animation
                                  SizedBox(
                                    height: isTablet ? 120 : 100,
                                    width: isTablet ? 120 : 100,
                                    child: Lottie.asset(
                                      'assets/animations/success_check.json',
                                      repeat: true,
                                      animate: true,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Loading Section
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Loading Indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                        strokeWidth: 3,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Loading Text
                    AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: 16,
                              color: lightBlue.withOpacity(0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Footer
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        '© 2023 DompetKasir POS System',
                        style: TextStyle(
                          fontSize: 12,
                          color: lightBlue.withOpacity(0.5),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
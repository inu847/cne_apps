import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Color palette baru
    const Color primaryGreen = Color(0xFF03D26F);
    const Color lightBlue = Color(0xFFEAF4F4);
    const Color darkBlack = Color(0xFF161514);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryGreen,
              primaryGreen.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: darkBlack.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/images/cne_logo.svg',
                          height: 100,
                          width: 100,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Login Card
                    Container(
                      width: 400,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: lightBlue,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: darkBlack.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: darkBlack,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please sign in to continue',
                            style: TextStyle(
                              fontSize: 16,
                              color: darkBlack.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Email Field
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: darkBlack),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(color: darkBlack.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.email, color: primaryGreen),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: darkBlack.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: primaryGreen, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Password Field
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: darkBlack),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(color: darkBlack.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.lock, color: primaryGreen),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  color: primaryGreen,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: darkBlack.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: primaryGreen, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Remember Me & Forgot Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value!;
                                      });
                                    },
                                    activeColor: primaryGreen,
                                    checkColor: lightBlue,
                                  ),
                                  Text(
                                    'Remember me',
                                    style: TextStyle(color: darkBlack),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  // Forgot password logic
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: primaryGreen),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Error Message
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: lightBlue,
                                disabledBackgroundColor: primaryGreen.withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: lightBlue,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: lightBlue,
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    // Footer
                    Text(
                      '© 2023 CashNEntry POS System',
                      style: TextStyle(
                        color: lightBlue,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _handleLogin() async {
    // Validate input
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Email and password are required';
      });
      return;
    }

    // Clear previous error message
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final response = await _authService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (response.success && response.data != null) {
        // Login successful, navigate to dashboard
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => DashboardScreen(user: response.data!.user),
          ),
        );
      } else {
        // Login failed
        setState(() {
          _errorMessage = response.message ?? 'Login failed. Please check your credentials.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
}
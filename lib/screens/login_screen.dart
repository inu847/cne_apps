import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';
import 'home_screen.dart';

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
    // Using theme colors from ApiConfig
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ApiConfig.primaryColor,
              ApiConfig.primaryColor.withOpacity(0.8),
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
                    // Login Card
                    Container(
                      width: 400,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: ApiConfig.backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: ApiConfig.textColor.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Logo
                          Image.asset(
                            'assets/images/logo-landscape.png',
                            height: 60,
                            width: 120,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 24),
                          
                          // Login Title
                          Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: ApiConfig.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please sign in to continue',
                            style: TextStyle(
                              fontSize: 16,
                              color: ApiConfig.textColor.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Form Fields
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          // Email Field
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofocus: false,
                            enableInteractiveSelection: false,
                            style: TextStyle(color: ApiConfig.textColor),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(color: ApiConfig.textColor.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.email, color: ApiConfig.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: ApiConfig.primaryColor, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: ApiConfig.primaryColor, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Password Field
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofocus: false,
                            enableInteractiveSelection: false,
                            style: TextStyle(color: ApiConfig.textColor),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(color: ApiConfig.textColor.withOpacity(0.7)),
                              prefixIcon: Icon(Icons.lock, color: ApiConfig.primaryColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  color: ApiConfig.primaryColor,
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
                                borderSide: BorderSide(color: ApiConfig.textColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: ApiConfig.primaryColor, width: 2),
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
                                    activeColor: ApiConfig.primaryColor,
                                    checkColor: ApiConfig.backgroundColor,
                                  ),
                                  Text(
                                    'Remember me',
                                    style: TextStyle(color: ApiConfig.textColor),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  // Forgot password logic
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: ApiConfig.primaryColor),
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
                                backgroundColor: ApiConfig.primaryColor,
                                foregroundColor: ApiConfig.backgroundColor,
                                disabledBackgroundColor: ApiConfig.primaryColor.withOpacity(0.5),
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
                                      color: ApiConfig.backgroundColor,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                    'LOGIN',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: ApiConfig.backgroundColor,
                                    ),
                                  ),
                            ),
                          ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    // Footer
                    Text(
                      '© 2025 Dompet Kasir - POS',
                      style: TextStyle(
                        color: ApiConfig.backgroundColor,
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
        // Login successful, navigate to home screen
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(user: response.data!.user),
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
import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/service/global_functions.dart';
import 'package:mama_meow/utils/custom_widgets/custom_loader.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool isLoading = false;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return CustomLoader(
      inAsyncCall: isLoading,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: formKey,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFFFBCFE8),
                                        Color(0xFFF9A8D4),
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.pets,
                                      size: 40,
                                      color: Color(0xFFEC4899),
                                    ),
                                  ),
                                ),
                                const Text(
                                  "Welcome Back!",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Sign in to continue your parenting journey 🐾",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Email
                            const Text(
                              "Email Address",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) =>
                                  globalFunctions.emailValidator(value),
                              decoration: InputDecoration(
                                hintText: "Enter your email",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF472B6),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password
                            const Text(
                              "Password",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              validator: (value) =>
                                  globalFunctions.nonEmptyRule(value),
                              decoration: InputDecoration(
                                hintText: "Enter your password",
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Colors.grey,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF472B6),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            ElevatedButton(
                              onPressed: () async {
                                final email = _emailController.text.trim();
                                final password = _passwordController.text;
                                if (globalFunctions.validateAndSave(formKey)) {
                                  setState(() {
                                    isLoading = true;
                                  });
                                  int isSuccess = await authenticationService
                                      .login(
                                        context,
                                        email: email,
                                        password: password,
                                      );

                                  setState(() {
                                    isLoading = false;
                                  });
                                  if (isSuccess == 1) {
                                    await Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      AppRoutes.navigationBarPage,
                                      (route) => false,
                                    );
                                  } else if (isSuccess == 2) {
                                    await authenticationService
                                        .logoutFromFirebase();
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF472B6),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                "Sign In",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),

                            const SizedBox(height: 16),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.registerPage,
                                  );
                                },
                                child: const Text(
                                  "Don't have an account? Sign Up",
                                  style: TextStyle(
                                    color: Color(0xFFEC4899),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Decorative dots
                    const Positioned(
                      top: -10,
                      left: -10,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Color(0xFFFBCFE8),
                      ),
                    ),
                    const Positioned(
                      bottom: -10,
                      right: -10,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Color(0xFFE9D5FF),
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
}

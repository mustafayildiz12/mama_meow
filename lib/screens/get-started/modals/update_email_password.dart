import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/service/database_service.dart';
import 'package:mama_meow/service/global_functions.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';

class UpdateEmailPasswordInfoModal extends StatefulWidget {
  const UpdateEmailPasswordInfoModal({super.key});

  @override
  State<UpdateEmailPasswordInfoModal> createState() =>
      _UpdateEmailPasswordInfoModalState();
}

class _UpdateEmailPasswordInfoModalState
    extends State<UpdateEmailPasswordInfoModal> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  User? user = authenticationService.getUser();

  // google.com
  // password
  String userProvider = "";

  bool isEmailVerified = false;
  bool obscurePassword = true;

  GlobalKey<FormState> emailKey = GlobalKey<FormState>();

  @override
  void initState() {
    emailController.text = currentMeowUser?.userEmail ?? "";
    passwordController.text = currentMeowUser?.userPassword ?? "";
    isEmailVerified = user?.emailVerified ?? false;
    getUserProvider();
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  getUserProvider() {
    String provider = authenticationService.findUserProvider();
    setState(() {
      userProvider = provider;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 750, maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Column(
                  children: [
                    Text(
                      '👶💕 Update your informations',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEC4899),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (userProvider == "password")
                Column(
                  children: [
                    // Baby's Name Field
                    const Text(
                      "Email",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEC4899),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Form(
                      key: emailKey,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: emailController,
                              maxLength: 30,
                              readOnly: !isEmailVerified,
                              validator: (value) =>
                                  globalFunctions.emailValidator(value),
                              decoration: InputDecoration(
                                hintText: "Enter your email...",
                                counterText: '',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFFBCFE8),
                                    width: 2,
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
                          ),
                          isEmailVerified
                              ? TextButton(
                                  onPressed: () async {
                                    if (globalFunctions.validateAndSave(
                                          emailKey,
                                        ) &&
                                        user!.email != emailController.text) {
                                      try {
                                        await user
                                            ?.verifyBeforeUpdateEmail(
                                              emailController.text,
                                            )
                                            .then((v) {
                                              customSnackBar.success(
                                                "We send a verify link to your new account. Your email will be updated when you verify",
                                              );
                                            });
                                      } catch (e) {
                                        customSnackBar.warning(
                                          "Error while updating email",
                                        );
                                      }
                                    } else {
                                      customSnackBar.warning(
                                        "Please input correct email format",
                                      );
                                    }
                                  },
                                  child: Text("Update"),
                                )
                              : TextButton(
                                  onPressed: () async {
                                    try {
                                      await user?.sendEmailVerification().then((
                                        _,
                                      ) {
                                        customSnackBar.success(
                                          "Verification link sended to your email",
                                        );
                                      });
                                    } catch (e) {
                                      print(e.toString());
                                      customSnackBar.warning(
                                        "Verification Error",
                                      );
                                    }
                                  },
                                  child: Text("Verify"),
                                ),
                        ],
                      ),
                    ),
                    const Text(
                      'You can always change this later in settings 😊',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    // Baby's Age Dropdown
                    const Text(
                      "Password",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEC4899),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: passwordController,
                            maxLength: 24,
                            obscureText: obscurePassword,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFBCFE8),
                                  width: 2,
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
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              await user?.updatePassword(
                                passwordController.text,
                              );
                              currentMeowUser = currentMeowUser?.copyWith(
                                userPassword: passwordController.text,
                              );
                              Navigator.pop(context, true);
                            } catch (e) {
                              print(e.toString());
                              customSnackBar.warning(
                                "An error occured while updating password.",
                              );
                              customSnackBar.tips(e.toString());
                            }
                          },
                          child: Text("Update"),
                        ),
                      ],
                    ),
                  ],
                ),
              SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog.adaptive(
                        title: Text("Delete Account?"),
                        content: Text(
                          "Are you sure you want to delete your account? All your data will be deleted along with your account. Do you still want to proceed?",
                        ),
                        actions: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text("Back"),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context, true);
                              },
                              child: Text("Delete"),
                            ),
                          ),
                        ],
                      );
                    },
                  ).then((value) async {
                    if (value == true) {
                      try {
                        User? user = authenticationService.getUser();
                        await user!.delete();
                        bool isSuccess = await databaseService.deleteAccount(
                          context,
                        );
                        if (isSuccess) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.loginPage,
                            (_) => false,
                          );
                        }
                      } catch (e) {
                        customSnackBar.error(
                          "Account not deleted right now. Please try again later.",
                        );
                        customSnackBar.tips(e.toString());
                      }
                    }
                  });
                },
                icon: Icon(CupertinoIcons.delete),
                label: Text("Delete Account"),
              ),
              SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

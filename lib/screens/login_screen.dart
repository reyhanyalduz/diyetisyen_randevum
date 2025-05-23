import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      AppUser? user = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        // Save FCM token for notifications
        await _notificationService.saveToken(user.uid);

        if (user.userType == UserType.client) {
          Navigator.pushReplacementNamed(context, '/clientHome');
        } else {
          Navigator.pushReplacementNamed(context, '/dietitianHome');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Giriş başarısız, lütfen bilgilerinizi kontrol edin.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    bool isKeyboardOpen = keyboardHeight > 0;

    return Scaffold(
      //backgroundColor: Color(0xFFF4F7FC),
      resizeToAvoidBottomInset: true, // Klavye açıldığında kaymayı sağlar
      body: SafeArea(
        child: Column(
          children: [
            if (!isKeyboardOpen) SizedBox(height: 70), // Klavye açıksa gizle

            Container(
              //height: screenHeight * 0.23,
              //color: Color(0xFFF4F7FC),

              height: isKeyboardOpen ? screenHeight * 0.20 : screenHeight * 0.3,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(1),
                  child: Image.asset(
                    'assets/images/logo3.png',
                  ),
                ),
              ),
            ),
            if (!isKeyboardOpen)
              Column(
                //mainAxisSize: MainAxisSize.min,  (height: 185),
                children: [
                  //SizedBox(height: 80),
                  Text(
                    "Kalorify",
                    style: TextStyle(
                        color: AppColors.color1,
                        fontSize: 40,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 110),
                ],
              ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.color1,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40.0),
                    topRight: Radius.circular(40.0),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                SizedBox(height: isKeyboardOpen ? 20 : 20),
                                Row(
                                  children: [
                                    SizedBox(width: 20),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _emailController,
                                        decoration: InputDecoration(
                                          hintText: 'E-mailinizi giriniz...',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(32.0)),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 10),
                                        ),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Lütfen e-posta adresinizi girin';
                                          }
                                          if (!value.contains('@')) {
                                            return 'Geçerli bir e-posta adresi girin';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                  ],
                                ),
                                SizedBox(height: isKeyboardOpen ? 20 : 20),
                                Row(
                                  children: [
                                    SizedBox(width: 20),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _passwordController,
                                        decoration: InputDecoration(
                                          hintText: 'Şifrenizi giriniz...',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(32.0)),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 10),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          ),
                                        ),
                                        obscureText: _obscurePassword,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Lütfen şifrenizi girin';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                  ],
                                ),
                                SizedBox(height: isKeyboardOpen ? 20 : 20),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    child: Text("Giriş Yap"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: AppColors.color1,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 40, vertical: 12),
                                      textStyle: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isKeyboardOpen ? 5 : 5),
                                Center(
                                  child: TextButton(
                                    onPressed: () =>
                                        Navigator.pushNamed(context, '/signup'),
                                    child: Text("Hesabınız yok mu? Kayıt olun"),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

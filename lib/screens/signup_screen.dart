import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _notificationService = NotificationService();
  String _selectedUserType = 'client';
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    bool isKeyboardOpen = keyboardHeight > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            if (!isKeyboardOpen) SizedBox(height: 50),
            Container(
              height:
                  isKeyboardOpen ? screenHeight * 0.20 : screenHeight * 0.27,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Image.asset('assets/images/dietitian.png',
                      color: AppColors.color1),
                ),
              ),
            ),
            if (!isKeyboardOpen) SizedBox(height: 20),
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
                                SizedBox(height: isKeyboardOpen ? 5 : 25),
                                Row(
                                  children: [
                                    Container(
                                      width: 100,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 20),
                                        child: Text(
                                          'Ad Soyad',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _nameController,
                                        decoration: InputDecoration(
                                          hintText:
                                              'Adınızı ve soyadınızı giriniz...',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(32.0)),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 10),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Lütfen adınızı ve soyadınızı girin';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                  ],
                                ),
                                SizedBox(height: isKeyboardOpen ? 5 : 25),
                                Row(
                                  children: [
                                    Container(
                                      width: 100,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 20),
                                        child: Text(
                                          'E-mail',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                    ),
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
                                SizedBox(height: isKeyboardOpen ? 5 : 25),
                                Row(
                                  children: [
                                    Container(
                                      width: 100,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 20),
                                        child: Text(
                                          'Şifre',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                    ),
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
                                          if (value.length < 6) {
                                            return 'Şifre en az 6 karakter olmalıdır';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                  ],
                                ),
                                SizedBox(height: isKeyboardOpen ? 5 : 25),
                                Row(
                                  children: [
                                    Container(
                                      width: 100,
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 20),
                                        child: Text(
                                          'Kullanıcı',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(32.0)),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedUserType,
                                            isExpanded: true,
                                            items: [
                                              DropdownMenuItem(
                                                value: 'client',
                                                child: Text('Danışan'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'dietitian',
                                                child: Text('Diyetisyen'),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedUserType = value!;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                  ],
                                ),
                                SizedBox(height: isKeyboardOpen ? 5 : 25),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _handleSignUp,
                                  child: _isLoading
                                      ? CircularProgressIndicator(
                                          color: Colors.white)
                                      : Text("Kayıt Ol"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.color1,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 40, vertical: 12),
                                    textStyle: TextStyle(fontSize: 16),
                                  ),
                                ),
                                SizedBox(height: isKeyboardOpen ? 5 : 10),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pushReplacementNamed(
                                          context, '/login'),
                                  child: Text(
                                      "Zaten hesabınız var mı? Giriş yapın"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
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

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = AuthService();
        final user = await authService.signUp(
          _emailController.text,
          _passwordController.text,
          _selectedUserType == 'client' ? UserType.client : UserType.dietitian,
          _nameController.text,
          170,
          60.0,
        );

        if (user != null) {
          // Save FCM token for notifications
          await _notificationService.saveToken(user.uid);
        }

        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          _selectedUserType == 'client' ? '/clientHome' : '/dietitianHome',
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt olma başarısız: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  UserType _userType = UserType.client;
  final AuthService _authService = AuthService();

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      AppUser? user = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _userType,
        _nameController.text.trim(),
        int.tryParse(_heightController.text.trim()) ?? 0,
        double.tryParse(_weightController.text.trim()) ?? 0.0,
      );

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Kayıt başarılı! Giriş yapabilirsiniz."),
              duration: Duration(seconds: 2)),
        );
        await Future.delayed(Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          '/login',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kayıt başarısız, lütfen tekrar deneyin.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Kayıt Ol")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Ad Soyad"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen ad soyad giriniz';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "E-posta"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen e-posta giriniz';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: "Şifre"),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen şifre giriniz';
                  }
                  return null;
                },
              ),
              Visibility(
                visible: _userType == UserType.client,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _heightController,
                      decoration: InputDecoration(labelText: "Boy (cm)"),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (_userType == UserType.client) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen boy giriniz';
                          }
                          int? height = int.tryParse(value);
                          if (height == null || height < 100 || height > 250) {
                            return 'Geçerli bir boy giriniz (100-250 cm)';
                          }
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _weightController,
                      decoration: InputDecoration(labelText: "Kilo (kg)"),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (_userType == UserType.client) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen kilo giriniz';
                          }
                          double? weight = double.tryParse(value);
                          if (weight == null || weight < 30 || weight > 300) {
                            return 'Geçerli bir kilo giriniz (30-300 kg)';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              ElevatedButton(onPressed: _signUp, child: Text("Kayıt Ol")),
            ],
          ),
        ),
      ),
    );
  }
}

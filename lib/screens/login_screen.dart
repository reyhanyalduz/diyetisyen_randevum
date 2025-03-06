import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      AppUser? user = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        if (user.userType == UserType.client) {
          Navigator.pushReplacementNamed(context, '/clientHome');
        } else {
          Navigator.pushReplacementNamed(context, '/deneme');
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
      resizeToAvoidBottomInset: true, // Klavye açıldığında kaymayı sağlar
      body: SafeArea(
        child: Column(
          children: [
            if (!isKeyboardOpen) SizedBox(height: 50), // Klavye açıksa gizle

            Container(
              //height: screenHeight * 0.23,
              height: isKeyboardOpen ? screenHeight*0.20 : screenHeight*0.27,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Image.asset('images/dietitian.png',color: AppColors.color1,),
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
                                Container(child:Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  child: Text('E-mail',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,),textAlign: TextAlign.left,),
                                ),width:MediaQuery.of(context).size.width),
                                
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    hintText: 'E-mailinizi giriniz...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(32.0)),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) =>
                                      value!.isEmpty || !value.contains("@")
                                          ? "Geçerli bir e-posta girin"
                                          : null,
                                ),
                                SizedBox(height: isKeyboardOpen ? 5 : 25),
                                Container(child:Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  child: Text('Şifre',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,),textAlign: TextAlign.left,),
                                ),width:MediaQuery.of(context).size.width),
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    hintText: 'Şifrenizi giriniz...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(32.0)),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  obscureText: true,
                                  validator: (value) => value!.length < 6
                                      ? "Şifre en az 6 karakter olmalı"
                                      : null,
                                ),
                                SizedBox(height: isKeyboardOpen ? 5 : 40),
                                ElevatedButton(
                                  onPressed: _login,
                                  child: Text("Giriş Yap"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.blue,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 40, vertical: 12),
                                    textStyle: TextStyle(fontSize: 16),
                                  ),
                                ),
                                SizedBox(height: isKeyboardOpen ? 10 : 20),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/signup'),
                                  child: Text("Hesabınız yok mu? Kayıt olun"),
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
}

import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    try {
      AppUser? user = await _authService.getCurrentUser();
      if (!mounted) return;

      if (user != null) {
        Navigator.pushReplacementNamed(
          context,
          user.userType == UserType.client ? '/clientHome' : '/dietitianHome',
        );
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('images/dietitian.png', height: 120,color: AppColors.color1,),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

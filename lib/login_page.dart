import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// -------------------- Constants --------------------
const Color kPrimaryColor = Color.fromARGB(255, 0, 107, 92);
const Color kSecondaryColor = Color.fromARGB(184, 0, 150, 136);
const Color kCardColor = Color.fromARGB(255, 0, 107, 92);
const Color kBackgroundColor = Color(0xFFE0F2F1);
const Color kTextColor = Colors.white;
const Color kInactiveTextColor = Colors.white70;
const double kCardRadius = 12.0;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = true;
  String _errorMessage = '';

  static const String correctPassword = "1234"; // change as needed

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool loggedIn = prefs.getBool('loggedIn') ?? false;
    if (loggedIn) {
      _goToHome();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _login() async {
    if (_passwordController.text == correctPassword) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('loggedIn', true);
      _goToHome();
    } else {
      setState(() {
        _errorMessage = 'Incorrect password';
      });
    }
  }

  void _goToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      color: kCardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 350),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Enter Password",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 20),
              _buildCard(
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: const TextStyle(color: kInactiveTextColor),
                    errorText: _errorMessage.isEmpty ? null : _errorMessage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kCardRadius),
                    ),
                    filled: true,
                    fillColor: kSecondaryColor.withOpacity(0.2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kCardRadius)),
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

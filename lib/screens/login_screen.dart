import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLogin = true;
  String error = '';

  Future<void> _handleAuth() async {
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      // Well‑structured FirebaseAuth errors
      print('FirebaseAuthException: code=${e.code} message=${e.message}');
      setState(() {
        error = e.message ?? 'Authentication error';
      });
    } on PlatformException catch (e) {
      // Rare low‑level platform errors
      print(
        'PlatformException: code=${e.code} message=${e.message} details=${e.details}',
      );
      setState(() {
        error = e.message ?? 'Platform error';
      });
    } catch (e, stack) {
      // Handle Pigeon list error or anything else
      if (e is List && e.length >= 2) {
        final code = e[0]?.toString() ?? 'unknown';
        final message = e[1]?.toString() ?? 'Unknown error';
        print('Pigeon error: code=$code message=$message');
        setState(() {
          error = message;
        });
      } else {
        print('Unknown login error: $e\n$stack');
        setState(() {
          error = 'Unexpected error: ${e.runtimeType}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLogin ? "Login" : "Register",
                style: TextStyle(fontSize: 24),
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Password"),
              ),
              if (error.isNotEmpty) ...[
                SizedBox(height: 10),
                Text(error, style: TextStyle(color: Colors.red)),
              ],
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _handleAuth,
                child: Text(isLogin ? "Login" : "Register"),
              ),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(
                  isLogin
                      ? "Don't have an account? Register"
                      : "Already registered? Login",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

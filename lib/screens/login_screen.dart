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
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;
  String error = '';
  bool _loading = false;

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      error = '';
      _loading = true;
    });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (email.isEmpty || password.isEmpty) {
        setState(() {
          error = 'Email and password cannot be empty.';
        });
        return;
      }
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        error = _friendlyError(e);
      });
    } catch (e, stack) {
      print('Unexpected error: $e\n$stack');
      setState(() {
        error = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Please log in or use another email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'The email or password is incorrect. Please try again.';
      default:
        if (e.message != null &&
            e.message!.toLowerCase().contains('auth credential is incorrect')) {
          return 'The email or password is incorrect. Please try again.';
        }
        return e.message ?? 'Authentication error. Please try again.';
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => error = 'Enter your email to reset password.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Password reset email sent!')));
    } on FirebaseAuthException catch (e) {
      setState(() => error = _friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLogin ? "Login" : "Register",
                    style: TextStyle(fontSize: 24),
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: "Email"),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email required';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: "Password"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password required';
                      }
                      if (!isLogin && value.length < 6) {
                        return 'Password should be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  if (error.isNotEmpty) ...[
                    SizedBox(height: 10),
                    Text(error, style: TextStyle(color: Colors.red)),
                  ],
                  SizedBox(height: 20),
                  _loading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
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
                  if (isLogin)
                    TextButton(
                      onPressed: _resetPassword,
                      child: Text("Forgot password?"),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ignore_for_file: library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  final String _phone = '';
  // ignore: unused_field
  String _confirmPassword = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      try {
        // Create user with email and password
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );

        // Send verification email
        await userCredential.user?.sendEmailVerification();

        // Extract data from email if it matches college format
        String batch = "";
        String branch = "Select Branch";
        String program = "";
        String rollNo = _email.split('@')[0].toUpperCase();
        bool isCollegeEmail = _email.endsWith('@rgipt.ac.in') &&
            RegExp(r'^[0-9]{2}[a-zA-Z]{2}[0-9]{4}$').hasMatch(rollNo);

        if (isCollegeEmail) {
          // Parse batch and branch
          batch =
              '20${rollNo.substring(0, 2)}'; // First two digits for batch
          String branchCode =
              rollNo.substring(2, 4).toUpperCase(); // Branch code
          program= 'B.Tech';

          // Map branch codes to full names
          Map<String, String> branchMap = {
            'IT': 'Information Technology',
            'CS': 'Computer Science',
            'CD': 'Computer Science and Design',
            'CE': 'Chemical Engineering',
          };

          branch = branchMap[branchCode] ?? '';

          // Check for IDD branch
          if (branchCode.startsWith('CS') && rollNo.substring(4, 6) == '20') {
            branch = 'Integrated Dual Degree (IDD)';
          }
        }

        // Store user data in Firestore under the "users" collection
        DocumentReference userDoc = FirebaseFirestore.instance
            .collection('users') // All users under the same collection
            .doc(userCredential.user?.uid);

        await userDoc.set({
          'name': _name,
          'email': _email,
          'phone': _phone,
          'createdAt': DateTime.now(),
          'program':isCollegeEmail ? program : null,
          'rollNo': isCollegeEmail ? rollNo : null,
          'batch': isCollegeEmail ? batch : null,
          'branch': isCollegeEmail ? branch : null,
          'profilePic':'',
          'banned':false,
          'profileCompletionStatus':0,
        });

        // Show verification message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Verify your email to log in.'),
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate back to login page after showing the message
        Future.delayed(const Duration(seconds: 3), () {
          Navigator.pop(context);
        });
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage =
                'This email is already in use. Please try logging in.';
            break;
          case 'weak-password':
            errorMessage = 'The password provided is too weak.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is not valid.';
            break;
          default:
            errorMessage = 'Sign Up failed: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false; // Hide loading indicator
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),

        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildTextField(
                  'Full Name', 'Enter your full name', Icons.person, false,
                  (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                if (value.length < 2) {
                  return 'Name must be at least 2 characters long';
                }
                return null;
              }, (value) {
                _name = value;
              }),
               SizedBox(height: MediaQuery.of(context).size.width * 0.04),
              _buildTextField(
                  'Email', 'Enter your college email', Icons.email, false,
                  (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                if(!_email.endsWith('@rgipt.ac.in'))
                {
                  return 'Please enter your college email';
                }
                return null;
              }, (value) {
                _email = value;
              }),
               SizedBox(height: MediaQuery.of(context).size.width * 0.04),
              _buildPasswordField('Password', 'Enter your password', (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters long';
                }
                return null;
              }, (value) {
                _password = value;
              }),
               SizedBox(height: MediaQuery.of(context).size.width * 0.04),
              _buildPasswordField('Confirm Password', 'Re-enter your password',
                  (value) {
                if (value != _password) return 'Passwords do not match';
                return null;
              }, (value) {
                _confirmPassword = value;
              }),
               SizedBox(height: MediaQuery.of(context).size.width * 0.04),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        minimumSize:  Size(double.infinity, MediaQuery.of(context).size.width * 0.12),
                      ),
                      child: const Text('Sign Up'),
                    ),
               SizedBox(height: MediaQuery.of(context).size.width * 0.04),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      String hint,
      IconData icon,
      bool obscureText,
      String? Function(String?)? validator,
      Function(String)? onChanged) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildPasswordField(String label, String hint,
      String? Function(String?)? validator, Function(String)? onChanged) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon:
              Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: const OutlineInputBorder(),
      ),
      obscureText: _obscurePassword,
      validator: validator,
      onChanged: onChanged,
    );
  }
}

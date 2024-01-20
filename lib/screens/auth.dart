import 'dart:io';

import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final firebaseAuthInstance = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  // #TODO - Adding FormKey
  final _formKey = GlobalKey<FormState>();
  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredUserName = '';
  var _enteredPassword = '';
  var _isLoading = false;
  File? _selectedImage;

  void _submit() async {
    final _isValid = _formKey.currentState!.validate();

    if (!_isValid || !_isLogin && _selectedImage == null) {
      return;
    }

    _formKey.currentState!.save();

    try {
      setState(() {
        _isLoading = true;
      });
      if (_isLogin) {
        // Login
        await firebaseAuthInstance.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
        setState(() {
          _isLoading = false;
        });
      } else {
        // Signup
        final signupResult =
            await firebaseAuthInstance.createUserWithEmailAndPassword(
                email: _enteredEmail, password: _enteredPassword);

        final fileStorageRef = FirebaseStorage.instance
            .ref()
            .child('user')
            .child('${signupResult.user!.uid}.jpg');

        await fileStorageRef.putFile(_selectedImage!);
        final imageUrl = await fileStorageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(signupResult.user!.uid)
            .set({
          'email': _enteredEmail,
          'user_name': _enteredUserName,
          'user_image': imageUrl,
        });

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('User Created'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ));
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message ?? 'Authentication/Signup failed'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.only(
                    top: 30,
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  width: 200,
                  child: Image.asset('assets/images/chat.png'),
                ),
                Card(
                  margin: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_isLogin)
                              UserImagePicker(
                                onPickedImage: (pickedImage) {
                                  _selectedImage = pickedImage;
                                },
                              ),
                            TextFormField(
                              decoration: const InputDecoration(
                                  labelText: 'Email Address'),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    !value.contains('@')) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                              onSaved: (textValue) {
                                _enteredEmail = textValue!;
                              },
                            ),
                            if (!_isLogin)
                              TextFormField(
                                  decoration: const InputDecoration(
                                      labelText: 'User Name'),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty ||
                                        value.trim().length < 4) {
                                      return 'Username must be at least 4 characters long';
                                    }
                                    return null;
                                  },
                                  onSaved: (userNameValue) {
                                    _enteredUserName = userNameValue!;
                                  }),
                            TextFormField(
                              decoration:
                                  const InputDecoration(labelText: 'Password'),
                              obscureText: true, // Hide typed characters
                              validator: (value) {
                                if (value == null || value.trim().length < 6) {
                                  return 'Password must be at least 6 characters long';
                                }
                                return null;
                              },
                              onSaved: (passwordValue) {
                                _enteredPassword = passwordValue!;
                              },
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      semanticsLabel:
                                          'Circular progress indicator',
                                    )
                                  : Text(_isLogin ? 'Login' : 'Signup'),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                              child: Text(_isLogin
                                  ? 'Create an account'
                                  : 'I already have an account'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}

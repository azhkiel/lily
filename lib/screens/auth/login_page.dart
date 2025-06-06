import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mentaly/screens/home/home_page.dart';
import 'register_page.dart';
import 'package:mentaly/db/database.dart';
import 'package:mentaly/screens/databaseScreen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showSuccessDialog = false;
  bool _showFailureDialog = false;

  @override
  void dispose() {
    // Clean up controllers when the widget is disposed
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Function to handle login
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      print('Attempting login with username: $username');

      final user = await DatabaseHelper.instance.getUser(username);
      print('User found: ${user != null}');

      if (user == null || user['password'] != password) {
        // Show failure popup with animation
        setState(() {
          _showFailureDialog = true;
        });
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            _showFailureDialog = false;
          });
        });
      } else {
        // Show success popup with animation
        setState(() {
          _showSuccessDialog = true;
        });
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            _showSuccessDialog = false;
          });
        });

        print('Login successful, navigating to HomePage');
        // Get userId after successful validation
        final userId = user['id']; // Get userId from the query result

        // Save user session data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        await prefs.setInt('userId', userId);

        // Navigate to HomePage
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomePage(username: username, userId: userId)),
          (route) => false,
        );
      }
    } catch (e) {
      print('Login error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during login: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DatabaseManagementScreen()),
              );
            },
            tooltip: 'View Database',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Section
                Container(
                  margin: const EdgeInsets.only(bottom: 40, top: 20),
                  child: Image.asset(
                    'assets/logo.png', // Replace with your logo path
                    height: 150,
                    width: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading logo: $error');
                      return const Icon(Icons.image_not_supported, size: 150);
                    },
                  ),
                ),

                // Welcome Text
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please login to continue',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Username is required'
                      : null,
                ),
                const SizedBox(height: 20),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Password is required'
                      : null,
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'LOGIN',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                ),
                const SizedBox(height: 20),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      // Pop-up dialog for login success
      floatingActionButton: _showSuccessDialog
          ? AnimatedOpacity(
              opacity: _showSuccessDialog ? 1.0 : 0.0,
              duration: const Duration(seconds: 1),
              child: Center(
                child: Container(
                  color: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: const Text(
                    'Login Successful!',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            )
          : _showFailureDialog
              ? AnimatedOpacity(
                  opacity: _showFailureDialog ? 1.0 : 0.0,
                  duration: const Duration(seconds: 1),
                  child: Center(
                    child: Container(
                      color: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: const Text(
                        'Invalid Username or Password',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(), // No dialog shown if login is still in progress
    );
  }
}

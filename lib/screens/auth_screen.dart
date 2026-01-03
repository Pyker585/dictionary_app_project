
import 'package:dictionary_app/models/auth_model.dart';
import 'package:dictionary_app/screens/home_screen.dart';
import 'package:dictionary_app/services/auth_service.dart';
import 'package:flutter/material.dart';


class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  final TextEditingController _registerNameController = TextEditingController();
  final TextEditingController _registerEmailController = TextEditingController();
  final TextEditingController _registerPasswordController = TextEditingController();
  final TextEditingController _registerConfirmPasswordController = TextEditingController();

  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _registerFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = LoginRequest(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );

      final response = await AuthService.login(request);

      if (response.success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        _showErrorDialog(response.message);
      }
    } on AuthException {
      // _showErrorDialog(getAuthErrorMessage(e));
    } catch (e) {
      _showErrorDialog('កំហុសមិនស្គាល់: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    if (_registerPasswordController.text != _registerConfirmPasswordController.text) {
      _showErrorDialog('ពាក្យសម្ងាត់មិនត្រូវគ្នាទេ');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = RegisterRequest(
        name: _registerNameController.text.trim(),
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text,
      );

      final response = await AuthService.register(request);

      if (response.success) {
        _tabController.animateTo(0);
        _showSuccessDialog('ចុះឈ្មោះជោគជ័យ! សូមចូលប្រើប្រាស់។');
        
        _registerNameController.clear();
        _registerEmailController.clear();
        _registerPasswordController.clear();
        _registerConfirmPasswordController.clear();
      } else {
        _showErrorDialog(response.message);
      }
    } on AuthException {
      // _showErrorDialog(getAuthErrorMessage(e));
    } catch (e) {
      _showErrorDialog('កំហុសមិនស្គាល់: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('កំហុស', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('យល់ព្រម'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ជោគជ័យ', style: TextStyle(color: Colors.green)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('យល់ព្រម'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              SizedBox(height: 40),
              Icon(
                Icons.book,
                size: 80,
                color: Colors.blue,
              ),
              SizedBox(height: 20),
              Text(
                'វចនានុក្រម អងគ្លេស-ខ្មែរ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              SizedBox(height: 10),
              Text(
                'សូមចុះឈ្មោះ ឬចូលប្រើប្រាស់',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 30),

              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[700],
                  indicator: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tabs: [
                    Tab(text: 'ចូលប្រើប្រាស់'),
                    Tab(text: 'ចុះឈ្មោះ'),
                  ],
                ),
              ),
              SizedBox(height: 20),

              SizedBox(
                height: 500,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLoginForm(),
                    _buildRegisterForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginEmailController,
            decoration: InputDecoration(
              labelText: 'អ៊ីមែល',
              prefixIcon: Icon(Icons.email, color: Colors.blue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'សូមបញ្ចូលអ៊ីមែល';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'អ៊ីមែលមិនត្រឹមត្រូវទេ';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          TextFormField(
            controller: _loginPasswordController,
            decoration: InputDecoration(
              labelText: 'ពាក្យសម្ងាត់',
              prefixIcon: Icon(Icons.lock, color: Colors.blue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) return 'សូមបញ្ចូលពាក្យសម្ងាត់';
              if (value.length < 6) return 'ពាក្យសម្ងាត់ត្រូវតែយ៉ាងតិច ៦ តួអក្សរ';
              return null;
            },
          ),
          SizedBox(height: 20),

          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text('ចូលប្រើប្រាស់', style: TextStyle(fontSize: 16)),
          ),
          SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('ឬ', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(child: Divider()),
            ],
          ),
          SizedBox(height: 20),

          OutlinedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: BorderSide(color: Colors.blue),
            ),
            child: Text(
              'បន្តដោយមិនចូលប្រើប្រាស់',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _registerNameController,
            decoration: InputDecoration(
              labelText: 'ឈ្មោះពេញ',
              prefixIcon: Icon(Icons.person, color: Colors.blue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'សូមបញ្ចូលឈ្មោះពេញ';
              return null;
            },
          ),
          SizedBox(height: 16),

          TextFormField(
            controller: _registerEmailController,
            decoration: InputDecoration(
              labelText: 'អ៊ីមែល',
              prefixIcon: Icon(Icons.email, color: Colors.blue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'សូមបញ្ចូលអ៊ីមែល';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'អ៊ីមែលមិនត្រឹមត្រូវទេ';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          TextFormField(
            controller: _registerPasswordController,
            decoration: InputDecoration(
              labelText: 'ពាក្យសម្ងាត់',
              prefixIcon: Icon(Icons.lock, color: Colors.blue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) return 'សូមបញ្ចូលពាក្យសម្ងាត់';
              if (value.length < 6) return 'ពាក្យសម្ងាត់ត្រូវតែយ៉ាងតិច ៦ តួអក្សរ';
              return null;
            },
          ),
          SizedBox(height: 16),

          TextFormField(
            controller: _registerConfirmPasswordController,
            decoration: InputDecoration(
              labelText: 'បញ្ជាក់ពាក្យសម្ងាត់',
              prefixIcon: Icon(Icons.lock_outline, color: Colors.blue),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) return 'សូមបញ្ចូលពាក្យសម្ងាត់ម្តងទៀត';
              return null;
            },
          ),
          SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'ពាក្យសម្ងាត់ត្រូវតែយ៉ាងតិច ៦ តួអក្សរ',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: 20),

          ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text('ចុះឈ្មោះ', style: TextStyle(fontSize: 16)),
          ),
          SizedBox(height: 20),

          Text(
            'ដោយចុះឈ្មោះ អ្នកយល់ព្រមទៅនឹងលក្ខខណ្ឌនិងល័ក្ខខ័ណ្ឌរបស់យើង។',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// Add these helper functions for showing messages
void showSuccessMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 2),
    ),
  );
}

void showErrorMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 3),
    ),
  );
}

void showInfoMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.blue,
      duration: Duration(seconds: 2),
    ),
  );
}

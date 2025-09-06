import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'database_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final dbHelper = DatabaseHelper.instance;

  // Save login credentials to SQLite
  void _saveToSQLite() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username and password required')),
      );
      return;
    }

    Map<String, dynamic> row = {
      DatabaseHelper.columnUsername: username,
      DatabaseHelper.columnPassword: password,
    };

    await dbHelper.insert(row);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login saved locally ✅')),
    );
  }

  // Upload SQLite data to MySQL via Laravel API
  void _uploadToServer() async {
     try {
    // Get last saved user from SQLite
    final lastUser = await dbHelper.getLastUser();
    if (lastUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user found in SQLite ❌')),
      );
      return;
    }

    String username = lastUser[DatabaseHelper.columnUsername];
    String password = lastUser[DatabaseHelper.columnPassword];

    final url = Uri.parse("http://192.168.29.244/flutter_api/upload.php");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "username": username,
        "password": password,
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Uploaded ✅")),
      );
    } else if (response.statusCode == 409) {
      final data = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Already exists ❌")),
      );
    } else if (response.statusCode == 400) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing username or password ❌")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server error: ${response.statusCode} ❌")),
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Upload failed: $e")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle:true,
      title: const Text('Login Page ',
      style: TextStyle(fontSize:30,fontWeight: FontWeight.bold,color: Color.fromARGB(255, 6, 230, 193),
      
      ),
      ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
           

            TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username')),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveToSQLite, child: const Text('Login')),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _uploadToServer, child: const Text('Upload to Server')),
          ],
        ),
      ),
    );
  }
}

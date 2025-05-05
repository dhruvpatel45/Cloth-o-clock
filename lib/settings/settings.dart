import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'changepassword.dart';
import 'editprofile.dart';
import 'package:hello/login/login.dart';
import 'privacypolicy.dart';
import 'about_us_page.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String email = '', name = '', phone = '', userId = '';
  String? _selectedRole;

  final List<String> _roles = [
    'Only Rent/Buy the product',
    'Customer and Seller both',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('email') ?? '';
      name = prefs.getString('name') ?? '';
      phone = prefs.getString('phone') ?? '';
      userId = prefs.getString('id') ?? '';
    });

    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('userId') ?? '';
      print('User ID to delete: $id');

      if (id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user ID found')),
        );
        return;
      }

      // Option 1: Using GET request (like your working example)
      final response = await http.get(
        Uri.parse('http://192.168.205.252/flutter_api/get_user_role.php?id=$id'),
        headers: {'Accept': 'application/json'},
      );

      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            // Make sure this matches exactly with your _roles list items
            _selectedRole = data['role'];
            print('Updated role to: $_selectedRole');
          });
        }
      }
    } catch (e) {
      print('Error loading role: $e');
    }
  }
  Future<void> _changeRole(String newRole) async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('userId') ?? '';
    print('User ID to delete: $id');

    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user ID found')),
      );
      return;
    }

    // Option 1: Using GET request (like your working example)
    final response = await http.get(
      Uri.parse('http://192.168.205.252/flutter_api/update_user_role.php?id=$id&&role=$newRole'),
      headers: {'Accept': 'application/json'},
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MyLogin()),
          (route) => false,
    );
    /*if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        await prefs.setString('role', newRole);
        await prefs.remove('id');
        await prefs.remove('email');

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MyLogin()),
              (route) => false,
        );
      }
    }*/
  }

  Future<void> _logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;

    await prefs.clear();
    await prefs.setBool('isDarkMode', isDark);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MyLogin()),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logoutUser();
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete your account? This action is irreversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('userId') ?? '';
      print('User ID to delete: $id');

      if (id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user ID found')),
        );
        return;
      }

      // Option 1: Using GET request (like your working example)
      final response = await http.get(
        Uri.parse('http://192.168.205.252/flutter_api/delete_user_account.php?id=$id'),
        headers: {'Accept': 'application/json'},
      );

      // Option 2: Using POST request with JSON (alternative)
      // final response = await http.post(
      //   Uri.parse('http://192.168.205.252/flutter_api/delete_user_account.php'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode({"user_id": id}),
      // );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        await prefs.clear();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MyLogin()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Account deletion failed')),
        );
      }
    } catch (e) {
      print('Error deleting account: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkMode = themeNotifier.isDarkMode;

    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth * 0.045;

    final backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.brown[50]!;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text("Settings", style: TextStyle(color: textColor)),
        backgroundColor: backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      backgroundColor: backgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          _buildListTile("Edit Profile", Icons.person, textColor, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfileScreen(
                  email: email,
                  phone: phone,
                  name: name,
                  userId: userId,
                ),
              ),
            );
          }),
          _buildListTile("Change Password", Icons.lock, textColor, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePasswordScreen()));
          }),
          _buildListTile("Privacy Policy", Icons.privacy_tip, textColor, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()));
          }),
          _buildListTile("About Us", Icons.info_outline, textColor, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AboutUsPage()));
          }),
          const SizedBox(height: 20),
          Text("Theme", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          SwitchListTile(
            title: Text("Dark Mode", style: TextStyle(fontSize: 16, color: textColor)),
            value: isDarkMode,
            activeColor: Colors.black,
            onChanged: themeNotifier.toggleTheme,
          ),
          const SizedBox(height: 20),
          Text("Preferences", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          ListTile(
            leading: Icon(Icons.switch_account, color: textColor),
            title: Text("Change Role", style: TextStyle(color: textColor)),
            subtitle: Text(_selectedRole ?? "Loading...", style: TextStyle(color: textColor)),
            trailing: DropdownButton<String>(
              value: _selectedRole,
              dropdownColor: backgroundColor,
              iconEnabledColor: textColor,
              onChanged: (newValue) {
                if (newValue != null && newValue != _selectedRole) {
                  _changeRole(newValue);
                  print(newValue);
                }
              },
              items: _roles.map((role) {
                return DropdownMenuItem<String>(
                  value: role,
                  child: Text(role, style: TextStyle(color: textColor)),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          _buildListTile("Delete Account", Icons.delete_forever, Colors.red, _confirmDeleteAccount),
          const SizedBox(height: 40),
          Center(
            child: ElevatedButton.icon(
              onPressed: _confirmLogout,
              icon: Icon(Icons.logout_outlined, color: isDarkMode ? Colors.black : Colors.white),
              label: Text("Logout", style: TextStyle(fontSize: fontSize, color: isDarkMode ? Colors.black : Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, Color textColor, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title, style: TextStyle(fontSize: 16, color: textColor)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
      onTap: onTap,
    );
  }
}
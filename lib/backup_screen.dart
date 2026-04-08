import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';
import 'export_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  final ExportService _exportService = ExportService();
  bool _isLoading = false;
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _firebaseService.signIn(_emailController.text, _passwordController.text);
      } else {
        await _firebaseService.signUp(_emailController.text, _passwordController.text);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isLogin ? 'Logged in successfully!' : 'Account created!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final credential = await _firebaseService.signInWithGoogle();
      if (credential != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged in with Google!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Sign-In failed: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBackup() async {
    setState(() => _isLoading = true);
    try {
      await _firebaseService.uploadBackup();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup successful!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: const Text('This will overwrite all local data with the cloud backup. ARE YOU SURE?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('YES, RESTORE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _firebaseService.downloadRestore();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore successful!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleExport() async {
    setState(() => _isLoading = true);
    try {
      await _exportService.exportToZip();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export successful! Check your downloads.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Synchronization')),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            return _buildAuthUI();
          }

          return _buildBackupUI(user);
        },
      ),
    );
  }

  Widget _buildAuthUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_queue, size: 80, color: Colors.deepPurpleAccent),
          const SizedBox(height: 24),
          const Text('Secure your data with Cloud Sync', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()), obscureText: true),
          const SizedBox(height: 24),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _handleAuth, child: Text(_isLogin ? 'Login' : 'Register')),
                ),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin ? 'Need an account? Create one' : 'Already have an account? Login'),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('OR', style: TextStyle(color: Colors.grey))),
                      Expanded(child: Divider()),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: const BorderSide(color: Colors.white70),
                    ),
                    onPressed: _handleGoogleSignIn,
                    icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg', 
                      height: 24, 
                      errorBuilder: (context, object, stack) => const Icon(Icons.login),
                    ),
                    label: const Text('Continue with Google'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBackupUI(User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_done, size: 80, color: Colors.cyanAccent),
          const SizedBox(height: 16),
          Text('Logged in as: ${user.email}'),
          const Divider(height: 48),
          const Text('Cloud Sync Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleBackup,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('UPLOAD BACKUP'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleRestore,
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('RESTORE FROM CLOUD'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.deepPurple),
                  ),
                ),
                const Divider(height: 48),
                const Text('Local Data Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _handleExport,
                    icon: const Icon(Icons.folder_zip, color: Colors.amberAccent),
                    label: const Text('EXPORT AS CSV (ZIP BUNDLE)', style: TextStyle(color: Colors.amberAccent)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: const BorderSide(color: Colors.amberAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                TextButton(onPressed: () => _firebaseService.signOut(), child: const Text('Sign Out', style: TextStyle(color: Colors.red))),
              ],
            ),
        ],
      ),
    );
  }
}

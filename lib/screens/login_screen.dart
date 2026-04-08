import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin/admin_home.dart';
import 'porteria/porteria_home.dart';
import 'residente/residente_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await _auth.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
      if (user != null) {
        final rol = _auth.getRol(user.email ?? '');
        if (!mounted) return;
        Widget destino;
        if (rol == 'admin') {
          destino = const AdminHome();
        } else if (rol == 'portero') {
          destino = const PorteriaHome();
        } else {
          destino = ResidenteHome(email: user.email ?? '');
        }
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => destino));
      }
    } catch (e) {
      setState(() { _error = 'Correo o contraseña incorrectos'; });
    }
    setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3C5E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.apartment, size: 80, color: Colors.white),
                const SizedBox(height: 16),
                const Text('Mi Conjunto',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold,
                      color: Colors.white)),
                const SizedBox(height: 8),
                const Text('Gestión residencial',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A3C5E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Ingresar',
                                style: TextStyle(fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
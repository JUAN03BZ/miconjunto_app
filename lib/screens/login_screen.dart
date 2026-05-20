import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool _verPass = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await _auth.login(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );
      if (user != null) {
        await _auth.crearUsuarioSiNoExiste(user);
        final rol = await _auth.getRol(user.uid);
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
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = (e.code == 'user-not-found' ||
                e.code == 'wrong-password' ||
                e.code == 'invalid-credential')
            ? 'Correo o contraseña incorrectos'
            : 'Error: ${e.message}';
      });
    } catch (e) {
      setState(() { _error = 'Error inesperado. Intenta de nuevo.'; });
    }
    if (mounted) setState(() { _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A3C5E), Color(0xFF0D2137)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Nombre y slogan ───────────────────────
                  const Text(
                    'MI CONJUNTO',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tu comunidad, a un toque de distancia.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Tarjeta login ─────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3C5E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ingresa con tu cuenta asignada',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 20),

                        // Email
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: const Icon(
                                Icons.email_outlined,
                                color: Color(0xFF1A3C5E)),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1A3C5E),
                                  width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Contraseña
                        TextField(
                          controller: _passCtrl,
                          obscureText: !_verPass,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(
                                Icons.lock_outlined,
                                color: Color(0xFF1A3C5E)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _verPass
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(
                                  () => _verPass = !_verPass),
                            ),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1A3C5E),
                                  width: 2),
                            ),
                          ),
                        ),

                        // Error
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius:
                                  BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.red.shade200),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(_error!,
                                      style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 13))),
                            ]),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Botón ingresar
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF1A3C5E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5))
                                : const Text('Ingresar',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight:
                                            FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Verde del logo abajo ───────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text(
                        'Tu comunidad segura y conectada',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
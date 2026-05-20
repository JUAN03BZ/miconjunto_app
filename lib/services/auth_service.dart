import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // Ahora el rol viene de Firestore, no del correo
  Future<String> getRol(String uid) async {
    try {
      final doc = await _db.collection('usuarios').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['rol'] ?? 'residente';
      }
      return 'residente';
    } catch (e) {
      return 'residente';
    }
  }

  // Crea el documento del usuario si no existe
  Future<void> crearUsuarioSiNoExiste(User user) async {
    final doc = await _db.collection('usuarios').doc(user.uid).get();
    if (!doc.exists) {
      await _db.collection('usuarios').doc(user.uid).set({
        'email': user.email,
        'rol': 'residente', // rol por defecto
        'nombre': '',
        'creadoEn': FieldValue.serverTimestamp(),
      });
    }
  }
}
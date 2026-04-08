import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  
  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get email => FirebaseAuth.instance.currentUser?.email ?? '';

  // ── VISITAS ──────────────────────────────────────────────
  Future<void> registrarVisita(Map<String, dynamic> data) async {
    await _db.collection('visitas').add({
      ...data,
      'uid': uid,
      'email': email,
      'fecha': FieldValue.serverTimestamp(),
      'estado': 'Registrada',
    });
  }

  Stream<QuerySnapshot> misVisitas() {
    return _db
        .collection('visitas')
        .where('uid', isEqualTo: uid)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // ── PAGOS ────────────────────────────────────────────────
  Stream<QuerySnapshot> misPagos() {
    return _db
        .collection('pagos')
        .where('uid', isEqualTo: uid)
        .orderBy('fechaVencimiento', descending: false)
        .snapshots();
  }

  Future<void> marcarPagado(String docId) async {
    await _db.collection('pagos').doc(docId).update({
      'estado': 'Pagado',
      'fechaPago': FieldValue.serverTimestamp(),
    });
  }

  Future<void> inicializarPagosResidente() async {
    // Crea pagos de ejemplo si el residente no tiene ninguno
    final existing = await _db.collection('pagos')
        .where('uid', isEqualTo: uid).limit(1).get();
    if (existing.docs.isEmpty) {
      final pagosBase = [
        {'concepto': 'Administración Marzo 2026', 'monto': 280000,
         'estado': 'Pagado', 'fechaVencimiento': Timestamp.fromDate(DateTime(2026, 3, 30))},
        {'concepto': 'Administración Abril 2026', 'monto': 280000,
         'estado': 'Pendiente', 'fechaVencimiento': Timestamp.fromDate(DateTime(2026, 4, 30))},
        {'concepto': 'Administración Mayo 2026', 'monto': 280000,
         'estado': 'Pendiente', 'fechaVencimiento': Timestamp.fromDate(DateTime(2026, 5, 30))},
      ];
      for (final p in pagosBase) {
        await _db.collection('pagos').add({...p, 'uid': uid, 'email': email});
      }
    }
  }

  // ── PQRS ─────────────────────────────────────────────────
  Future<void> enviarPqrs(Map<String, dynamic> data) async {
    await _db.collection('pqrs').add({
      ...data,
      'uid': uid,
      'email': email,
      'estado': 'En revisión',
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> misPqrs() {
    return _db
        .collection('pqrs')
        .where('uid', isEqualTo: uid)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  // ── RESERVAS ─────────────────────────────────────────────
  Future<void> crearReserva(Map<String, dynamic> data) async {
    await _db.collection('reservas').add({
      ...data,
      'uid': uid,
      'email': email,
      'estado': 'Confirmada',
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> misReservas() {
    return _db
        .collection('reservas')
        .where('uid', isEqualTo: uid)
        .orderBy('creadoEn', descending: true)
        .snapshots();
  }

  Future<void> cancelarReserva(String docId) async {
    await _db.collection('reservas').doc(docId).update({'estado': 'Cancelada'});
  }

  // ── CASILLERO ────────────────────────────────────────────
  Stream<QuerySnapshot> misCasillas() {
    return _db
        .collection('casillero')
        .where('email', isEqualTo: email)
        .orderBy('fechaLlegada', descending: true)
        .snapshots();
  }

  Future<void> marcarRecogido(String docId) async {
    await _db.collection('casillero').doc(docId).update({
      'estado': 'Recogido',
      'fechaRecogido': FieldValue.serverTimestamp(),
    });
  }

  // ── COMUNICADOS ──────────────────────────────────────────
  Stream<QuerySnapshot> comunicados() {
    return _db
        .collection('comunicados')
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  Future<void> publicarComunicado(Map<String, dynamic> data) async {
    await _db.collection('comunicados').add({
      ...data,
      'autorEmail': email,
      'fecha': FieldValue.serverTimestamp(),
    });
  }
}
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final opciones = [
      {'icon': Icons.campaign, 'label': 'Comunicados',
       'color': const Color(0xFF9C27B0), 'accion': 'comunicados'},
      {'icon': Icons.inbox, 'label': 'Casilleros',
       'color': const Color(0xFFFF9800), 'accion': 'casillero'},
      {'icon': Icons.people, 'label': 'Visitas',
       'color': const Color(0xFF2196F3), 'accion': 'visitas'},
      {'icon': Icons.report_problem, 'label': 'PQRS',
       'color': const Color(0xFFF44336), 'accion': 'pqrs'},
      {'icon': Icons.event_available, 'label': 'Reservas',
       'color': const Color(0xFF009688), 'accion': 'reservas'},
      {'icon': Icons.bar_chart, 'label': 'Reportes',
       'color': const Color(0xFF795548), 'accion': 'reportes'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Panel Administrador',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A3C5E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1A3C5E), Color(0xFF2E6DA4)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bienvenido,', style: TextStyle(color: Colors.white70)),
              Text('Administrador', style: TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Conjunto Residencial', style: TextStyle(color: Colors.white70)),
            ]),
          ),
          const SizedBox(height: 24),
          const Text('Módulos de gestión',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3C5E))),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12,
                  mainAxisSpacing: 12, childAspectRatio: 1.1),
              itemCount: opciones.length,
              itemBuilder: (_, i) {
                final op = opciones[i];
                return GestureDetector(
                  onTap: () => _onTap(context, op['accion'] as String),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (op['color'] as Color).withOpacity(0.1),
                          shape: BoxShape.circle),
                        child: Icon(op['icon'] as IconData,
                            color: op['color'] as Color, size: 32)),
                      const SizedBox(height: 12),
                      Text(op['label'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  void _onTap(BuildContext context, String accion) {
    if (accion == 'comunicados') {
      _mostrarFormComunicado(context);
    } else if (accion == 'casillero') {
      _mostrarFormCasillero(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Módulo $accion próximamente')));
    }
  }

  void _mostrarFormComunicado(BuildContext context) {
    final tituloCtrl = TextEditingController();
    final contenidoCtrl = TextEditingController();
    final fs = FirestoreService();
    bool guardando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Publicar Comunicado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: tituloCtrl,
              decoration: InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contenidoCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Contenido del comunicado',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: guardando ? null : () async {
                  if (tituloCtrl.text.isEmpty || contenidoCtrl.text.isEmpty) return;
                  setModal(() => guardando = true);
                  await fs.publicarComunicado({
                    'titulo': tituloCtrl.text.trim(),
                    'contenido': contenidoCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: Colors.green,
                        content: Text('✅ Comunicado publicado')));
                },
                child: guardando
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Publicar',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _mostrarFormCasillero(BuildContext context) {
    final emailCtrl = TextEditingController();
    final remitenteCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final fs = FirestoreService();
    bool guardando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Registrar Paquete',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo del residente destinatario',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: remitenteCtrl,
              decoration: InputDecoration(
                labelText: 'Remitente (ej: Amazon)',
                prefixIcon: const Icon(Icons.store),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: 'Descripción del paquete',
                prefixIcon: const Icon(Icons.inventory_2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: guardando ? null : () async {
                  if (emailCtrl.text.isEmpty || remitenteCtrl.text.isEmpty) return;
                  setModal(() => guardando = true);
                  await FirebaseFirestore.instance.collection('casillero').add({
                    'email': emailCtrl.text.trim().toLowerCase(),
                    'remitente': remitenteCtrl.text.trim(),
                    'descripcion': descCtrl.text.trim(),
                    'estado': 'Sin recoger',
                    'fechaLlegada': FieldValue.serverTimestamp(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(backgroundColor: Colors.green,
                        content: Text('✅ Paquete registrado. El residente verá la notificación.')));
                },
                child: guardando
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Registrar paquete',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
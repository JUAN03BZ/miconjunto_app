import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class CasilleroScreen extends StatelessWidget {
  const CasilleroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Casillero'),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: fs.misCasillas(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          final sinRecoger =
              docs.where((d) => (d.data() as Map)['estado'] == 'Sin recoger').length;

          if (docs.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No tienes paquetes pendientes',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Cuando llegue un paquete te notificaremos aquí',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center),
              ]),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (sinRecoger > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF9800))),
                  child: Row(children: [
                    const Icon(Icons.inbox, color: Color(0xFFFF9800), size: 32),
                    const SizedBox(width: 12),
                    Expanded(child: Text(
                        '$sinRecoger paquete(s) esperándote en portería',
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                  ]),
                ),
              const SizedBox(height: 16),
              ...docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final sinRec = d['estado'] == 'Sin recoger';
                final ts = d['fechaLlegada'] as Timestamp?;
                final fecha = ts != null
                    ? '${ts.toDate().day.toString().padLeft(2,'0')}/${ts.toDate().month.toString().padLeft(2,'0')}/${ts.toDate().year}'
                    : '-';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          sinRec ? const Color(0xFFFF9800) : Colors.grey,
                      child: const Icon(Icons.inventory_2, color: Colors.white)),
                    title: Text(d['remitente'] ?? 'Paquete',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${d['descripcion'] ?? ''} · $fecha'),
                    trailing: sinRec
                        ? ElevatedButton(
                            onPressed: () async {
                              await fs.marcarRecogido(doc.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      backgroundColor: Colors.green,
                                      content: Text('✅ Paquete marcado como recogido')));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9800),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                            child: const Text('Recoger',
                                style: TextStyle(fontSize: 12)))
                        : const Chip(
                            label: Text('Recogido',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 11)),
                            backgroundColor: Colors.grey),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
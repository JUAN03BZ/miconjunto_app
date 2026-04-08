import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class ComunicadosScreen extends StatelessWidget {
  const ComunicadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunicados'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: fs.comunicados(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.campaign_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No hay comunicados aún',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final ts = d['fecha'] as Timestamp?;
              final fecha = ts != null
                  ? '${ts.toDate().day.toString().padLeft(2,'0')}/${ts.toDate().month.toString().padLeft(2,'0')}/${ts.toDate().year}'
                  : '';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      const Icon(Icons.campaign, color: Color(0xFF9C27B0)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(d['titulo'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15))),
                    ]),
                    const SizedBox(height: 4),
                    Text(fecha,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(d['contenido'] ?? '',
                        style: const TextStyle(fontSize: 14)),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
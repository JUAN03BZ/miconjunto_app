import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class PqrsScreen extends StatefulWidget {
  const PqrsScreen({super.key});
  @override
  State<PqrsScreen> createState() => _PqrsScreenState();
}

class _PqrsScreenState extends State<PqrsScreen> {
  final _fs = FirestoreService();
  String _tipo = 'Petición';
  final _asuntoCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _enviando = false;

  Future<void> _enviar() async {
    if (_asuntoCtrl.text.isEmpty || _descCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completa todos los campos')));
      return;
    }
    setState(() => _enviando = true);
    await _fs.enviarPqrs({
      'tipo': _tipo,
      'asunto': _asuntoCtrl.text.trim(),
      'descripcion': _descCtrl.text.trim(),
    });
    _asuntoCtrl.clear();
    _descCtrl.clear();
    setState(() => _enviando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: Colors.green,
              content: Text('✅ PQRS enviada. Te responderemos pronto.')));
    }
  }

  Color _colorTipo(String tipo) {
    switch (tipo) {
      case 'Queja': return Colors.red;
      case 'Reclamo': return Colors.orange;
      case 'Sugerencia': return Colors.blue;
      default: return const Color(0xFF795548);
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Resuelta': return Colors.green;
      case 'En proceso': return Colors.blue;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PQRS'),
        backgroundColor: const Color(0xFF795548),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Formulario nueva PQRS ──────────────────────────
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nueva solicitud',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text(
                      'Peticiones, quejas, reclamos o sugerencias para el administrador.',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _tipo,
                    decoration: InputDecoration(
                        labelText: 'Tipo de solicitud',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    items: ['Petición', 'Queja', 'Reclamo', 'Sugerencia']
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _tipo = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _asuntoCtrl,
                    decoration: InputDecoration(
                        labelText: 'Asunto',
                        prefixIcon: const Icon(Icons.subject),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                        labelText: 'Descripción detallada',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _enviando ? null : _enviar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF795548),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                      child: _enviando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Enviar PQRS',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text('Mis solicitudes',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // ── Lista de PQRS con respuesta del admin ──────────
          StreamBuilder<QuerySnapshot>(
            stream: _fs.misPqrs(),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                      child: Text('No tienes solicitudes enviadas',
                          style: TextStyle(color: Colors.grey))));
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final estado = d['estado'] ?? 'En revisión';
                  final respuesta = d['respuesta'] as String?;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                          backgroundColor: _colorTipo(d['tipo'] ?? ''),
                          child: const Icon(Icons.report,
                              color: Colors.white)),
                      title: Text(d['asunto'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      subtitle:
                          Text('${d['tipo'] ?? ''} · $estado'),
                      trailing: Chip(
                        label: Text(estado,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11)),
                        backgroundColor: _colorEstado(estado),
                      ),
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Descripción original
                              const Text('Tu solicitud:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(d['descripcion'] ?? '',
                                  style:
                                      const TextStyle(fontSize: 14)),

                              const SizedBox(height: 12),

                              // Respuesta del admin o estado pendiente
                              if (respuesta != null &&
                                  respuesta.isNotEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                        color: Colors.green.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Icon(Icons.check_circle,
                                            color:
                                                Colors.green.shade600,
                                            size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                            'Respuesta del administrador:',
                                            style: TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
                                                color: Colors
                                                    .green.shade700,
                                                fontSize: 13)),
                                      ]),
                                      const SizedBox(height: 6),
                                      Text(respuesta,
                                          style: const TextStyle(
                                              fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.orange.shade200),
                                  ),
                                  child: Row(children: [
                                    Icon(Icons.hourglass_empty,
                                        color: Colors.orange.shade600,
                                        size: 16),
                                    const SizedBox(width: 6),
                                    const Text(
                                        'En espera de respuesta...',
                                        style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 13)),
                                  ]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
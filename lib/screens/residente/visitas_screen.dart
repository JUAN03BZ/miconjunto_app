import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class VisitasScreen extends StatefulWidget {
  const VisitasScreen({super.key});
  @override
  State<VisitasScreen> createState() => _VisitasScreenState();
}

class _VisitasScreenState extends State<VisitasScreen> {
  final _fs = FirestoreService();
  final _nombreCtrl = TextEditingController();
  final _docCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  bool _guardando = false;

  Future<void> _registrar() async {
    if (_nombreCtrl.text.isEmpty || _fechaCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa nombre y fecha')));
      return;
    }
    setState(() => _guardando = true);
    await _fs.registrarVisita({
      'nombre': _nombreCtrl.text.trim(),
      'documento': _docCtrl.text.trim(),
      'fechaVisita': _fechaCtrl.text.trim(),
    });
    _nombreCtrl.clear(); _docCtrl.clear(); _fechaCtrl.clear();
    setState(() => _guardando = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(backgroundColor: Colors.green,
          content: Text('✅ Visita registrada. Portería fue notificada.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Visita'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                const Text('Nueva visita', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Registra tu visita con anticipación para\nevitar esperas en portería.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),
                _campo(_nombreCtrl, 'Nombre del visitante', Icons.person),
                const SizedBox(height: 12),
                _campo(_docCtrl, 'Documento de identidad', Icons.badge),
                const SizedBox(height: 12),
                TextField(
                  controller: _fechaCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Fecha de visita',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (picked != null) {
                      _fechaCtrl.text =
                          '${picked.day.toString().padLeft(2,'0')}/${picked.month.toString().padLeft(2,'0')}/${picked.year}';
                    }
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _registrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                    child: _guardando
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Registrar visita',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Mis visitas registradas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _fs.misVisitas(),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No tienes visitas registradas',
                      style: TextStyle(color: Colors.grey))));
              }
              return Column(
                children: snap.data!.docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF2196F3),
                        child: Icon(Icons.person, color: Colors.white)),
                      title: Text(d['nombre'] ?? ''),
                      subtitle: Text(
                          'Doc: ${d['documento'] ?? '-'} · ${d['fechaVisita'] ?? ''}'),
                      trailing: const Chip(
                        label: Text('Registrada',
                            style: TextStyle(color: Colors.white, fontSize: 11)),
                        backgroundColor: Colors.green),
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

  Widget _campo(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    );
  }
}
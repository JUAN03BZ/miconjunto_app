import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});
  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  final _fs = FirestoreService();

  final List<Map<String, dynamic>> _espacios = [
    {'nombre': 'BBQ', 'icon': Icons.outdoor_grill,
     'color': const Color(0xFFF44336), 'disponible': true},
    {'nombre': 'Piscina', 'icon': Icons.pool,
     'color': const Color(0xFF2196F3), 'disponible': true},
    {'nombre': 'Cancha', 'icon': Icons.sports_soccer,
     'color': const Color(0xFF4CAF50), 'disponible': true},
    {'nombre': 'Salón Comunal', 'icon': Icons.meeting_room,
     'color': const Color(0xFF9C27B0), 'disponible': true},
    {'nombre': 'Gimnasio', 'icon': Icons.fitness_center,
     'color': const Color(0xFFFF9800), 'disponible': true},
    {'nombre': 'Parque Infantil', 'icon': Icons.child_care,
     'color': const Color(0xFF00BCD4), 'disponible': true},
  ];

  void _mostrarFormulario(Map<String, dynamic> espacio) {
    final fechaCtrl = TextEditingController();
    final horaCtrl = TextEditingController();
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
            Row(children: [
              Icon(espacio['icon'] as IconData,
                  color: espacio['color'] as Color),
              const SizedBox(width: 8),
              Text('Reservar ${espacio['nombre']}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: fechaCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Fecha',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (picked != null) {
                  fechaCtrl.text =
                      '${picked.day.toString().padLeft(2,'0')}/${picked.month.toString().padLeft(2,'0')}/${picked.year}';
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: horaCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Hora',
                prefixIcon: const Icon(Icons.access_time),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (picked != null && context.mounted) {
                  horaCtrl.text = picked.format(context);
                }
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: espacio['color'] as Color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
                onPressed: guardando ? null : () async {
                  if (fechaCtrl.text.isEmpty || horaCtrl.text.isEmpty) return;
                  setModal(() => guardando = true);
                  await _fs.crearReserva({
                    'espacio': espacio['nombre'],
                    'fecha': fechaCtrl.text,
                    'hora': horaCtrl.text,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: Colors.green,
                      content: Text('✅ ${espacio['nombre']} reservado')));
                },
                child: guardando
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Confirmar reserva',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas'),
        backgroundColor: const Color(0xFF009688),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Espacios disponibles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12,
                mainAxisSpacing: 12, childAspectRatio: 1.2),
            itemCount: _espacios.length,
            itemBuilder: (_, i) {
              final e = _espacios[i];
              return GestureDetector(
                onTap: () => _mostrarFormulario(e),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: (e['color'] as Color).withOpacity(0.1),
                          shape: BoxShape.circle),
                        child: Icon(e['icon'] as IconData,
                            color: e['color'] as Color, size: 32)),
                      const SizedBox(height: 8),
                      Text(e['nombre'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text('Toca para reservar',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Mis reservas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: _fs.misReservas(),
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No tienes reservas activas',
                      style: TextStyle(color: Colors.grey))));
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final cancelada = d['estado'] == 'Cancelada';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cancelada
                            ? Colors.grey : const Color(0xFF009688),
                        child: const Icon(Icons.event_available,
                            color: Colors.white)),
                      title: Text(d['espacio'] ?? ''),
                      subtitle: Text('${d['fecha']} · ${d['hora']}'),
                      trailing: cancelada
                          ? const Chip(
                              label: Text('Cancelada',
                                  style: TextStyle(color: Colors.white, fontSize: 11)),
                              backgroundColor: Colors.grey)
                          : TextButton(
                              onPressed: () async {
                                await _fs.cancelarReserva(doc.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Reserva cancelada')));
                                }
                              },
                              child: const Text('Cancelar',
                                  style: TextStyle(color: Colors.red))),
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
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
    {'nombre': 'BBQ', 'icon': Icons.outdoor_grill, 'color': const Color(0xFFF44336)},
    {'nombre': 'Piscina', 'icon': Icons.pool, 'color': const Color(0xFF2196F3)},
    {'nombre': 'Cancha', 'icon': Icons.sports_soccer, 'color': const Color(0xFF4CAF50)},
    {'nombre': 'Salón Comunal', 'icon': Icons.meeting_room, 'color': const Color(0xFF9C27B0)},
    {'nombre': 'Gimnasio', 'icon': Icons.fitness_center, 'color': const Color(0xFFFF9800)},
    {'nombre': 'Parque Infantil', 'icon': Icons.child_care, 'color': const Color(0xFF00BCD4)},
  ];

  final List<String> _horas = [
    '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
    '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
    '18:00', '19:00', '20:00', '21:00',
  ];

  void _verDisponibilidad(Map<String, dynamic> espacio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DisponibilidadScreen(
          espacio: espacio,
          horas: _horas,
          fs: _fs,
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
          const Text('Selecciona un espacio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Toca un espacio para ver disponibilidad y reservar',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15),
            itemCount: _espacios.length,
            itemBuilder: (_, i) {
              final e = _espacios[i];
              return GestureDetector(
                onTap: () => _verDisponibilidad(e),
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
                          color: (e['color'] as Color).withOpacity(0.12),
                          shape: BoxShape.circle),
                        child: Icon(e['icon'] as IconData,
                            color: e['color'] as Color, size: 32)),
                      const SizedBox(height: 10),
                      Text(e['nombre'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text('Ver disponibilidad',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
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
                  child: Center(
                      child: Text('No tienes reservas activas',
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
                            ? Colors.grey
                            : const Color(0xFF009688),
                        child: const Icon(Icons.event_available,
                            color: Colors.white)),
                      title: Text(d['espacio'] ?? ''),
                      subtitle: Text('${d['fecha']} · ${d['hora']}'),
                      trailing: cancelada
                          ? const Chip(
                              label: Text('Cancelada',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11)),
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

// ── Pantalla de disponibilidad por horas ───────────────────
class _DisponibilidadScreen extends StatefulWidget {
  final Map<String, dynamic> espacio;
  final List<String> horas;
  final FirestoreService fs;
  const _DisponibilidadScreen(
      {required this.espacio, required this.horas, required this.fs});

  @override
  State<_DisponibilidadScreen> createState() => _DisponibilidadScreenState();
}

class _DisponibilidadScreenState extends State<_DisponibilidadScreen> {
  DateTime _fecha = DateTime.now().add(const Duration(days: 1));
  String? _horaSeleccionada;

  String get _fechaStr =>
      '${_fecha.day.toString().padLeft(2, '0')}/${_fecha.month.toString().padLeft(2, '0')}/${_fecha.year}';

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _reservar(Set<String> horasOcupadas) async {
    if (_horaSeleccionada == null) return;
    if (horasOcupadas.contains(_horaSeleccionada)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esa hora ya está reservada')));
      return;
    }
    await widget.fs.crearReserva({
      'espacio': widget.espacio['nombre'],
      'fecha': _fechaStr,
      'hora': _horaSeleccionada,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.green,
          content: Text(
              '✅ ${widget.espacio['nombre']} reservado el $_fechaStr a las $_horaSeleccionada')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.espacio['color'] as Color;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.espacio['nombre'] as String),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Selector de fecha
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: _seleccionarFecha,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6, offset: const Offset(0, 3))],
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today, color: color),
                  const SizedBox(width: 12),
                  Text('Fecha: $_fechaStr',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: color, fontSize: 15)),
                  const Spacer(),
                  Icon(Icons.arrow_drop_down, color: color),
                ]),
              ),
            ),
          ),

          // Horarios disponibles
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.fs.reservasPorEspacio(
                  widget.espacio['nombre'] as String, _fechaStr),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final horasOcupadas = (snap.data?.docs ?? [])
                    .map((d) => (d.data() as Map)['hora'] as String)
                    .toSet();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        _Leyenda(color: Colors.green.shade100, label: 'Disponible'),
                        const SizedBox(width: 16),
                        _Leyenda(color: Colors.red.shade100, label: 'Ocupado'),
                        const SizedBox(width: 16),
                        _Leyenda(color: color.withOpacity(0.3), label: 'Seleccionado'),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1.6),
                        itemCount: widget.horas.length,
                        itemBuilder: (_, i) {
                          final hora = widget.horas[i];
                          final ocupado = horasOcupadas.contains(hora);
                          final seleccionado = _horaSeleccionada == hora;

                          Color bgColor;
                          Color textColor;
                          if (ocupado) {
                            bgColor = Colors.red.shade100;
                            textColor = Colors.red.shade700;
                          } else if (seleccionado) {
                            bgColor = color.withOpacity(0.8);
                            textColor = Colors.white;
                          } else {
                            bgColor = Colors.green.shade50;
                            textColor = Colors.green.shade700;
                          }

                          return GestureDetector(
                            onTap: ocupado
                                ? null
                                : () => setState(
                                    () => _horaSeleccionada =
                                        seleccionado ? null : hora),
                            child: Container(
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: seleccionado ? color : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(hora,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: textColor)),
                                  if (ocupado)
                                    Icon(Icons.lock, size: 10,
                                        color: Colors.red.shade400),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Botón confirmar
          StreamBuilder<QuerySnapshot>(
            stream: widget.fs.reservasPorEspacio(
                widget.espacio['nombre'] as String, _fechaStr),
            builder: (_, snap) {
              final horasOcupadas = (snap.data?.docs ?? [])
                  .map((d) => (d.data() as Map)['hora'] as String)
                  .toSet();
              return Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _horaSeleccionada == null
                        ? null
                        : () => _reservar(horasOcupadas),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _horaSeleccionada == null
                          ? 'Selecciona una hora'
                          : 'Reservar $_fechaStr a las $_horaSeleccionada',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  final Color color;
  final String label;
  const _Leyenda({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 14, height: 14,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }
}
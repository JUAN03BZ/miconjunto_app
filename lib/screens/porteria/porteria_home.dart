import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class PorteriaHome extends StatefulWidget {
  const PorteriaHome({super.key});

  @override
  State<PorteriaHome> createState() => _PorteriaHomeState();
}

class _PorteriaHomeState extends State<PorteriaHome> {
  final List<Map<String, String>> _visitas = [
    {'nombre': 'Juan Pérez', 'apto': '101', 'hora': '09:30', 'estado': 'Autorizada'},
    {'nombre': 'María López', 'apto': '205', 'hora': '11:00', 'estado': 'Pendiente'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Portería', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF607D8B),
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
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF607D8B),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Control de Acceso', style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Visitas del día', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatCard('Visitas hoy', '${_visitas.length}',
                        Icons.people, Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard('Pendientes',
                        '${_visitas.where((v) => v['estado'] == 'Pendiente').length}',
                        Icons.hourglass_empty, Colors.orange)),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Visitas registradas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._visitas.map((v) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: v['estado'] == 'Autorizada'
                        ? Colors.green : Colors.orange,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(v['nombre']!,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Apto ${v['apto']} · ${v['hora']}'),
                    trailing: Chip(
                      label: Text(v['estado']!,
                        style: const TextStyle(fontSize: 12, color: Colors.white)),
                      backgroundColor: v['estado'] == 'Autorizada'
                        ? Colors.green : Colors.orange,
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarRegistroVisita(context),
        backgroundColor: const Color(0xFF607D8B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Registrar visita'),
      ),
    );
  }

  void _mostrarRegistroVisita(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final aptoCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Nueva Visita', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(controller: nombreCtrl,
            decoration: InputDecoration(labelText: 'Nombre del visitante',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 12),
          TextField(controller: aptoCtrl,
            decoration: InputDecoration(labelText: 'Apartamento a visitar',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF607D8B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () {
                if (nombreCtrl.text.isNotEmpty && aptoCtrl.text.isNotEmpty) {
                  setState(() {
                    _visitas.add({
                      'nombre': nombreCtrl.text,
                      'apto': aptoCtrl.text,
                      'hora': TimeOfDay.now().format(context),
                      'estado': 'Pendiente',
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Registrar'),
            )),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String titulo, valor;
  final IconData icono;
  final Color color;
  const _StatCard(this.titulo, this.valor, this.icono, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
          blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Icon(icono, color: color, size: 32),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(valor, style: TextStyle(fontSize: 24,
            fontWeight: FontWeight.bold, color: color)),
          Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ]),
    );
  }
}
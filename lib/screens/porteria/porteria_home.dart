import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../login_screen.dart';

class PorteriaHome extends StatefulWidget {
  const PorteriaHome({super.key});
  @override
  State<PorteriaHome> createState() => _PorteriaHomeState();
}

class _PorteriaHomeState extends State<PorteriaHome>
    with SingleTickerProviderStateMixin {
  final _fs = FirestoreService();
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String _formatFecha(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

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
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Visitas'),
            Tab(icon: Icon(Icons.inbox), text: 'Casillero'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _VistaVisitas(fs: _fs, formatFecha: _formatFecha),
          _VistaCasillero(fs: _fs, formatFecha: _formatFecha),
        ],
      ),
    );
  }
}

// ── TAB VISITAS ────────────────────────────────────────────
class _VistaVisitas extends StatelessWidget {
  final FirestoreService fs;
  final String Function(Timestamp?) formatFecha;
  const _VistaVisitas({required this.fs, required this.formatFecha});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: fs.todasLasVisitas(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          final hoy = DateTime.now();
          final visitasHoy = docs.where((d) {
            final ts = (d.data() as Map)['fecha'] as Timestamp?;
            if (ts == null) return false;
            final f = ts.toDate();
            return f.day == hoy.day && f.month == hoy.month && f.year == hoy.year;
          }).toList();
          final pendientes =
              visitasHoy.where((d) => (d.data() as Map)['estado'] == 'Registrada').length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Expanded(child: _StatCard('Hoy', '${visitasHoy.length}',
                    Icons.today, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard('Pendientes', '$pendientes',
                    Icons.hourglass_empty, Colors.orange)),
              ]),
              const SizedBox(height: 20),
              const Text('Visitas registradas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (docs.isEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No hay visitas aún',
                      style: TextStyle(color: Colors.grey)),
                )),
              ...docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final estado = d['estado'] ?? 'Registrada';
                final autorizado = estado == 'Autorizada';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: autorizado ? Colors.green : Colors.orange,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(d['nombre'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        'Apto: ${d['apartamento'] ?? d['apto'] ?? '-'} · ${formatFecha(d['fecha'] as Timestamp?)}'),
                    trailing: autorizado
                        ? const Chip(
                            label: Text('Autorizada',
                                style: TextStyle(color: Colors.white, fontSize: 11)),
                            backgroundColor: Colors.green)
                        : ElevatedButton(
                            onPressed: () async {
                              await fs.actualizarEstadoVisita(doc.id, 'Autorizada');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        backgroundColor: Colors.green,
                                        content: Text('✅ Visita autorizada')));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF607D8B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Autorizar',
                                style: TextStyle(fontSize: 12)),
                          ),
                  ),
                );
              }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarRegistro(context),
        backgroundColor: const Color(0xFF607D8B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva visita'),
      ),
    );
  }

  void _mostrarRegistro(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final aptoCtrl = TextEditingController();
    final docCtrl = TextEditingController();
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
            const Text('Registrar Visita',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _campo(nombreCtrl, 'Nombre del visitante', Icons.person),
            const SizedBox(height: 12),
            _campo(aptoCtrl, 'Apartamento', Icons.apartment),
            const SizedBox(height: 12),
            _campo(docCtrl, 'Documento (opcional)', Icons.badge),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF607D8B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: guardando
                    ? null
                    : () async {
                        if (nombreCtrl.text.isEmpty || aptoCtrl.text.isEmpty) return;
                        setModal(() => guardando = true);
                        await fs.registrarVisita({
                          'nombre': nombreCtrl.text.trim(),
                          'apartamento': aptoCtrl.text.trim(),
                          'documento': docCtrl.text.trim(),
                          'registradoPor': 'porteria',
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text('✅ Visita registrada')));
                        }
                      },
                child: guardando
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Registrar',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _campo(TextEditingController c, String label, IconData icon) =>
      TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}

// ── TAB CASILLERO ──────────────────────────────────────────
class _VistaCasillero extends StatelessWidget {
  final FirestoreService fs;
  final String Function(Timestamp?) formatFecha;
  const _VistaCasillero({required this.fs, required this.formatFecha});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: fs.todosCasilleros(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          final sinRecoger =
              docs.where((d) => (d.data() as Map)['estado'] == 'Sin recoger').length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Expanded(child: _StatCard('Sin recoger', '$sinRecoger',
                    Icons.inbox, Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard('Total', '${docs.length}',
                    Icons.inventory_2, Colors.blueGrey)),
              ]),
              const SizedBox(height: 20),
              const Text('Paquetes registrados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (docs.isEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No hay paquetes registrados',
                      style: TextStyle(color: Colors.grey)),
                )),
              ...docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final sinRec = d['estado'] == 'Sin recoger';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          sinRec ? const Color(0xFFFF9800) : Colors.grey,
                      child: const Icon(Icons.inventory_2, color: Colors.white),
                    ),
                    title: Text(d['remitente'] ?? 'Paquete',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${d['email'] ?? ''}\n${d['descripcion'] ?? ''} · ${formatFecha(d['fechaLlegada'] as Timestamp?)}'),
                    isThreeLine: true,
                    trailing: sinRec
                        ? const Chip(
                            label: Text('Sin recoger',
                                style: TextStyle(color: Colors.white, fontSize: 10)),
                            backgroundColor: Color(0xFFFF9800))
                        : const Chip(
                            label: Text('Recogido',
                                style: TextStyle(color: Colors.white, fontSize: 10)),
                            backgroundColor: Colors.grey),
                  ),
                );
              }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarRegistroPaquete(context),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo paquete'),
      ),
    );
  }

  void _mostrarRegistroPaquete(BuildContext context) {
    final emailCtrl = TextEditingController();
    final remitenteCtrl = TextEditingController();
    final descCtrl = TextEditingController();
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
            _campo(emailCtrl, 'Correo del residente', Icons.email),
            const SizedBox(height: 12),
            _campo(remitenteCtrl, 'Remitente (ej: Amazon)', Icons.store),
            const SizedBox(height: 12),
            _campo(descCtrl, 'Descripción', Icons.inventory_2),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: guardando
                    ? null
                    : () async {
                        if (emailCtrl.text.isEmpty || remitenteCtrl.text.isEmpty) return;
                        setModal(() => guardando = true);
                        await fs.registrarPaquete({
                          'email': emailCtrl.text.trim().toLowerCase(),
                          'remitente': remitenteCtrl.text.trim(),
                          'descripcion': descCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text('✅ Paquete registrado')));
                        }
                      },
                child: guardando
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Registrar',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _campo(TextEditingController c, String label, IconData icon) =>
      TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Icon(icono, color: color, size: 32),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(valor,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(titulo,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ]),
    );
  }
}
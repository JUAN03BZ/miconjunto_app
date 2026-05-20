import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../login_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome>
    with SingleTickerProviderStateMixin {
  final _fs = FirestoreService();
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
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
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Administrador',
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
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.campaign), text: 'Comunicados'),
            Tab(icon: Icon(Icons.report_problem), text: 'PQRS'),
            Tab(icon: Icon(Icons.event_available), text: 'Reservas'),
            Tab(icon: Icon(Icons.inbox), text: 'Casillero'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _TabComunicados(fs: _fs),
          _TabPqrs(fs: _fs, formatFecha: _formatFecha),
          _TabReservas(fs: _fs, formatFecha: _formatFecha),
          _TabCasillero(fs: _fs, formatFecha: _formatFecha),
        ],
      ),
    );
  }
}

// ── TAB COMUNICADOS ────────────────────────────────────────
class _TabComunicados extends StatelessWidget {
  final FirestoreService fs;
  const _TabComunicados({required this.fs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: fs.comunicados(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (docs.isEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No hay comunicados publicados',
                      style: TextStyle(color: Colors.grey)),
                )),
              ...docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final ts = d['fecha'] as Timestamp?;
                final fecha = ts != null
                    ? '${ts.toDate().day.toString().padLeft(2,'0')}/${ts.toDate().month.toString().padLeft(2,'0')}/${ts.toDate().year}'
                    : '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        const Icon(Icons.campaign, color: Color(0xFF9C27B0)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(d['titulo'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15))),
                        Text(fecha,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ]),
                      const SizedBox(height: 8),
                      Text(d['contenido'] ?? '',
                          style: const TextStyle(fontSize: 14)),
                    ]),
                  ),
                );
              }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarForm(context),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo comunicado'),
      ),
    );
  }

  void _mostrarForm(BuildContext context) {
    final tituloCtrl = TextEditingController();
    final contenidoCtrl = TextEditingController();
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contenidoCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                  labelText: 'Contenido',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: guardando
                    ? null
                    : () async {
                        if (tituloCtrl.text.isEmpty || contenidoCtrl.text.isEmpty) return;
                        setModal(() => guardando = true);
                        await fs.publicarComunicado({
                          'titulo': tituloCtrl.text.trim(),
                          'contenido': contenidoCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text('✅ Comunicado publicado')));
                        }
                      },
                child: guardando
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Publicar',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── TAB PQRS ───────────────────────────────────────────────
class _TabPqrs extends StatelessWidget {
  final FirestoreService fs;
  final String Function(Timestamp?) formatFecha;
  const _TabPqrs({required this.fs, required this.formatFecha});

  Color _colorTipo(String tipo) {
    switch (tipo) {
      case 'Queja': return Colors.red;
      case 'Reclamo': return Colors.orange;
      case 'Sugerencia': return Colors.blue;
      default: return const Color(0xFF795548);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: fs.todasLasPqrs(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
              child: Text('No hay PQRS recibidas',
                  style: TextStyle(color: Colors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final d = doc.data() as Map<String, dynamic>;
            final resuelta = d['estado'] == 'Resuelta';
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: _colorTipo(d['tipo'] ?? ''),
                  child: const Icon(Icons.report, color: Colors.white, size: 18),
                ),
                title: Text(d['asunto'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    '${d['tipo'] ?? ''} · ${d['email'] ?? ''} · ${formatFecha(d['fecha'] as Timestamp?)}'),
                trailing: Chip(
                  label: Text(d['estado'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                  backgroundColor: resuelta ? Colors.green : Colors.orange,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Descripción:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(d['descripcion'] ?? ''),
                        if (d['respuesta'] != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Respuesta del administrador:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                                const SizedBox(height: 4),
                                Text(d['respuesta']),
                              ],
                            ),
                          ),
                        ],
                        if (!resuelta) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _mostrarRespuesta(context, doc.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A3C5E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.reply, size: 18),
                            label: const Text('Responder'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarRespuesta(BuildContext context, String docId) {
    final ctrl = TextEditingController();
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
            const Text('Responder PQRS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: InputDecoration(
                  labelText: 'Escribe tu respuesta',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3C5E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: guardando
                    ? null
                    : () async {
                        if (ctrl.text.isEmpty) return;
                        setModal(() => guardando = true);
                        await fs.responderPqrs(docId, ctrl.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text('✅ Respuesta enviada')));
                        }
                      },
                child: guardando
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Enviar respuesta',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── TAB RESERVAS ───────────────────────────────────────────
class _TabReservas extends StatelessWidget {
  final FirestoreService fs;
  final String Function(Timestamp?) formatFecha;
  const _TabReservas({required this.fs, required this.formatFecha});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: fs.todasLasReservas(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        final activas =
            docs.where((d) => (d.data() as Map)['estado'] == 'Confirmada').length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Expanded(child: _StatCard2('Activas', '$activas',
                  Icons.event_available, Colors.teal)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard2('Total', '${docs.length}',
                  Icons.calendar_month, Colors.blueGrey)),
            ]),
            const SizedBox(height: 20),
            const Text('Todas las reservas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (docs.isEmpty)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No hay reservas registradas',
                    style: TextStyle(color: Colors.grey)),
              )),
            ...docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final confirmada = d['estado'] == 'Confirmada';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        confirmada ? const Color(0xFF009688) : Colors.grey,
                    child: const Icon(Icons.event_available, color: Colors.white),
                  ),
                  title: Text(d['espacio'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${d['fecha'] ?? ''} · ${d['hora'] ?? ''}\n${d['email'] ?? ''}'),
                  isThreeLine: true,
                  trailing: confirmada
                      ? ElevatedButton(
                          onPressed: () async {
                            await fs.cancelarReserva(doc.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Reserva cancelada')));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancelar',
                              style: TextStyle(fontSize: 12)))
                      : const Chip(
                          label: Text('Cancelada',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11)),
                          backgroundColor: Colors.grey),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ── TAB CASILLERO (ADMIN) ──────────────────────────────────
class _TabCasillero extends StatelessWidget {
  final FirestoreService fs;
  final String Function(Timestamp?) formatFecha;
  const _TabCasillero({required this.fs, required this.formatFecha});

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
                Expanded(child: _StatCard2('Sin recoger', '$sinRecoger',
                    Icons.inbox, Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard2('Total', '${docs.length}',
                    Icons.inventory_2, Colors.blueGrey)),
              ]),
              const SizedBox(height: 20),
              const Text('Paquetes en casillero',
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
                      child:
                          const Icon(Icons.inventory_2, color: Colors.white),
                    ),
                    title: Text(d['remitente'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${d['email'] ?? ''}\n${d['descripcion'] ?? ''} · ${formatFecha(d['fechaLlegada'] as Timestamp?)}'),
                    isThreeLine: true,
                    trailing: sinRec
                        ? const Chip(
                            label: Text('Sin recoger',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10)),
                            backgroundColor: Color(0xFFFF9800))
                        : const Chip(
                            label: Text('Recogido',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10)),
                            backgroundColor: Colors.grey),
                  ),
                );
              }),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarRegistro(context),
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo paquete'),
      ),
    );
  }

  void _mostrarRegistro(BuildContext context) {
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
            _campo(remitenteCtrl, 'Remitente', Icons.store),
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
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}

class _StatCard2 extends StatelessWidget {
  final String titulo, valor;
  final IconData icono;
  final Color color;
  const _StatCard2(this.titulo, this.valor, this.icono, this.color);

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
        Icon(icono, color: color, size: 28),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(valor,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(titulo,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ]),
    );
  }
}
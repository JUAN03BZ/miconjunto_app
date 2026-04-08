import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class PagosScreen extends StatefulWidget {
  const PagosScreen({super.key});
  @override
  State<PagosScreen> createState() => _PagosScreenState();
}

class _PagosScreenState extends State<PagosScreen> {
  final _fs = FirestoreService();
  bool _iniciando = true;

  @override
  void initState() {
    super.initState();
    _fs.inicializarPagosResidente().then((_) {
      if (mounted) setState(() => _iniciando = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagos'),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
      ),
      body: _iniciando
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _fs.misPagos(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                final pendientes =
                    docs.where((d) => (d.data() as Map)['estado'] == 'Pendiente').length;
                final pagados = docs.length - pendientes;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(children: [
                      Expanded(child: _ResumenCard('Pendientes',
                          '$pendientes', Colors.orange, Icons.pending)),
                      const SizedBox(width: 12),
                      Expanded(child: _ResumenCard('Al día',
                          '$pagados', Colors.green, Icons.check_circle)),
                    ]),
                    const SizedBox(height: 20),
                    const Text('Estado de pagos',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final esPendiente = d['estado'] == 'Pendiente';
                      final ts = d['fechaVencimiento'] as Timestamp?;
                      final fecha = ts != null
                          ? '${ts.toDate().day.toString().padLeft(2,'0')}/${ts.toDate().month.toString().padLeft(2,'0')}/${ts.toDate().year}'
                          : '-';
                      final monto = d['monto'] ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                esPendiente ? Colors.orange : Colors.green,
                            child: Icon(
                                esPendiente ? Icons.pending : Icons.check,
                                color: Colors.white)),
                          title: Text(d['concepto'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '\$${_formatMonto(monto)} · Vence: $fecha'),
                          trailing: esPendiente
                              ? ElevatedButton(
                                  onPressed: () async {
                                    await _fs.marcarPagado(doc.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            backgroundColor: Colors.green,
                                            content: Text('✅ Pago registrado')));
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00BCD4),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8))),
                                  child: const Text('Pagar',
                                      style: TextStyle(fontSize: 12)))
                              : const Chip(
                                  label: Text('Al día',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 11)),
                                  backgroundColor: Colors.green),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }

  String _formatMonto(dynamic monto) {
    final n = (monto as num).toInt();
    return n.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }
}

class _ResumenCard extends StatelessWidget {
  final String titulo, valor;
  final Color color;
  final IconData icono;
  const _ResumenCard(this.titulo, this.valor, this.color, this.icono);
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
        Icon(icono, color: color, size: 28),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(valor, style: TextStyle(fontSize: 24,
              fontWeight: FontWeight.bold, color: color)),
          Text(titulo,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
      ]),
    );
  }
}
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';
import 'visitas_screen.dart';
import 'pagos_screen.dart';
import 'casillero_screen.dart';
import 'pqrs_screen.dart';
import 'reservas_screen.dart';
import 'comunicados_screen.dart';

class ResidenteHome extends StatelessWidget {
  final String email;
  const ResidenteHome({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final opciones = [
      {'icon': Icons.phone, 'label': 'Llamar Portería',
       'color': const Color(0xFF4CAF50), 'screen': null, 'accion': 'llamar'},
      {'icon': Icons.warning_amber_rounded, 'label': 'Botón de Pánico',
       'color': const Color(0xFFF44336), 'screen': null, 'accion': 'panico'},
      {'icon': Icons.people_outline, 'label': 'Registrar Visita',
       'color': const Color(0xFF2196F3), 'screen': const VisitasScreen()},
      {'icon': Icons.campaign_outlined, 'label': 'Comunicados',
       'color': const Color(0xFF9C27B0), 'screen': const ComunicadosScreen()},
      {'icon': Icons.payment, 'label': 'Pagos',
       'color': const Color(0xFF00BCD4), 'screen': const PagosScreen()},
      {'icon': Icons.inbox_outlined, 'label': 'Casillero',
       'color': const Color(0xFFFF9800), 'screen': const CasilleroScreen()},
      {'icon': Icons.report_outlined, 'label': 'PQRS',
       'color': const Color(0xFF795548), 'screen': const PqrsScreen()},
      {'icon': Icons.event_available, 'label': 'Reservas',
       'color': const Color(0xFF009688), 'screen': const ReservasScreen()},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Mi Conjunto', style: TextStyle(fontWeight: FontWeight.bold)),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A3C5E), Color(0xFF2E6DA4)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    radius: 30,
                    child: Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bienvenido',
                          style: TextStyle(color: Colors.white70)),
                        Text(email,
                          style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis),
                        const Text('Residente · Conjunto Residencial',
                          style: TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Servicios disponibles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: Color(0xFF1A3C5E))),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12,
                mainAxisSpacing: 12, childAspectRatio: 1.1),
              itemCount: opciones.length,
              itemBuilder: (_, i) {
                final op = opciones[i];
                return GestureDetector(
                  onTap: () {
                    if (op['accion'] == 'panico') {
                      showDialog(context: context, builder: (_) => AlertDialog(
                        title: const Text('🚨 Alerta enviada'),
                        content: const Text('Se notificó a portería tu alerta de pánico.'),
                        actions: [TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'))],
                      ));
                    } else if (op['accion'] == 'llamar') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Llamando a portería...')));
                    } else if (op['screen'] != null) {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => op['screen'] as Widget));
                    }
                  },
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
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (op['color'] as Color).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(op['icon'] as IconData,
                            color: op['color'] as Color, size: 32),
                        ),
                        const SizedBox(height: 12),
                        Text(op['label'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
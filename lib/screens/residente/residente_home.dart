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
      {'icon': Icons.phone, 'label': 'Llamar\nPortería',
       'color': const Color(0xFF2E7D32), 'screen': null, 'accion': 'llamar'},
      {'icon': Icons.warning_amber_rounded, 'label': 'Botón\nde Pánico',
       'color': const Color(0xFFD32F2F), 'screen': null, 'accion': 'panico'},
      {'icon': Icons.people_outline, 'label': 'Registrar\nVisita',
       'color': const Color(0xFF1A3C5E), 'screen': const VisitasScreen(), 'accion': ''},
      {'icon': Icons.campaign_outlined, 'label': 'Comunicados',
       'color': const Color(0xFF6A1B9A), 'screen': const ComunicadosScreen(), 'accion': ''},
      {'icon': Icons.payment, 'label': 'Pagos',
       'color': const Color(0xFF00838F), 'screen': const PagosScreen(), 'accion': ''},
      {'icon': Icons.inbox_outlined, 'label': 'Casillero',
       'color': const Color(0xFFE65100), 'screen': const CasilleroScreen(), 'accion': ''},
      {'icon': Icons.report_outlined, 'label': 'PQRS',
       'color': const Color(0xFF4E342E), 'screen': const PqrsScreen(), 'accion': ''},
      {'icon': Icons.event_available, 'label': 'Reservas',
       'color': const Color(0xFF388E3C), 'screen': const ReservasScreen(), 'accion': ''},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(children: [
          Image.asset('assets/images/logo.png',
              height: 32, width: 32, fit: BoxFit.contain),
          const SizedBox(width: 10),
          const Text('Mi Conjunto',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        backgroundColor: const Color(0xFF1A3C5E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()));
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
            // ── Banner bienvenida ─────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A3C5E), Color(0xFF2E6DA4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A3C5E).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Row(children: [
                // Avatar con borde verde
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF4CAF50), width: 2.5),
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Colors.white24,
                    radius: 28,
                    child: Icon(Icons.person,
                        color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bienvenido',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      Text(email,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50)
                              .withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF4CAF50)
                                  .withOpacity(0.5)),
                        ),
                        child: const Text('Residente',
                            style: TextStyle(
                                color: Color(0xFF81C784),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Título sección ────────────────────────────
            Row(children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Servicios disponibles',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3C5E))),
            ]),
            const SizedBox(height: 14),

            // ── Grid de opciones ──────────────────────────
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: opciones.length,
              itemBuilder: (_, i) {
                final op = opciones[i];
                final color = op['color'] as Color;
                return GestureDetector(
                  onTap: () {
                    if (op['accion'] == 'panico') {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(16)),
                          title: const Text('🚨 Alerta enviada'),
                          content: const Text(
                              'Se notificó a portería tu alerta de pánico.'),
                          actions: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF1A3C5E),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () =>
                                  Navigator.pop(context),
                              child: const Text('OK'),
                            )
                          ],
                        ),
                      );
                    } else if (op['accion'] == 'llamar') {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Llamando a portería...')));
                    } else if (op['screen'] != null) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  op['screen'] as Widget));
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: color.withOpacity(0.2),
                                width: 1.5),
                          ),
                          child: Icon(op['icon'] as IconData,
                              color: color, size: 30),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          op['label'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
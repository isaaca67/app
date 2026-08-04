import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16161D),
        title: const Text(
          'Dashboard COV',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // 1. Menú Lateral (Drawer)
      drawer: Drawer(
        backgroundColor: const Color(0xFF16161D),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF09090B)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.account_circle, color: Colors.white, size: 48),
                  SizedBox(height: 10),
                  Text(
                    'Administrador',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),
              title: const Text(
                'Inicio',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context), // Cierra el menú
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text(
                'Configuración',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {}, // Aquí iría la pantalla de configuración
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(context); // Cierra el menú
                Navigator.pop(context); // Regresa al Login
              },
            ),
          ],
        ),
      ),

      // 2. Contenido Principal con Tarjetas Responsivas
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen General',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // GridView Responsivo
            Expanded(
              child: GridView.extent(
                maxCrossAxisExtent:
                    250, // Ancho máximo por tarjeta. Cambia el # de columnas automáticamente.
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildSummaryCard(
                    'Ventas Hoy',
                    '\$1,250',
                    Icons.attach_money,
                    Colors.green,
                  ),
                  _buildSummaryCard(
                    'Operaciones',
                    '42',
                    Icons.sync,
                    Colors.blue,
                  ),
                  _buildSummaryCard(
                    'Usuarios',
                    '128',
                    Icons.people,
                    Colors.orange,
                  ),
                  _buildSummaryCard('Alertas', '3', Icons.warning, Colors.red),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Función para dibujar las tarjetas y no repetir código
  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16161D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

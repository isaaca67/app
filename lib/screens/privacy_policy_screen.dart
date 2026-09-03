import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:stitch_cov_dark_mobile_login/core/theme/app_theme.dart';

/// Políticas de Privacidad y Términos de Uso de COV.
///
/// Pantalla 100% informativa: no requiere red ni permisos.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidad y Términos'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: EdgeInsets.all(kIsWeb ? 32 : 20),
            children: [
              _HeaderCard(isDark: isDark),
              const SizedBox(height: 16),
              const _PolicySection(
                icon: Icons.person_outline,
                title: '1. Datos que recopilamos',
                body: 'COV almacena únicamente los datos necesarios para operar tu '
                    'negocio: tu nombre, correo electrónico y foto de perfil '
                    '(provenientes de tu cuenta), tu catálogo de productos y el '
                    'historial de ventas que registras. No recopilamos ubicación, '
                    'contactos ni ningún otro dato de tu dispositivo.',
              ),
              const _PolicySection(
                icon: Icons.qr_code_scanner,
                title: '2. Cámara y escáner de códigos',
                body: 'La cámara se utiliza exclusivamente para escanear códigos '
                    'de barras y QR de tus productos en el punto de venta. Las '
                    'imágenes de la cámara se procesan en tu dispositivo y no se '
                    'suben, almacenan ni comparten con terceros.',
              ),
              const _PolicySection(
                icon: Icons.cloud_outlined,
                title: '3. Dónde se guardan tus datos',
                body: 'Tus datos se almacenan de forma segura en Firebase (Google '
                    'Cloud), con cifrado en tránsito y en reposo. Cada cuenta solo '
                    'puede leer y escribir sus propios datos: las reglas de '
                    'seguridad aíslan la información por usuario. Nunca vendemos '
                    'ni compartimos tus datos con fines publicitarios.',
              ),
              const _PolicySection(
                icon: Icons.fingerprint,
                title: '4. Autenticación biométrica',
                body: 'Si activas la huella digital o el reconocimiento facial, la '
                    'verificación ocurre íntegramente en tu dispositivo mediante '
                    'el sistema operativo. COV nunca recibe ni almacena tus datos '
                    'biométricos.',
              ),
              const _PolicySection(
                icon: Icons.notifications_outlined,
                title: '5. Notificaciones',
                body: 'Las notificaciones (por ejemplo, alertas de stock bajo) se '
                    'gestionan en tu dispositivo. Puedes activarlas o '
                    'desactivarlas en cualquier momento desde Ajustes > '
                    'Notificaciones, y el sistema te pedirá permiso antes de '
                    'enviar la primera.',
              ),
              const _PolicySection(
                icon: Icons.security_outlined,
                title: '6. Seguridad de tu cuenta',
                body: 'Protege tu cuenta con una contraseña segura y no la '
                    'compartas. Si cambias tu contraseña, es posible que debas '
                    'cerrar sesión y volver a entrar (medida de seguridad de '
                    'Firebase). Puedes cerrar sesión cuando quieras desde '
                    'Ajustes > Zona de peligro.',
              ),
              const _PolicySection(
                icon: Icons.manage_accounts_outlined,
                title: '7. Tus derechos',
                body: 'Puedes consultar, corregir o eliminar tus datos en '
                    'cualquier momento: edita tu perfil desde la app o solicita '
                    'la eliminación de tu cuenta escribiéndonos. Al eliminar tu '
                    'cuenta se borran tu perfil, tu catálogo y tu historial de '
                    'ventas asociados.',
              ),
              const _PolicySection(
                icon: Icons.gavel_outlined,
                title: '8. Uso aceptable',
                body: 'COV es una herramienta para la gestión de tu propio '
                    'negocio. Te comprometes a usarla de forma lícita, a no '
                    'intentar acceder a datos de otros usuarios y a no realizar '
                    'ingeniería inversa con fines maliciosos.',
              ),
              const _PolicySection(
                icon: Icons.update_outlined,
                title: '9. Cambios en estas políticas',
                body: 'Podemos actualizar este documento para reflejar mejoras '
                    'del servicio o requisitos legales. Te avisaremos desde la '
                    'sección de actualizaciones cuando haya cambios relevantes. '
                    'Última actualización: septiembre de 2026 · v1.0.0.',
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'COV · Control de Ventas e Inventario',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.privacy_tip_outlined, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            'Tu información está protegida',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transparencia total sobre qué datos usa COV y para qué.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? AppTheme.darkSurface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

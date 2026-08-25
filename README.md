# COV — Control de Ventas e Inventario

Aplicación multiplataforma (Web y Android) para emprendedores. Controla tu
catálogo, registra ventas con descuento automático de stock y consulta tu
dashboard en tiempo real.

- **Autenticación**: Firebase Auth (correo/contraseña y Google).
- **Datos**: Cloud Firestore, con reglas de seguridad por usuario
  (`users/{uid}/productos` y `users/{uid}/ventas`).
- **Identidad visual**: negro puro `#000000`, blanco y acento rosa `#FF7A8A`.

## Arquitectura

```text
lib/
  core/
    config/                Configuración central (variables de entorno)
    constants/             Constantes y strings
    di/                    ServiceLocator (inyección de dependencias)
    theme/                 Temas claro/oscuro (identidad COV)
  features/
    auth/                  Login y registro
    dashboard/             Dashboard (total del día + alertas de stock)
    products/              Catálogo de productos (CRUD)
    sales/                 Registro de ventas
  models/                  Modelos de datos (Product, Sale)
  services/                Servicios de Firebase (auth, productos, ventas)
  screens/                 Pantallas raíz (home, login, splash)
  main.dart                Punto de entrada
  firebase_options.dart    Config generada por FlutterFire (claves públicas)
```

## Variables de entorno

Todas las conexiones externas se pueden sobreescribir en tiempo de compilación
con `--dart-define` (no hay configuración fija apuntando a localhost). Los
valores por defecto son las **claves públicas de cliente** de Firebase, que no
son secretos; la seguridad real la dan las reglas de Firestore y App Check.

| Variable | Descripción | Default |
| --- | --- | --- |
| `APP_ENV` | `development`, `staging` o `production` | `development` |
| `FIREBASE_PROJECT_ID` | ID del proyecto Firebase | `cov-app-71e00` |
| `FIREBASE_WEB_API_KEY` | API key Web | (pública, del repo) |
| `FIREBASE_WEB_APP_ID` | App ID Web | (pública, del repo) |
| `FIREBASE_WEB_AUTH_DOMAIN` | Auth domain Web | (pública, del repo) |
| `FIREBASE_WEB_STORAGE_BUCKET` | Storage bucket Web | (pública, del repo) |
| `FIREBASE_WEB_SENDER_ID` | Sender ID Web | (pública, del repo) |
| `FIREBASE_WEB_MEASUREMENT_ID` | Measurement ID Web | (pública, del repo) |
| `FIREBASE_ANDROID_API_KEY` | API key Android | (pública, del repo) |
| `FIREBASE_ANDROID_APP_ID` | App ID Android | (pública, del repo) |
| `FIREBASE_ANDROID_SENDER_ID` | Sender ID Android | (pública, del repo) |
| `GOOGLE_CLIENT_ID` | OAuth Client ID para Web | (del repo) |

Ejemplo local:

```bash
flutter run -d chrome \
  --dart-define=APP_ENV=development \
  --dart-define=GOOGLE_CLIENT_ID=...
```

> En Android el Client ID de Google se lee automáticamente de
> `google-services.json`, por eso no se pasa por `--dart-define`.

## Compilar para producción

### Web

```bash
flutter build web --release --dart-define=APP_ENV=production
```

El resultado queda en `build/web/`, listo para Firebase Hosting (configuración
en `firebase.json` y `.firebaserc`).

### Android (APK)

```bash
cp android/key.properties.example android/key.properties
# ... rellena tus valores de firma (keystore en android/app/)
flutter build apk --release --dart-define=APP_ENV=production
```

## Despliegue

### APK en la nube (GitHub Actions)

El workflow `.github/workflows/build-apk.yml` compila el APK de release
firmado. Activa al crear un tag `v*` o manualmente (workflow_dispatch).

Configura estos **secretos** en el repositorio:

| Secreto | Descripción |
| --- | --- |
| `KEYSTORE_BASE64` | El keystore `.jks` codificado en base64 (`base64 -w0 cov-upload.jks`) |
| `KEY_ALIAS` | Alias del keystore |
| `KEY_PASSWORD` | Contraseña de la llave |
| `KEYSTORE_PASSWORD` | Contraseña del keystore |

### Web en Firebase Hosting (GitHub Actions)

El workflow `.github/workflows/deploy-web.yml` publica `build/web` en el canal
`live` de Firebase Hosting al hacer push a `main`.

- Crea una cuenta de servicio en Firebase/Google Cloud con el rol de **Firebase
  Hosting Admin**, descarga su JSON, y súbelo (codificado en base64 o como
  secreto multilínea) con el nombre
  `FIREBASE_SERVICE_ACCOUNT_COV_APP_71E00`.

### Requisitos previos de Google OAuth (Web en producción)

Para que el inicio de sesión con Google funcione en producción, agrega en
**Firebase Console → Authentication → Configuración → Dominios autorizados** y
en **Google Cloud Console → APIs y servicios → Credenciales → Cliente OAuth**
los orígenes/dominios autorizados de tu dominio de producción (ej.
`https://micompany.com`), además de `localhost`.

## Pruebas

```bash
flutter analyze
flutter test
```

## Estructura de reglas de Firestore

Ver `firestore.rules`. Cada usuario solo lee/escribe en `users/{uid}` y sus
subcolecciones `productos` y `ventas`.
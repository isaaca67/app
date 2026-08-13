# COV App

Aplicación Flutter para la gestión de tareas, con autenticación y datos en Firebase.

## Estructura

```text
lib/
  screens/                 Pantallas de la aplicación
  main.dart                Punto de entrada y tema global
  firebase_options.dart    Configuración generada de Firebase
assets/
  images/                  Imágenes que usa la aplicación
docs/
  design-references/       Diseños de referencia exportados desde Stitch
test/                      Pruebas automatizadas
android/                   Configuración de Android
web/                       Configuración de Web
```

## Ejecutar

```bash
flutter pub get
flutter run
```

La carpeta `docs/design-references/` es documentación visual: no forma parte de la aplicación compilada.

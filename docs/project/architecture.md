# Arquitectura técnica

```text
Flutter (Android / Web)
  ├── Pantallas: acceso, registro y tareas
  ├── Servicios: AuthService y TaskService
  └── Modelos: Task
          │
          ├── Firebase Authentication
          └── Cloud Firestore
                users/{uid}/tareas/{taskId}
```

Flutter se eligió por su salida multiplataforma. Firebase Authentication gestiona la identidad y Cloud Firestore persiste las tareas por usuario en tiempo real. Las reglas de `firestore.rules` limitan cada documento a su propietario.

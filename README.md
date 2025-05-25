# TaskVoice

Un proyecto Flutter para la gestión de tareas con capacidades de voz e integración con Firebase.

## Descripción

TaskVoice es una aplicación móvil construida con Flutter que permite a los usuarios gestionar sus tareas. Incluye funcionalidades de autenticación de usuario (inicio de sesión y registro) y se integra con Firebase para los servicios de backend. El proyecto tiene como objetivo incorporar comandos de voz para la creación y gestión de tareas.

## Características

- Autenticación de Usuario (Inicio de Sesión y Registro)
- Gestión de Tareas
- Integración con Firebase
- (Planificado) Integración de Comandos de Voz

## Primeros Pasos

Estas instrucciones te ayudarán a obtener una copia del proyecto y ponerla en funcionamiento en tu máquina local para propósitos de desarrollo y pruebas.

### Prerrequisitos

- SDK de Flutter: [Instalar Flutter](https://flutter.dev/docs/get-started/install)
- Cuenta de Firebase: [Crear una Cuenta de Firebase](https://firebase.google.com/)
- Android Studio o VS Code con los plugins de Flutter y Dart instalados.

### Instalación

1.  Clona el repositorio:
    ```bash
    git clone https://github.com/ErickMendoza117/taskvoice.git
    ```
2.  Navega al directorio del proyecto:
    ```bash
    cd taskvoice
    ```
3.  Obtén las dependencias del proyecto:
    ```bash
    flutter pub get
    ```

### Configuración de Firebase

1.  Crea un nuevo proyecto de Firebase en la Consola de Firebase.
2.  Agrega una aplicación Android y/o iOS a tu proyecto de Firebase.
3.  Sigue las instrucciones de Firebase para descargar los archivos `google-services.json` (para Android) y `GoogleService-Info.plist` (para iOS) files.
4.  Coloca `google-services.json` en `android/app/`.
5.  Coloca `GoogleService-Info.plist` en `ios/Runner/`.
6.  Genera el archivo `firebase_options.dart` ejecutando el siguiente comando en la raíz de tu proyecto:
    ```bash
    flutterfire configure
    ```
    (Asegúrate de tener la CLI de Firebase instalada: `npm install -g firebase-tools`)

## Uso

Para ejecutar la aplicación en un dispositivo conectado o emulador:

```bash
flutter run
```

## Contribuciones

¡Las contribuciones son bienvenidas! Por favor, lee el [CONTRIBUTING.md](CONTRIBUTING.md) para detalles sobre nuestro código de conducta y el proceso para enviar pull requests.

## Licencia

Este proyecto está bajo la Licencia [MIT](LICENSE) - consulta el archivo [LICENSE](LICENSE) para más detalles.

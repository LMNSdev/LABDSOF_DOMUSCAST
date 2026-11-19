# condoapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Correr o Flutter em Docker

Se não for possível correr o Flutter localmente, usa o script `flutter-docker.ps1`
(requer Docker Desktop). Usa a mesma versão do Flutter que o CI e, na primeira
execução, constrói a imagem a partir de `Dockerfile.flutter`:

```powershell
.\flutter-docker.ps1 pub get
.\flutter-docker.ps1 analyze
.\flutter-docker.ps1 test
```

Serve para análise e testes. Não inclui o Android SDK, por isso não gera APKs nem
permite usar emuladores ou dispositivos.

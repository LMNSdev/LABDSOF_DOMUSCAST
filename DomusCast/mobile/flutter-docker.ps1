# Corre o Flutter dentro de Docker, com esta pasta montada em /app.
# Uso: .\flutter-docker.ps1 test | analyze | pub get | --version
$image = 'domuscast-flutter'

# Com cache, o build é quase instantâneo e mantém a imagem igual ao Dockerfile.
Get-Content -Raw "$PSScriptRoot\Dockerfile.flutter" | docker build -q -t $image - > $null
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

docker run --rm -t `
    -v "${PSScriptRoot}:/app" `
    -v domuscast-pub-cache:/root/.pub-cache `
    -w /app `
    $image flutter @args
exit $LASTEXITCODE

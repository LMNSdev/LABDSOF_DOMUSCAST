# Corre comandos Flutter num contentor Docker, na mesma versão do CI.
# Uso (a partir de qualquer pasta):
#   .github\skills\us-implementation\scripts\flutter.ps1                       # pub get + analyze + test
#   .github\skills\us-implementation\scripts\flutter.ps1 "flutter build apk --debug"
# Na primeira vez cria a imagem domuscast-flutter:<versão> (alguns minutos); o primeiro
# build do APK demora cerca de 10 minutos (depois fica em cache no volume domuscast-gradle).
param([string]$Comandos = "flutter pub get && flutter analyze && flutter test")

# Sem ErrorActionPreference=Stop: no PowerShell 5.1 o stderr do docker passaria a erro fatal.
$repo = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
$mobile = "$repo\DomusCast\mobile"

# Versão do CI, ex.: flutter-version: "3.47.x" -> 3.47
$linha = Select-String -Path "$repo\.github\workflows\ci.yml" -Pattern 'flutter-version:\s*"?([\d.]+)' | Select-Object -First 1
$versao = $linha.Matches[0].Groups[1].Value.TrimEnd('.')
$imagem = "domuscast-flutter:$versao"

docker image inspect $imagem *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Host "A criar $imagem (Flutter $versao.x mais recente)..."
  $tmp = Join-Path $env:TEMP "domuscast-flutter"
  New-Item -ItemType Directory -Force $tmp | Out-Null
  $script = @"
set -e
FR=`$(dirname "`$(dirname "`$(readlink -f "`$(which flutter)")")")
cd "`$FR"
git config --global --add safe.directory "`$FR"
TAG=`$(git ls-remote --tags --refs origin '$versao.*' | sed 's#.*refs/tags/##' | sort -V | tail -1)
git fetch --depth 1 origin tag "`$TAG"
git checkout -f "`$TAG"
rm -f bin/cache/flutter.version.json version
flutter --version | head -1
flutter precache --android > /dev/null
"@
  # Script por ficheiro: o PowerShell 5.1 estraga aspas dentro de bash -c.
  [IO.File]::WriteAllText("$tmp\pin.sh", ($script -replace "`r`n", "`n"))
  docker rm -f domuscast-flutter-setup *> $null
  docker run --name domuscast-flutter-setup -v "${tmp}:/scripts" ghcr.io/cirruslabs/flutter:stable bash /scripts/pin.sh
  if ($LASTEXITCODE -ne 0) { throw "Falhou a preparação da imagem $imagem" }
  docker commit domuscast-flutter-setup $imagem | Out-Null
  docker rm domuscast-flutter-setup | Out-Null
}

docker run --rm -v "${mobile}:/app" -v domuscast-pub-cache:/root/.pub-cache -v domuscast-gradle:/root/.gradle `
  -w /app $imagem bash -c $Comandos
exit $LASTEXITCODE

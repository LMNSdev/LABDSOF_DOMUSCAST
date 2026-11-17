# Funções para conduzir a app no emulador Android e tirar screenshots de evidência.
# Uso: . .github\skills\us-implementation\scripts\emulador.ps1 -Us us-15
#   Arrancar          liga o emulador (se não houver nenhum) e espera que termine o arranque
#   Instalar          instala o APK de debug (gerado com flutter.ps1 "flutter build apk --debug")
#   Limpar            apaga os dados da app (primeiro acesso) e abre-a
#   Reiniciar         fecha e abre a app, mantendo os dados
#   Textos            lista os textos, campos e botões visíveis, com as coordenadas
#   Tocar "texto"     toca no elemento que contém o texto (ou etiqueta de acessibilidade)
#   TocarCampo        toca no primeiro campo de texto
#   Escrever "texto"  escreve no campo com o foco (só ASCII; o teclado pode pôr maiúsculas)
#   Enter             envia o campo (tecla Enter)
#   Link "<token>"    abre domuscast://entrar?t=<token>, como se o residente tocasse no link
#   SemRede / ComRede liga e desliga o modo de avião
#   Shot "01-ecra"    guarda docs\sprintB\screenshots\<us>\01-ecra.png
# Não uses as teclas 111 (Esc) nem 4 (Voltar) para esconder o teclado: fecham diálogos e ecrãs.
param([Parameter(Mandatory = $true)][string]$Us)

$script:sdk = "$env:LOCALAPPDATA\Android\Sdk"
$script:adb = "$sdk\platform-tools\adb.exe"
$script:pkg = "com.condoapp.condoapp"
$script:repo = (Resolve-Path "$PSScriptRoot\..\..\..\..").Path
$script:shots = "$repo\docs\sprintB\screenshots\$Us"
$script:ui = Join-Path $env:TEMP "domuscast-ui.xml"
New-Item -ItemType Directory -Force $shots | Out-Null

function Arrancar {
  if ((& $adb devices) -match "emulator-\d+\s+device") { return "emulador já ligado" }
  $avd = (& "$sdk\emulator\emulator.exe" -list-avds | Select-Object -First 1)
  Start-Process "$sdk\emulator\emulator.exe" -ArgumentList "-avd", $avd, "-no-snapshot-save", "-no-boot-anim" -WindowStyle Minimized
  & $adb wait-for-device
  while ((& $adb shell getprop sys.boot_completed 2>$null) -notmatch "1") { Start-Sleep 2 }
  "emulador $avd ligado"
}

function Instalar { & $adb install -r "$repo\DomusCast\mobile\build\app\outputs\flutter-apk\app-debug.apk" }

function Limpar { & $adb shell pm clear $pkg | Out-Null; Reiniciar }

function Reiniciar {
  & $adb shell am force-stop $pkg
  & $adb shell monkey -p $pkg -c android.intent.category.LAUNCHER 1 2>&1 | Out-Null
  Start-Sleep 5
}

function Ui {
  & $adb shell uiautomator dump /sdcard/ui.xml 2>&1 | Out-Null
  & $adb pull /sdcard/ui.xml $ui 2>&1 | Out-Null
  [xml](Get-Content $ui -Raw -Encoding UTF8)
}

function Centro($no) {
  $b = [regex]::Matches($no.bounds, '\d+') | ForEach-Object { [int]$_.Value }
  & $adb shell input tap ([int](($b[0] + $b[2]) / 2)) ([int](($b[1] + $b[3]) / 2))
}

function Textos {
  (Ui).SelectNodes("//node") | ForEach-Object {
    $t = if ($_.text) { $_.text } else { $_.'content-desc' }
    if ($t) { "$t  [$($_.bounds)] $($_.class)" }
  }
}

function Tocar($texto) {
  $no = (Ui).SelectNodes("//node") | Where-Object { $_.text -like "*$texto*" -or $_.'content-desc' -like "*$texto*" } | Select-Object -Last 1
  if (-not $no) { throw "Elemento não encontrado: $texto" }
  Centro $no
  Start-Sleep 2
}

function TocarCampo {
  Centro ((Ui).SelectNodes("//node[@class='android.widget.EditText']") | Select-Object -First 1)
  Start-Sleep 1
}

function Escrever($texto) { & $adb shell "input text '$($texto -replace ' ', '%s')'" }

function Enter { & $adb shell input keyevent 66; Start-Sleep 3 }

function Link($token) {
  & $adb shell am start -a android.intent.action.VIEW -d "domuscast://entrar?t=$token" $pkg 2>&1 | Out-Null
  Start-Sleep 3
}

function SemRede { & $adb shell cmd connectivity airplane-mode enable; Start-Sleep 4 }
function ComRede { & $adb shell cmd connectivity airplane-mode disable; Start-Sleep 8 }

function Shot($nome) {
  # Copiar pelo telemóvel: "adb exec-out ... > ficheiro" estraga o PNG no PowerShell 5.1.
  & $adb shell screencap -p /sdcard/ecra.png | Out-Null
  & $adb pull /sdcard/ecra.png "$shots\$nome.png" 2>&1 | Out-Null
  "$shots\$nome.png"
}

#!/usr/bin/env bash
# Testes dos scripts da pipeline. Correr na raiz do repositório:
#   bash .github/scripts/tests.sh
# Usa tags reais da main (precisa do histórico completo e das tags).
set -uo pipefail

falhas=0
check() { # check <descrição> <obtido> <esperado>
  if [ "$2" = "$3" ]; then
    echo "OK    $1 -> $2"
  else
    echo "FALHA $1 -> '$2' (esperado '$3')"
    falhas=$((falhas + 1))
  fi
}

nv=.github/scripts/next-version.sh
check "sem tags"                    "$(bash $nv "" "")"                  v0.1.0
check "feat/ sobe o MINOR"          "$(bash $nv v0.2.3 feat/us-02)"      v0.3.0
check "feature/ sobe o MINOR"       "$(bash $nv v0.2.3 feature/us-15-x)" v0.3.0
check "fix/ sobe o PATCH"           "$(bash $nv v0.2.3 fix/bug)"         v0.2.4
check "docs/ sobe o PATCH"          "$(bash $nv v0.2.3 docs/x)"          v0.2.4
check "push direto sobe o PATCH"    "$(bash $nv v0.2.3 "")"              v0.2.4
check "a seguir ao MAJOR manual"    "$(bash $nv v1.0.0 feat/x)"          v1.1.0

sc=.github/scripts/server-changed.sh
check "primeira versão faz deploy"           "$(bash $sc "" v0.2.0)"     true
check "feat/us-01 mexeu na API"              "$(bash $sc v0.1.0 v0.2.0)" true
check "chore/codeowners não mexeu no servidor" "$(bash $sc v0.2.1 v0.2.2)" false

do=.github/scripts/docs-only.sh
check "sem versão anterior gera versão"       "$(bash $do "" fcd55a5)"            false
check "merge só de docs/ não gera versão"     "$(bash $do fcd55a5^1 fcd55a5)"     true
check "CODEOWNERS (fora de docs/) gera versão" "$(bash $do 1f7c607^1 1f7c607)"    false

# Não há na main um commit que mova código para docs/; usa-se um repositório temporário.
raiz=$PWD
tmp=$(mktemp -d)
(
  cd "$tmp" && git init -q && git config user.email ci@teste && git config user.name ci
  mkdir src docs && echo x > src/app.py && echo y > docs/a.md
  git add . && git commit -qm inicial && git mv src/app.py docs/app.py && git commit -qm mover
) > /dev/null 2>&1
check "código movido para docs/ gera versão"  "$(cd "$tmp" && bash "$raiz/$do" HEAD^ HEAD)" false
rm -rf "$tmp"

pr=.github/scripts/pr-rules.sh
check "branch feature/ aceite"           "$(bash $pr branch feature/us-09-privacidade)" true
check "branch feat/ aceite"              "$(bash $pr branch feat/deploy-azure)"         true
check "branch bugfix/ aceite"            "$(bash $pr branch bugfix/12-login)"           true
check "branch chore/ aceite"             "$(bash $pr branch chore/ci)"                  true
check "branch ci/ aceite"                "$(bash $pr branch ci/semgrep)"                true
check "branch fix/ aceite"               "$(bash $pr branch fix/login)"                 true
check "branch docs/ aceite (dailies)"    "$(bash $pr branch docs/daily-2026-11-18)"     true
check "branch release/ aceite"           "$(bash $pr branch release/sprint-b)"          true
check "branch sem prefixo recusado"      "$(bash $pr branch us-09-privacidade)"         false
check "branch hotfix/ recusado"          "$(bash $pr branch hotfix/x)"                  false
check "prefixo sem nome recusado"        "$(bash $pr branch feature/)"                  false
check "commit [#12] - aceite"            "$(bash $pr mensagem '[#12] - Adiciona formulário')"      true
check "commit com várias issues aceite"  "$(bash $pr mensagem '[#12, #13] - Formulário')"          true
check "commit #12 - aceite"              "$(bash $pr mensagem '#12 - Formulário')"                 true
check "commit de infraestrutura aceite"  "$(bash $pr mensagem 'GitHub: deploy só na main')"        true
check "merge do Git aceite"              "$(bash $pr mensagem "Merge branch 'main' into x")"       true
check "commit sem issue recusado"        "$(bash $pr mensagem 'Corrige o login')"                  false
check "área desconhecida recusada"       "$(bash $pr mensagem 'Coisas: várias')"                   false
check "issue sem descrição recusada"     "$(bash $pr mensagem '[#12] - ')"                         false
check "issue sem separador recusada"     "$(bash $pr mensagem '[#12] Formulário')"                 false

# Resumo dos testes (T-08): relatórios pequenos escritos aqui, no formato do pytest e do flutter.
rt=.github/scripts/resumo-testes.py
tmp=$(mktemp -d)
cat > "$tmp/ok.xml" <<'EOF'
<testsuites><testsuite name="pytest" tests="3"><testcase classname="tests.test_a" name="test_um" time="0.5"/><testcase classname="tests.test_a" name="test_dois" time="0.25"/><testcase classname="tests.test_a" name="test_tres" time="0.25"><skipped message="x"/></testcase></testsuite></testsuites>
EOF
cat > "$tmp/falha.xml" <<'EOF'
<testsuites><testsuite name="pytest" tests="2"><testcase classname="tests.test_b" name="test_ok" time="1"/><testcase classname="tests.test_b" name="test_partido" time="1"><failure message="assert"/></testcase></testsuite></testsuites>
EOF
cat > "$tmp/cobertura.xml" <<'EOF'
<coverage line-rate="0.873" branch-rate="0"></coverage>
EOF
cat > "$tmp/flutter.json" <<'EOF'
{"protocolVersion":"0.1.1","type":"start","time":0}
{"test":{"id":1,"name":"loading test/a_test.dart"},"type":"testStart","time":1}
{"testID":1,"result":"success","skipped":false,"hidden":true,"type":"testDone","time":2}
{"test":{"id":2,"name":"mostra o formulário"},"type":"testStart","time":3}
{"testID":2,"result":"success","skipped":false,"hidden":false,"type":"testDone","time":4}
{"test":{"id":3,"name":"anuncia o erro"},"type":"testStart","time":5}
{"testID":3,"result":"failure","skipped":false,"hidden":false,"type":"testDone","time":6}
{"success":false,"type":"done","time":2500}
EOF
linha() { python3 $rt "$@" | grep '^| [0-9]'; }
check "pytest verde: totais"              "$(linha junit API "$tmp/ok.xml")"                  "| 3 | 2 | 0 | 1 | 1,0 s |"
check "pytest verde: título com ✅"       "$(python3 $rt junit API "$tmp/ok.xml" | head -1)"   "### ✅ API"
check "pytest com falha: totais"          "$(linha junit API "$tmp/falha.xml")"               "| 2 | 1 | 1 | 0 | 2,0 s |"
check "pytest com falha: lista o teste"   "$(python3 $rt junit API "$tmp/falha.xml" | grep -c 'tests.test_b::test_partido')" 1
check "cobertura em percentagem"          "$(python3 $rt junit API "$tmp/ok.xml" "$tmp/cobertura.xml" | tail -1)" "Cobertura de linhas: **87,3%**"
check "flutter ignora os passos internos" "$(linha flutter App "$tmp/flutter.json")"          "| 2 | 1 | 1 | 0 | 2,5 s |"
check "flutter lista o teste que falhou"  "$(python3 $rt flutter App "$tmp/flutter.json" | grep -c 'anuncia o erro')" 1
check "sem relatório não falha o passo"   "$(python3 $rt junit API "$tmp/nao-existe.xml" > /dev/null; echo $?)" 0
echo "isto não é XML" > "$tmp/estragado.xml"
check "relatório estragado não falha"     "$(python3 $rt junit API "$tmp/estragado.xml" | grep -c 'Não foi possível ler')" 1
rm -rf "$tmp"

echo
if [ "$falhas" -eq 0 ]; then echo "Todos os testes passaram."; else echo "$falhas teste(s) falharam."; exit 1; fi

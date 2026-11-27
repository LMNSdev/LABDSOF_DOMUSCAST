#!/usr/bin/env python3
"""Resumo dos testes para o separador Summary de um run do GitHub Actions (T-08).

Uso (o resultado vai para stdout; no workflow, acrescentar a "$GITHUB_STEP_SUMMARY"):
  python3 resumo-testes.py junit   "<título>" <relatorio.xml> [cobertura.xml]
  python3 resumo-testes.py flutter "<título>" <relatorio.json>

- junit: relatório JUnit do pytest (--junitxml); a cobertura é o XML do pytest-cov
  (--cov-report=xml), no formato Cobertura.
- flutter: relatório JSON do `flutter test --file-reporter json:<ficheiro>`.

Sai sempre com 0: quem falha o job são os testes, não o resumo. Sem relatório (os testes
nem chegaram a correr), escreve isso mesmo.
"""

import json
import sys
import xml.etree.ElementTree as ET  # noqa: S405 (relatórios gerados pelo próprio job)
from pathlib import Path

MAX_FALHAS_LISTADAS = 20


def _segundos(valor: float) -> str:
    return f"{valor:.1f} s".replace(".", ",")


def _tabela(titulo: str, total: int, falhas: list[str], ignorados: int, duracao: float) -> str:
    passados = total - len(falhas) - ignorados
    estado = "✅" if not falhas else "❌"
    linhas = [
        f"### {estado} {titulo}",
        "",
        "| Total | Passados | Falhados | Ignorados | Duração |",
        "|---:|---:|---:|---:|---:|",
        f"| {total} | {passados} | {len(falhas)} | {ignorados} | {_segundos(duracao)} |",
    ]
    if falhas:
        linhas += ["", "**Falharam:**", ""]
        linhas += [f"- `{nome}`" for nome in falhas[:MAX_FALHAS_LISTADAS]]
        if len(falhas) > MAX_FALHAS_LISTADAS:
            linhas.append(f"- ... e mais {len(falhas) - MAX_FALHAS_LISTADAS}")
    return "\n".join(linhas)


def resumo_junit(titulo: str, relatorio: Path, cobertura: Path | None = None) -> str:
    raiz = ET.parse(relatorio).getroot()  # noqa: S314 (ficheiro gerado pelo pytest no job)
    casos = list(raiz.iter("testcase"))
    falhas, ignorados, duracao = [], 0, 0.0
    for caso in casos:
        duracao += float(caso.get("time") or 0)
        if caso.find("failure") is not None or caso.find("error") is not None:
            falhas.append(f"{caso.get('classname', '')}::{caso.get('name', '')}")
        elif caso.find("skipped") is not None:
            ignorados += 1
    texto = _tabela(titulo, len(casos), falhas, ignorados, duracao)
    if cobertura is not None and cobertura.exists():
        taxa = float(ET.parse(cobertura).getroot().get("line-rate", 0))  # noqa: S314
        texto += f"\n\nCobertura de linhas: **{taxa * 100:.1f}%**".replace(".", ",", 1)
    return texto


def resumo_flutter(titulo: str, relatorio: Path) -> str:
    nomes, falhas, total, ignorados, duracao_ms = {}, [], 0, 0, 0
    for linha in relatorio.read_text(encoding="utf-8").splitlines():
        if not linha.strip():
            continue
        evento = json.loads(linha)
        tipo = evento.get("type")
        if tipo == "testStart":
            nomes[evento["test"]["id"]] = evento["test"].get("name", "")
        elif tipo == "testDone" and not evento.get("hidden"):
            # "hidden" são os passos internos ("loading ..."), não são testes.
            total += 1
            if evento.get("skipped"):
                ignorados += 1
            elif evento.get("result") != "success":
                falhas.append(nomes.get(evento["testID"], f"teste {evento['testID']}"))
        elif tipo == "done":
            duracao_ms = evento.get("time", 0)
    return _tabela(titulo, total, falhas, ignorados, duracao_ms / 1000)


def main(argumentos: list[str]) -> str:
    if len(argumentos) < 3 or argumentos[0] not in ("junit", "flutter"):
        return "Uso: resumo-testes.py junit|flutter <título> <relatório> [cobertura.xml]"
    formato, titulo, relatorio = argumentos[0], argumentos[1], Path(argumentos[2])
    if not relatorio.exists():
        return f"### ⚠️ {titulo}\n\nSem relatório: os testes não chegaram a correr."
    if formato == "junit":
        cobertura = Path(argumentos[3]) if len(argumentos) > 3 else None
        return resumo_junit(titulo, relatorio, cobertura)
    return resumo_flutter(titulo, relatorio)


if __name__ == "__main__":
    try:
        print(main(sys.argv[1:]))
    except (OSError, ValueError, KeyError, ET.ParseError) as erro:
        print(f"### ⚠️ Resumo dos testes\n\nNão foi possível ler o relatório: {erro}")

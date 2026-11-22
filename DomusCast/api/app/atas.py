"""Regras da ata partilhadas entre a API (US-24) e o Worker (US-10).

- `gravar_resultado_ia`: o único caminho pelo qual o resultado da IA deve chegar
  à ata. Só escreve numa ata que ainda está `a_transcrever`, por isso uma resposta
  tardia nunca substitui uma ata aprovada (critério 2 da US-24) nem um rascunho
  que o administrador já está a rever.
- `apagar_audio`: apaga o ficheiro de áudio depois da aprovação (US-10, RNF-08, 10.4).

O áudio segue a convenção das fotos dos reportes: `audio_path` é um caminho
relativo a `MEDIA_ROOT` (ex.: `atas/<uuid>.m4a`).
"""

import logging
import os
from pathlib import Path

from sqlalchemy.orm import Session

from . import models

MEDIA_ROOT = Path(os.getenv("MEDIA_ROOT", "media"))

logger = logging.getLogger(__name__)


def gravar_resultado_ia(db: Session, ata_id: int, transcricao: str, rascunho: str) -> bool:
    """Grava a transcrição e o rascunho e passa a ata a `pendente_revisao`.

    Devolve `False`, sem alterar nada, se a ata não existir ou já não estiver
    `a_transcrever` (por exemplo, se foi aprovada entretanto). É um único UPDATE
    condicional, por isso não há janela entre verificar o estado e escrever.

    Não faz commit: o Worker grava o resultado e o estado do job na mesma transação.
    """
    alteradas = (
        db.query(models.Ata)
        .filter(
            models.Ata.id == ata_id,
            models.Ata.estado == models.EstadoAta.a_transcrever,
        )
        .update(
            {
                "transcricao": transcricao,
                "rascunho": rascunho,
                "estado": models.EstadoAta.pendente_revisao,
            },
            synchronize_session=False,
        )
    )
    return alteradas == 1


def apagar_audio(audio_path: str | None) -> None:
    """Apaga o ficheiro de áudio; não falha se já não existir.

    Chamado depois do commit da aprovação: a ata já está publicada, por isso uma
    falha a apagar o ficheiro fica registada no log e não desfaz a aprovação.
    Recusa caminhos fora de `MEDIA_ROOT`, para um valor inesperado na base de
    dados nunca apagar outro ficheiro do servidor.
    """
    if not audio_path:
        return
    raiz = MEDIA_ROOT.resolve()
    caminho = (raiz / audio_path).resolve()
    if not caminho.is_relative_to(raiz):
        logger.warning("Áudio da ata fora de MEDIA_ROOT; não foi apagado.")
        return
    try:
        caminho.unlink(missing_ok=True)
    except OSError as exc:
        # Só o código do erro: a mensagem de um OSError inclui o caminho do
        # ficheiro, que pode identificar a assembleia (RNF-08).
        logger.error("Não foi possível apagar o áudio de uma ata aprovada (errno %s).", exc.errno)

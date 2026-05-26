#!/bin/bash
# mp — pipeline eficiente para planos básicos
# Filosofia: Claude é o agente principal. Codex é reserva ou complemento explícito.
# Uso:
#   mp "task"           → Claude sozinho (padrão, economiza mensagens)
#   mp -p "task"        → pipeline Claude→Codex (use só em features grandes)
#   mp -r "task"        → roteamento automático leve (regex, sem LLM extra)
#   mp -x "task"        → Codex direto (quando Claude estiver throttled)

AGENT_DIR="$HOME/.agent"
CLAUDE_OUT="$AGENT_DIR/claude-out.md"
CODEX_OUT="$AGENT_DIR/codex-out.md"

MODE="claude"   # padrão: Claude sozinho

# Parse flags
while [[ "$1" == -* ]]; do
  case "$1" in
    -p) MODE="pipeline" ;;   # pipeline explícito
    -r) MODE="route"    ;;   # roteamento regex local
    -x) MODE="codex"    ;;   # Codex direto
    *)  break ;;
  esac
  shift
done

TASK="$*"

if [ -z "$TASK" ] && [ -f "$AGENT_DIR/task.md" ]; then
  TASK="$(cat "$AGENT_DIR/task.md")"
fi

if [ -z "$TASK" ]; then
  echo "Uso: mp [-p|-r|-x] \"sua task\""
  echo "  (sem flag)  Claude sozinho — padrão, economiza mensagens"
  echo "  -p          pipeline Claude→Codex — features com split claro"
  echo "  -r          roteamento automático por padrões de texto"
  echo "  -x          Codex direto — use quando Claude estiver throttled"
  exit 1
fi

# ── Roteamento regex local (sem LLM) ────────────────────────
# Só ativado com -r. Não gasta mensagem extra.
route_task() {
  local t="${TASK,,}"   # lowercase

  # Padrões claros → Codex (geração pura, sem leitura de código existente)
  if echo "$t" | grep -qE "gera (mock|seed|fixture|boilerplate|template)|cria.*do zero|documenta|escreve.*readme|gera.*tipos|interface.*a partir de"; then
    echo "codex"
    return
  fi

  # Padrões claros → pipeline (tem parte backend E parte frontend)
  if echo "$t" | grep -qE "(endpoint|rota|api).*(tela|componente|screen|frontend)|(tela|componente|screen).*(endpoint|rota|api)|migration.*(tela|screen)|backend.*(frontend|ui)"; then
    echo "pipeline"
    return
  fi

  # Tudo mais → Claude
  echo "claude"
}

if [ "$MODE" = "route" ]; then
  MODE="$(route_task)"
  echo "→ modo detectado: $MODE"
fi

# ── Execução ─────────────────────────────────────────────────
> "$CLAUDE_OUT"
> "$CODEX_OUT"

case "$MODE" in

  claude)
    claude --dangerously-skip-permissions "$TASK"
    ;;

  codex)
    codex exec --dangerously-bypass-approvals-and-sandbox "$TASK"
    ;;

  pipeline)
    echo "┌─ PASSO 1: Claude"
    CLAUDE_FULL="$TASK

Quando terminar, escreva em $CLAUDE_OUT:
- Arquivos criados/alterados
- Contratos de API: método, path, body, response
- Tipos TypeScript ou schemas que o frontend vai usar"

    claude --dangerously-skip-permissions "$CLAUDE_FULL"

    echo ""
    echo "└─ PASSO 2: Codex"
    CODEX_FULL="$TASK"
    if [ -s "$CLAUDE_OUT" ]; then
      CODEX_FULL="$TASK

HANDOFF DO BACKEND — use estes contratos exatamente:
$(cat "$CLAUDE_OUT")"
    fi
    codex exec --dangerously-bypass-approvals-and-sandbox "$CODEX_FULL"
    ;;

esac

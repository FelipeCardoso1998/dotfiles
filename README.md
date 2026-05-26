# dotfiles — Claude Code global agents + pipeline

## Estrutura
- `agents/` → copiar para `~/.claude/agents/` (subagents globais)
- `pipeline.sh` → copiar para `~/.agent/pipeline.sh`

## Aliases no ~/.bashrc
```bash
alias mc='claude --dangerously-skip-permissions'
alias mx='codex --approval-mode full-auto'
alias mp='bash ~/.agent/pipeline.sh'
alias mt='${EDITOR:-nano} ~/.agent/task.md'
```

## Uso do pipeline
```
mp "task"       # Claude sozinho (padrão)
mp -p "task"    # pipeline Claude→Codex (features grandes)
mp -r "task"    # roteamento automático por regex
mp -x "task"    # Codex direto (Claude throttled)
```

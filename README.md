# Syscoin Claude Configuration

![Version](https://img.shields.io/badge/version-0.1.0-blue)
![Status](https://img.shields.io/badge/status-scaffold-yellow)
![License](https://img.shields.io/badge/license-MIT-green)

Claude Code configuration for full-stack Syscoin development — Core (UTXO/SPT) + NEVM (EVM L1).

> **Status**: v0.1.0 is a scaffold. Agents, commands, rules, and skills are not yet populated. See the roadmap in [CLAUDE.md](CLAUDE.md) for progress.

Inspired by [solana-claude-config](https://github.com/solanabr/solana-claude-config). Same architectural patterns (two-file CLAUDE.md split, lazy-loaded rules, progressive skill loading, MCP integration, agent teams), adapted for Syscoin's tooling.

## Scope

- **Syscoin Core** — UTXO chain, SPT assets, Z-DAG, PSBT, merged-mined with BTC
- **NEVM** — EVM-compatible L1, Solidity + Hardhat/Foundry
- **Not supported**: Rollux (being discontinued), zkSYS (deferred)

## Framework Defaults

- **Primary**: Hardhat + Ethers v6 (matches [official Syscoin docs](https://docs.syscoin.org/docs/dev-resources/nevm/hardhat))
- **Secondary**: Foundry + Viem (fully supported via lazy-loaded rules)

## Installation (planned)

```bash
# Once published:
curl -fsSL https://raw.githubusercontent.com/<org>/syscoin-claude-config/main/install.sh | bash

# Or manual:
git clone --recurse-submodules https://github.com/<org>/syscoin-claude-config.git
cp -r syscoin-claude-config/.claude /path/to/your-project/
cp syscoin-claude-config/CLAUDE-syscoin.md /path/to/your-project/CLAUDE.md
```

## Repository Structure

```
.
├── CLAUDE.md                    # Maintainer config (this repo)
├── CLAUDE-syscoin.md            # Ships to user projects as CLAUDE.md
├── README.md                    # This file
├── QUICK-START.md               # 2-minute install guide
├── .mcp.json                    # MCP server configs
├── .env.example                 # API key template
├── install.sh                   # One-liner installer
├── update.sh                    # Update to latest upstream
├── validate.sh                  # Config integrity check
├── tests/                       # Shell-based integrity tests
├── .github/workflows/           # CI
└── .claude/
    ├── VERSION                  # Semver
    ├── CHANGELOG.md             # Release log
    ├── settings.json            # Permissions, hooks, agent teams
    ├── agents/                  # Specialized agents (TBD)
    ├── bin/                     # update.sh, resync.sh helpers (TBD)
    ├── commands/                # Slash commands (TBD)
    ├── rules/                   # Auto-loading file-pattern rules (TBD)
    └── skills/
        ├── SKILL.md             # Unified skill hub (TBD)
        ├── ext/                 # External skill submodules (TBD)
        └── *.md                 # Local authored skills (TBD)
```

## Planned Components

### Agents (~6–8, first cut)

| Agent | Purpose |
|-------|---------|
| `syscoin-architect` | Cross-layer design (Core vs NEVM), SPT vs ERC-20 tradeoffs, bridging |
| `solidity-engineer` | NEVM Solidity contracts with Hardhat/Foundry |
| `syscoin-core-engineer` | UTXO, SPT, PSBT, node RPC |
| `nevm-frontend-engineer` | Viem/wagmi/Ethers, Pali + MetaMask flows |
| `syscoin-qa-engineer` | Foundry fuzzing, Hardhat tests, regtest for Core |
| `devops-engineer` | Node infra, RPC providers, CI/CD |
| `syscoin-guide` | Learning and tutorials |
| `syscoin-researcher` | Ecosystem research |

### Commands (planned set)

- **Build**: `/build-contracts`, `/build-app`, `/scaffold`
- **Quality**: `/test-foundry`, `/test-hardhat`, `/audit-syscoin`, `/diff-review`, `/gas-profile`, `/debug-user-tx`
- **Deploy**: `/deploy`, `/verify-contract`, `/bridge-deploy`
- **Core-specific**: `/spt-create`, `/regtest-up`
- **Workflow**: `/quick-commit`, `/setup-ci-cd`, `/setup-mcp`, `/update`, `/cleanup`, `/write-docs`, `/explain-code`, `/plan-feature`, `/resync`

### Rules (lazy-loaded by file pattern)

`solidity.md`, `hardhat.md`, `foundry.md`, `ethers.md`, `viem.md`, `typescript.md`, `syscoin-core.md`.

### Skills

- **Local**: `spt-tokens.md`, `syscoin-core-rpc.md`, `nevm-deployment.md`, `pali-wallet.md`, `syscoin-reference.md` (llms.txt-powered discovery)
- **Vendored submodules**: `trailofbits`, `cloudflare`, `vercel`

### MCP Servers

`context7`, `playwright`, `context-mode`, `memsearch`. Additional EVM RPC / explorer MCPs to be evaluated.

## Roadmap

See the full phase plan in [CLAUDE.md](CLAUDE.md#roadmap).

## License

MIT — see [LICENSE](LICENSE).

# Syscoin Claude Config — Meta Configuration
<!-- This is the config-repo maintainer file (NOT shipped to user projects).
     CLAUDE-syscoin.md is the one that ships as CLAUDE.md to target projects. -->

This repository contains Claude Code configuration for Syscoin development projects. The actual Syscoin builder configuration lives in `CLAUDE-syscoin.md` and should be copied to target projects as their `CLAUDE.md`.

**Install docs**: See README.md and QUICK-START.md.

**Status**: v0.1.0 — scaffold only. Agents, commands, rules, and skills are not yet populated.

---

## This Repo's Purpose

You are maintaining the **syscoin-claude-config** repository — a template/library of Claude Code configurations for Syscoin development. Your role is to improve, test, and maintain the agents, skills, commands, MCP servers, and rules that other projects will use.

## Scope

- **Syscoin Core** (UTXO, SPT assets, Z-DAG, PSBT, syscoind/syscoin-cli)
- **NEVM** (EVM-compatible L1 smart contract layer; merged-mined with BTC)
- **Out of scope for v1**: Rollux (being discontinued), zkSYS (zksync-era fork; deferred)

## Framework Defaults

- **Primary**: Hardhat + Ethers v6 (Syscoin's official docs use these)
- **Secondary**: Foundry + Viem (supported via lazy-loaded rules; no first-class scaffolding yet)

Rationale: the Syscoin documentation's canonical smart-contract deploy tutorial uses Hardhat. Defaulting to Foundry would create friction for devs copy-pasting from official docs.

## Token Loading Model

| File | When loaded | Budget guidance |
|------|-------------|-----------------|
| `CLAUDE.md` | Session start; delivered as user message (uncached) | Keep <200 lines |
| `CLAUDE-syscoin.md` | Session start (user projects) | Keep <120 lines |
| `.claude/rules/*.md` (with `paths:`) | Lazy — on matching file read | Can be detailed |
| `.claude/rules/*.md` (no `paths:`) | Session start | Minimal — always loaded |
| `.claude/agents/*.md` | On agent spawn | Can be detailed |
| `.claude/commands/*.md` | On invocation | Can be detailed |
| `.claude/skills/SKILL.md` | On invocation | Medium |
| `.claude/skills/*.md` | On-demand via links | Can be detailed |

## Communication Style

- No filler phrases
- Direct, efficient responses — code/config first, explanations when needed
- Admit uncertainty rather than guess
- Consider token efficiency in all additions

## Ripple Map
<!-- When adding/removing any component, walk through every row before committing. -->

| Changed | Also update |
|---------|-------------|
| Add/remove **agent** | README.md agent table, install.sh output, tests/test_agents.sh |
| Add/remove **command** | README.md commands table, tests/test_commands.sh |
| Add/remove **MCP server** | README.md MCP table, CLAUDE-syscoin.md MCP list, .env.example, commands/setup-mcp.md |
| Add/remove **submodule** | .gitmodules, README.md submodule table, .claude/skills/SKILL.md routing |
| Modify **install.sh** | Run `bash tests/test_install.sh` in a temp dir |
| Modify **CLAUDE-syscoin.md** | This ships to ALL user projects — different audience than this repo |

## Roadmap

Delivery is sliced by domain (contracts → core → frontend/devops) rather than by phase number. Contract-focused content ships first.

- [x] **Phase 1** — Repo scaffold (v0.1.0)
- [x] **Phase 2 (contracts)** — Rules: `solidity.md`, `hardhat.md`, `foundry.md`, `typescript.md` (v0.2.0)
- [x] **Phase 3 (contracts)** — Agents: `solidity-engineer`, `syscoin-architect`, `nevm-qa-engineer` (v0.2.0)
- [ ] **Phase 4 (contracts)** — Commands: build/test/deploy/quality for NEVM (`/build-contracts`, `/test-foundry`, `/test-hardhat`, `/audit-syscoin`, `/gas-profile`, `/deploy`, `/verify-contract`, `/diff-review`)
- [ ] **Future — Core/UTXO**: rules and skills for Syscoin Core (SPT, PSBT, syscoin-cli, syscoinjs-lib). Out of scope for v1 contracts bundle.
- [ ] **Future — Frontend / DevOps**: `nevm-frontend-engineer`, `devops-engineer`, `syscoin-guide`, `syscoin-researcher` agents
- [ ] **Future — Skills**: `syscoin-reference.md` (llms.txt index), `spt-tokens.md`, `bridge-nevm-utxo.md`, `pali-wallet.md`
- [ ] **Future — MCP**: EVM RPC and explorer MCP servers
- [ ] **Future — Tests + CI**: shell-based integrity tests + GitHub Actions
- [ ] **Future — Finalize CLAUDE-syscoin.md** based on real-world feedback

## When Editing This Repo

| Component | Location | Key Rule |
|-----------|----------|----------|
| **Agents** | `.claude/agents/` | Non-overlapping responsibilities; spawn other agents for cross-domain work |
| **Skills** | `.claude/skills/` | Progressive loading; reference from `SKILL.md`; prefer code over prose |
| **Commands** | `.claude/commands/` | Atomic (one command, one purpose); document inputs/outputs |
| **Rules** | `.claude/rules/` | Minimal — they load on every matching file; use `paths:` in frontmatter |
| **MCP Servers** | `.mcp.json` | Document env vars; test connectivity; update setup-mcp command |

## Release Management

- `.claude/VERSION` contains current semver. Bump **patch** for fixes, **minor** for new components, **major** for breaking install.sh changes.
- Prepend a new entry to `.claude/CHANGELOG.md` on every bump.

---

**Main config**: `CLAUDE-syscoin.md` | **Agents**: `.claude/agents/` | **Skills**: `.claude/skills/` | **Commands**: `.claude/commands/` | **MCP**: `.mcp.json` | **Rules**: `.claude/rules/`

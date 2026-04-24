---
name: syscoin-dev
description: Unified skill hub for Syscoin development. Routes to local skills and external submodule skills. Progressive disclosure — read only what you need.
user-invocable: true
---

# Syscoin Development Skill Hub

Routes to the right skill file based on the task. Read the relevant section, follow the link, load that skill.

## Status

**v0.1.0 scaffold** — skill files not yet authored. This file is a placeholder reflecting the planned structure.

## Planned Skills

### Core Syscoin (Local)

- [syscoin-reference.md](syscoin-reference.md) — Discovery index backed by upstream `llms.txt`. Lists canonical docs for Syscoin Core, NEVM, Pali, Bridge, syscoinjs-lib. Agents WebFetch specific pages on demand.
- [syscoin-core-rpc.md](syscoin-core-rpc.md) — UTXO/SPT via syscoin-cli and JSON-RPC; PSBT workflows; Z-DAG semantics.
- [spt-tokens.md](spt-tokens.md) — SPT asset creation, issuance, transfer, allocation.
- [nevm-deployment.md](nevm-deployment.md) — Devnet (Tanenbaum) and mainnet deploy workflows, verification, multisig.
- [pali-wallet.md](pali-wallet.md) — Pali wallet integration (UTXO + NEVM dual-mode), MetaMask coexistence.
- [bridge-nevm-utxo.md](bridge-nevm-utxo.md) — Syscoin Bridge between UTXO and NEVM sides.

### Smart Contract Development (Local)

- [nevm-hardhat-patterns.md](nevm-hardhat-patterns.md) — Hardhat config for NEVM, deploy scripts, hardhat-verify setup.
- [nevm-foundry-patterns.md](nevm-foundry-patterns.md) — Foundry config for NEVM, forge scripts, fork testing.

### External Skills (Planned Submodules)

| Submodule | Source | Purpose |
|-----------|--------|---------|
| `ext/trailofbits` | [trailofbits/skills](https://github.com/trailofbits/skills) | Security auditing (EVM-applicable patterns) |
| `ext/cloudflare` | [cloudflare/skills](https://github.com/cloudflare/skills) | Infrastructure (Workers, Agents SDK, MCP servers) |
| `ext/vercel` | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | Vercel deployment, Next.js, AI SDK, v0, edge functions |

### Library Documentation (Dynamic via Context7 MCP)

For up-to-date docs on Hardhat, Foundry, Ethers v6, Viem, wagmi, OpenZeppelin, solhint, slither — use the Context7 MCP server. Avoids vendoring stale snapshots.

## Task Routing (Planned)

| User asks about... | Primary skill |
|--------------------|---------------|
| NEVM contract code | nevm-hardhat-patterns.md OR nevm-foundry-patterns.md |
| Contract deployment | nevm-deployment.md |
| Security review, audit | ext/trailofbits + security checklist in solidity rules |
| SPT token creation | spt-tokens.md |
| Syscoin Core RPC, syscoin-cli | syscoin-core-rpc.md |
| PSBT, multisig (UTXO side) | syscoin-core-rpc.md |
| Bridge UTXO ↔ NEVM | bridge-nevm-utxo.md |
| Wallet integration, Pali, MetaMask | pali-wallet.md |
| Unknown / exploration | syscoin-reference.md → fetch canonical docs |
| Library docs (Hardhat, Viem, OZ, etc.) | Context7 MCP |
| Workers, edge deployment | ext/cloudflare |
| Vercel / Next.js deployment | ext/vercel |

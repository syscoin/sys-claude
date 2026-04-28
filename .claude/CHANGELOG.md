# Changelog

All notable changes to the syscoin-claude config will be documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versioning follows [SemVer](https://semver.org/).

## [0.2.0] - 2026-04-27

### Added
- **Rules** (4 lazy-loaded files for contract-related work):
  - `solidity.md` — language discipline, NEVM facts (Chain IDs 57/5700, Blockscout verification), security anti-patterns. Triggers on `**/*.sol`.
  - `hardhat.md` — config template with `customChains` for NEVM, deploy script patterns, Chai+ethers tests, fork testing. Triggers on `hardhat.config.*`, `scripts/`, `tasks/`, `test/` TS/JS files.
  - `foundry.md` — `foundry.toml` template with `[rpc_endpoints]` + Blockscout verification, fuzz/invariant patterns, deploy scripts, cast. Triggers on `foundry.toml`, `*.t.sol`, `*.s.sol`, `remappings.txt`.
  - `typescript.md` — Ethers v6 primary + Viem secondary, wagmi for React, BigInt discipline, EIP-6963 wallet discovery (Pali + MetaMask). Triggers on all TS files.
- **Agents** (3 contract-focused specialists, non-overlapping responsibilities):
  - `solidity-engineer` — writes/modifies Solidity contracts; implements specs.
  - `syscoin-architect` — produces design specifications, decision documents, interface stubs (NOT implementation).
  - `nevm-qa-engineer` — tests, security reviews, fuzzing, invariants, static analysis, audit-readiness.

### Changed
- Roadmap reorganized in `CLAUDE.md` and `README.md` to reflect domain-sliced delivery (contracts → core → frontend/devops) instead of phase-numbered delivery.
- Removed forward reference to non-existent `nevm-deployment.md` skill from `solidity.md`.
- Reworded the network-naming guidance in `hardhat.md` to use a concrete reason (multi-chain ambiguity with Ethereum) instead of subjective phrasing.

### Notes
- Out of scope for v1: Syscoin Core (UTXO/SPT/PSBT), Rollux, zkSYS. Core-side rules and skills will land when scope expands.
- Commands, skills, MCP additions, and tests are tracked under "Future" in the roadmap.

## [0.1.0] - 2026-04-23

### Added
- Initial repository scaffold: directory structure, skeleton files, install/update/validate scripts.
- Scope: Syscoin Core (UTXO/SPT) + NEVM (EVM L1). Rollux and zkSYS intentionally out of scope for v1.
- Framework defaults: Hardhat + Ethers primary; Foundry + Viem secondary (both supported via lazy rules).

### Notes
- Agents, commands, rules, and skills not yet populated — placeholders only.
- `llms.txt` from upstream Syscoin will drive authoring of rules/skills in subsequent phases.

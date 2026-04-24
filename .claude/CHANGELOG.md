# Changelog

All notable changes to the syscoin-claude config will be documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versioning follows [SemVer](https://semver.org/).

## [0.1.0] - 2026-04-23

### Added
- Initial repository scaffold: directory structure, skeleton files, install/update/validate scripts.
- Scope: Syscoin Core (UTXO/SPT) + NEVM (EVM L1). Rollux and zkSYS intentionally out of scope for v1.
- Framework defaults: Hardhat + Ethers primary; Foundry + Viem secondary (both supported via lazy rules).

### Notes
- Agents, commands, rules, and skills not yet populated — placeholders only.
- `llms.txt` from upstream Syscoin will drive authoring of rules/skills in subsequent phases.

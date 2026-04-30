---
name: build-contracts
description: Compile NEVM contracts. Auto-detects Foundry or Hardhat. Pass --clean to wipe artifacts first.
argument-hint: "[--clean]"
---

# /build-contracts

Compile the NEVM contracts in this project. Detect framework, run the appropriate build, surface meaningful output.

## Steps

### 1. Detect framework

Check the project root for:
- `foundry.toml` → Foundry project
- `hardhat.config.ts`, `hardhat.config.js`, `hardhat.config.cts`, `hardhat.config.mts` → Hardhat project

If both exist, build both. If neither exists, stop and report:

> No Foundry (`foundry.toml`) or Hardhat (`hardhat.config.*`) project detected in the current directory. Run this command from a contract project root.

### 2. Optional clean

If `$ARGUMENTS` contains `--clean`, run the framework's clean command first:

- Foundry: `forge clean`
- Hardhat: `npx hardhat clean`

Strip `--clean` from `$ARGUMENTS` before passing to the build step.

### 3. Build

Run the appropriate command. Forward any remaining args after `--clean` to the build tool.

**Foundry:**
```bash
forge build --sizes $ARGUMENTS
```

`--sizes` shows runtime bytecode sizes per contract — keep it on by default; it's free and surfaces EIP-170 risk.

**Hardhat:**
```bash
npx hardhat compile $ARGUMENTS
```

**Both frameworks present:**
Run them in sequence (Foundry first, then Hardhat). Report each result separately. Do not stop on the first failure — report both.

### 4. Report

On **success**, summarize per framework:

- **Foundry**: contract count, runtime sizes for any contract whose `--sizes` output is `>= 22KB` (EIP-170 limit is 24,576 bytes; flag at ~90%). Forward any compiler warnings verbatim.
- **Hardhat**: contract count, any compiler warnings verbatim.

On **failure**:

- Surface the compiler error verbatim with the originating `file:line`.
- Do **not** attempt to fix the error in this command. Suggest the user invoke the `solidity-engineer` agent or fix manually.

## What this command does NOT do

- Does not run tests — use `/test-foundry` or `/test-hardhat`.
- Does not deploy — use `/deploy`.
- Does not modify source code — read-only build.
- Does not auto-fix compiler errors — surfaces them only.
- Does not spawn agents — deterministic shell work.

## Examples

| Invocation | Behavior |
|------------|----------|
| `/build-contracts` | Build with default args |
| `/build-contracts --clean` | Clean artifacts, then build |
| `/build-contracts --force` (Hardhat-only project) | Forwards `--force` to `npx hardhat compile` |
| `/build-contracts --skip test/` (Foundry-only) | Forwards `--skip test/` to `forge build` |

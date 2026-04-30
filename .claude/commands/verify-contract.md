---
name: verify-contract
description: Verify a deployed NEVM contract on Blockscout-compatible explorer (tanenbaum or nevm). Auto-detects Foundry or Hardhat.
argument-hint: "<address> [tanenbaum|nevm] [constructor-args...]"
---

# /verify-contract

Verify a contract that's already been deployed to NEVM on the Blockscout-compatible block explorer.

## Steps

### 1. Parse arguments

- **First arg**: contract address (required, must match `0x[a-fA-F0-9]{40}`).
- **Second arg**: network — `tanenbaum` (default) or `nevm`.
- **Remaining args**: constructor arguments (positional, in declared order).

If no address is provided, stop and explain the syntax.

If the address format is invalid, stop and report it back literally so the user sees what was parsed.

### 2. Resolve verifier URL

| Network | Verifier URL |
|---------|--------------|
| tanenbaum | `https://tanenbaum.io/api` |
| nevm | `https://explorer.syscoin.org/api` |

API key: any non-empty string. Blockscout doesn't require a real key; framework configs ship with `"abc"` placeholders.

### 3. Detect framework

Same detection as `/deploy`:

- `foundry.toml` → Foundry
- `hardhat.config.*` → Hardhat
- Both present → ask user which to use for verification (Foundry's `forge verify-contract` and Hardhat's `npx hardhat verify` both work; pick whichever matches how the contract was originally deployed)

### 4. Run verification

**Foundry path:**

```bash
forge verify-contract <address> <ContractPath>:<ContractName> \
  --verifier blockscout \
  --verifier-url <verifier-url> \
  --chain <chain-id> \
  $CONSTRUCTOR_ARGS_FORMATTED
```

If the user did not provide `<ContractPath>:<ContractName>`, ask. Foundry needs the explicit contract reference — there's no auto-detection from address.

For constructor args in Foundry, encode with `cast abi-encode "constructor(<types>)" <values>` and pass via `--constructor-args 0x<encoded>`.

**Hardhat path:**

```bash
npx hardhat verify --network <network> <address> <constructor-args-positional>
```

Hardhat resolves the contract from the build artifacts automatically — no `<path>:<name>` needed.

### 5. Interpret result

**On success:** report the explorer URL:

> Verified: `https://<explorer>/address/<address>#code`

**On failure**, surface the verifier's error and suggest the appropriate fix:

| Error | Likely cause | Suggested action |
|-------|--------------|------------------|
| "Contract not yet indexed" / "Unable to locate contract" | Verification triggered too soon after deploy | Wait 30–60 seconds, retry |
| "Constructor argument mismatch" / decoded args differ | Wrong constructor args supplied | Compare against what was passed to deploy; re-run with corrected args |
| "Compiler version mismatch" | Verifier compiled with different solc | Pin the same compiler version that produced the deploy artifact |
| "Optimizer settings differ" | `optimizer_runs` or `via_ir` doesn't match | Align settings in `foundry.toml` or `hardhat.config.*` to match deploy |
| "Already verified" | Idempotency | Treat as success; show the existing explorer link |

Do not retry automatically on failure — surface the issue, let the user respond.

## What this command does NOT do

- Does not deploy — separate command (`/deploy`)
- Does not modify config to "fix" verification mismatches — surfaces them, user decides
- Does not detect contract from address alone — Foundry needs `<path>:<name>` explicitly
- Does not handle proxy verification (TransparentUpgradeableProxy / UUPS) automatically — proxies require verifying both the proxy and the implementation; this command verifies one contract per invocation

## Examples

| Invocation | Behavior |
|------------|----------|
| `/verify-contract 0xabc...123` | Verify on tanenbaum (default), auto-detect framework |
| `/verify-contract 0xabc...123 nevm` | Verify on mainnet |
| `/verify-contract 0xabc...123 tanenbaum 0xdeadbeef 1000` | Pass two constructor args |
| `/verify-contract 0xabc...123 tanenbaum src/Vault.sol:Vault` | Foundry path with explicit contract reference |

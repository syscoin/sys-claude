---
name: deploy
description: Deploy NEVM contracts to localhost, tanenbaum (testnet), or nevm (mainnet — typed confirmation required). Auto-detects Foundry or Hardhat.
argument-hint: "<localhost|tanenbaum|nevm> [extra args]"
---

# /deploy

Deploy NEVM contracts to a target network. Includes pre-flight summary and mainnet gating.

## Steps

### 1. Parse the network

Read the first token of `$ARGUMENTS`. Accept:
- `localhost` — local Anvil/Hardhat node
- `tanenbaum` — Syscoin NEVM testnet (chain ID 5700)
- `nevm` — Syscoin NEVM mainnet (chain ID 57) — **GATED**

If no network is provided, default to `tanenbaum` and tell the user explicitly which network was selected.

If the network is `nevm`, mainnet protocol applies (Step 5).

### 2. Detect framework + deploy script

Look for, in order:
1. `foundry.toml` AND `script/Deploy.s.sol` → Foundry path
2. `hardhat.config.{ts,js,cts,mts}` AND `scripts/deploy.{ts,js}` → Hardhat path
3. Both present with both deploy scripts → **ask the user which to run**. Do not pick silently.
4. Neither path complete → stop and report what's missing (framework or deploy script).

### 3. Pre-flight summary

Before any deploy command, print:

- Framework: Foundry or Hardhat
- Target network + chain ID
- RPC URL (resolve from `.env` or framework config)
- Deployer address (from `PRIVATE_KEY` env, or deduce from framework)
- Deployer balance in SYS (from `cast balance` or `npx hardhat run` snippet — fall back to "unknown" if no RPC connectivity)
- Deploy script path
- Build freshness: warn if any `.sol` file under `src/` or `contracts/` is newer than the latest artifact in `out/` or `artifacts/`. Do not block — warn only.

### 4. Confirm (testnet & localhost)

For `localhost` and `tanenbaum`, ask once:

> Proceed with deployment to <network>? (yes/no)

If the user says yes, proceed to Step 6. If no, abort and report nothing was changed.

### 5. Confirm (mainnet) — gated

For `nevm`, **require a typed literal confirmation** in the conversation:

> ⚠️  MAINNET DEPLOY (chain 57). This is irreversible.
> To proceed, type exactly: `DEPLOY TO NEVM MAINNET`

Do not accept variations (lowercase, partial, etc.). If the typed string does not match exactly, abort.

The PreToolUse hook in `.claude/settings.json` is a secondary gate that may also prompt on the underlying `forge script --broadcast` or `hardhat run --network nevm` command. Both gates passing is expected.

### 6. Run the deploy

**Foundry path:**

```bash
forge script script/Deploy.s.sol \
  --rpc-url <network> \
  --broadcast \
  $REMAINING_ARGUMENTS
```

`<network>` resolves to the entry in `[rpc_endpoints]` in `foundry.toml`. `$REMAINING_ARGUMENTS` is `$ARGUMENTS` with the leading network token stripped.

**Hardhat path:**

```bash
npx hardhat run scripts/deploy.<ts|js> --network <network> $REMAINING_ARGUMENTS
```

### 7. Post-deploy report

Parse the deploy output and report:

- **Deployed contract address(es)** — Foundry's `forge script` prints these in the broadcast log; Hardhat's typical deploy script prints via `console.log`. Capture both.
- **Transaction hash(es)**
- **Block number** (if available)
- **Explorer link**: `https://explorer.tanenbaum.io/address/<addr>` or `https://explorer.syscoin.org/address/<addr>`
- **Next-step suggestion**: `Run /verify-contract <address> <network> to verify on Blockscout.`

Save the deploy artifact location (Foundry: `broadcast/`, Hardhat: depends on script). If the project lacks a deployment-tracking convention, suggest one in the report (don't impose).

## What this command does NOT do

- Does not modify the deploy script
- Does not run tests (`/test-foundry` or `/test-hardhat` first if you want pre-deploy testing)
- Does not auto-verify on Blockscout — that's `/verify-contract`
- Does not handle multi-contract orchestration with CREATE2 sequencing — that's design territory; spawn `syscoin-architect`
- Does not auto-fund the deployer

## Examples

| Invocation | Behavior |
|------------|----------|
| `/deploy` | Defaults to `tanenbaum`, prompts for yes/no |
| `/deploy tanenbaum` | Same as above, explicit |
| `/deploy localhost` | Deploys to local node (Anvil/Hardhat Network) |
| `/deploy nevm` | **Mainnet** — requires typed literal confirmation |
| `/deploy tanenbaum --slow` | Forwards `--slow` (Foundry) for sequential broadcasting |

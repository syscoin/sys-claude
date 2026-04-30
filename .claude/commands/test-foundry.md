---
name: test-foundry
description: Run Foundry tests with verbose-on-failure output. Forwards args to `forge test`.
argument-hint: "[forge test args]"
---

# /test-foundry

Run the Foundry test suite for this project.

## Steps

### 1. Verify Foundry project

Check the project root for `foundry.toml`. If missing, stop and report:

> No `foundry.toml` found. This is not a Foundry project. If you're using Hardhat, run `/test-hardhat` instead.

### 2. Run tests

Run:

```bash
forge test -vvv $ARGUMENTS
```

Why `-vvv`: shows revert reasons, `console2.log` output, and stack traces on failure — but stays terse on success. Users wanting deeper traces can pass `-vvvv` or `-vvvvv` themselves.

### 3. Report

**On success:**
- Total test count
- Pass count, skipped count
- Total wall time
- If `$ARGUMENTS` contained `--gas-report`, summarize the gas table (top 5 by avg cost, plus any function over 100k gas)

**On failure:**
- Failing test names with their contract path (`test/Vault.t.sol::test_deposit_revertsOnZero`)
- Revert reason from each failure (the `[FAIL.…]` line + any expected-vs-actual diff)
- Pointer to first failure line in the source if available

Do **not** attempt to fix failing tests. If the user asks for help interpreting failures, suggest spawning `nevm-qa-engineer`.

## What this command does NOT do

- Does not modify test or contract files
- Does not deploy
- Does not build (`forge test` compiles automatically if needed)
- Does not generate new tests — that's `nevm-qa-engineer`'s job
- Does not auto-fix failures

## Examples

| Invocation | Behavior |
|------------|----------|
| `/test-foundry` | Run all tests, verbose on failure |
| `/test-foundry --match-test test_deposit` | Run only tests whose names match `test_deposit` |
| `/test-foundry --match-contract VaultTest` | Run only `VaultTest` contract tests |
| `/test-foundry --gas-report` | Run all tests + gas table |
| `/test-foundry --fork-url tanenbaum` | Run tests forking NEVM testnet (requires `[rpc_endpoints]` in `foundry.toml`) |
| `/test-foundry -vvvv` | Run with full traces (overrides default `-vvv`) |

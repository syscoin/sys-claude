---
name: test-hardhat
description: Run Hardhat tests (Chai + ethers). Forwards args to `npx hardhat test`.
argument-hint: "[hardhat test args]"
---

# /test-hardhat

Run the Hardhat test suite for this project.

## Steps

### 1. Verify Hardhat project

Check the project root for any of: `hardhat.config.ts`, `hardhat.config.js`, `hardhat.config.cts`, `hardhat.config.mts`. If none found, stop and report:

> No `hardhat.config.*` found. This is not a Hardhat project. If you're using Foundry, run `/test-foundry` instead.

### 2. Run tests

Run:

```bash
npx hardhat test $ARGUMENTS
```

Hardhat's Chai output is already verbose-on-failure by default — no extra flag needed.

If the user wants gas reporting, they can either:
- Set `REPORT_GAS=true` in the env before running, or
- Pass it explicitly: `REPORT_GAS=true /test-hardhat`

The command does not enable gas reporting by default — it adds noise on every run.

### 3. Report

**On success:**
- Total test count
- Pass count, skipped/pending count
- Total wall time
- If gas reporting was enabled, summarize the table (top 5 by avg cost, plus any function over 100k gas)

**On failure:**
- Failing `it()` titles with file path
- Assertion message and the expected-vs-actual values
- The originating line in the test file when available

Do **not** attempt to fix failing tests. If the user asks for help interpreting failures, suggest spawning `nevm-qa-engineer`.

## What this command does NOT do

- Does not modify test or contract files
- Does not deploy
- Does not run `npx hardhat compile` separately (`hardhat test` compiles automatically)
- Does not generate new tests — that's `nevm-qa-engineer`'s job
- Does not auto-fix failures

## Examples

| Invocation | Behavior |
|------------|----------|
| `/test-hardhat` | Run all tests |
| `/test-hardhat test/Vault.test.ts` | Run a specific test file |
| `/test-hardhat --grep "deposit"` | Run only tests whose names match `deposit` |
| `/test-hardhat --bail` | Stop on the first failure |
| `/test-hardhat --network tanenbaum` | Run tests against NEVM testnet (requires the network entry in `hardhat.config.*`) |
| `REPORT_GAS=true /test-hardhat` | Run with gas reporting |

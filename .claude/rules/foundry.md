---
paths:
  - "**/foundry.toml"
  - "**/*.t.sol"
  - "**/*.s.sol"
  - "**/remappings.txt"
description: Foundry configuration and workflow rules for Syscoin NEVM. Secondary framework; prefer Foundry for greenfield projects needing fuzz/invariant testing.
---

# Foundry Rules (NEVM)

Foundry is the **secondary** framework for Syscoin NEVM. Prefer it when:
- Starting greenfield and the team is comfortable with Solidity-native tests
- You need fast fuzz/invariant testing
- You want pure-Rust tooling with no JS/TS dependencies

Prefer Hardhat when following the official Syscoin deploy tutorial or integrating heavy JS/TS tooling.

Solidity-language rules live in `solidity.md`. This file covers config, tests, scripts, fuzz/invariant patterns, and NEVM-specific deploy/verify.

## Project Layout

```
.
├── foundry.toml           # Config (profiles, solc, optimizer, rpc_endpoints)
├── remappings.txt         # Dependency path aliases (optional, can live in foundry.toml)
├── src/                   # Contract sources
│   └── Vault.sol
├── test/                  # *.t.sol test files
│   └── Vault.t.sol
├── script/                # *.s.sol deploy/operational scripts (SINGULAR — not scripts/)
│   └── Deploy.s.sol
└── lib/                   # Git submodule dependencies (forge-std, openzeppelin-contracts, ...)
```

Do not commit `out/`, `cache/`, `broadcast/`. They should be in `.gitignore`.

## `foundry.toml` Template for NEVM

```toml
[profile.default]
src = "src"
test = "test"
script = "script"
out = "out"
libs = ["lib"]
solc = "0.8.24"
optimizer = true
optimizer_runs = 200
via_ir = false
remappings = [
  "forge-std/=lib/forge-std/src/",
  "@openzeppelin/=lib/openzeppelin-contracts/",
]
# Fuzzing defaults
fuzz = { runs = 256 }
invariant = { runs = 256, depth = 15, fail_on_revert = false }

[profile.ci]
fuzz = { runs = 10_000 }
invariant = { runs = 1_000, depth = 50 }

[rpc_endpoints]
tanenbaum = "${NEVM_TESTNET_RPC_URL}"
nevm = "${NEVM_RPC_URL}"

[etherscan]
tanenbaum = { key = "abc", url = "https://explorer.tanenbaum.io/api", chain = 5700 }
nevm = { key = "abc", url = "https://explorer.syscoin.org/api", chain = 57 }
```

Key NEVM-specific bits:
- `[rpc_endpoints]` — shell-substituted from `.env`. Lets you run `forge test --fork-url tanenbaum` without pasting URLs.
- `[etherscan]` — Blockscout-compatible; any non-empty `key` string works since NEVM explorers don't require real API keys.
- `[profile.ci]` overrides — crank fuzz runs in CI, keep local runs fast.

Install deps as git submodules:
```bash
forge install foundry-rs/forge-std
forge install OpenZeppelin/openzeppelin-contracts
```

## Test Pattern

```solidity
// test/Vault.t.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {Vault} from "src/Vault.sol";

contract VaultTest is Test {
    Vault vault;
    address user = makeAddr("user");

    function setUp() public {
        vault = new Vault();
        vm.deal(user, 10 ether);
    }

    function test_deposit_creditsCaller() public {
        vm.prank(user);
        vault.deposit{value: 1 ether}();
        assertEq(vault.balanceOf(user), 1 ether);
    }

    function test_deposit_zeroAmount_reverts() public {
        vm.prank(user);
        vm.expectRevert(Vault.ZeroAmount.selector);
        vault.deposit{value: 0}();
    }

    function test_deposit_emitsEvent() public {
        vm.prank(user);
        vm.expectEmit(true, true, false, true);
        emit Vault.Deposited(user, 1 ether);
        vault.deposit{value: 1 ether}();
    }
}
```

Key idioms:
- `setUp()` runs before every test — Foundry snapshots and rewinds for free, just like Hardhat fixtures.
- `makeAddr("label")` generates a labeled address (shows up in traces as the label, not a raw hex).
- `vm.prank(user)` — next call is from `user`. `vm.startPrank(user)` / `vm.stopPrank()` for multiple calls.
- `vm.deal(addr, amount)` — sets `addr`'s native SYS balance.
- Custom errors: `vm.expectRevert(Vault.ZeroAmount.selector)`. For args: `vm.expectRevert(abi.encodeWithSelector(Vault.InsufficientBalance.selector, 0, 1 ether))`.
- Events: `vm.expectEmit(indexed1, indexed2, indexed3, data)` flags which fields to match.

Run: `forge test -vvv` (3 v's shows logs on failure; 4 shows all logs; 5 adds traces).

## Fuzz Testing

Foundry auto-fuzzes any test function with parameters:

```solidity
function testFuzz_deposit_creditsAnyAmount(uint128 amount) public {
    vm.assume(amount > 0);
    vm.deal(user, amount);
    vm.prank(user);
    vault.deposit{value: amount}();
    assertEq(vault.balanceOf(user), amount);
}
```

- Use `vm.assume(condition)` to discard uninteresting inputs (not `require`, which would revert the test).
- Prefer bounded types (`uint128` not `uint256`) when the full range is irrelevant — more meaningful fuzz runs.
- Use `bound(x, min, max)` to coerce inputs into valid ranges without discarding runs.

## Invariant Testing

```solidity
contract VaultInvariantTest is Test {
    Vault vault;
    Handler handler;

    function setUp() public {
        vault = new Vault();
        handler = new Handler(vault);
        targetContract(address(handler));
    }

    function invariant_totalDepositsEqualsSum() public view {
        assertEq(vault.totalDeposits(), handler.ghost_sumDeposits());
    }
}
```

The `Handler` contract wraps the target with constraints (e.g. caps amounts, tracks ghost state). Invariants run many random sequences of handler calls and assert the property still holds. Use for conservation laws (sums, balances, ownership).

## Deploy Script

```solidity
// script/Deploy.s.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {Vault} from "src/Vault.sol";

contract DeployScript is Script {
    function run() external returns (Vault vault) {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);
        vault = new Vault();
        vm.stopBroadcast();
        console2.log("Vault deployed at", address(vault));
    }
}
```

Run on testnet — deploy first, verify separately (NEVM blocks take ~2.5 min; the indexer races the tx):
```bash
# Step 1: deploy
forge script script/Deploy.s.sol \
  --rpc-url tanenbaum \
  --broadcast

# Step 2: wait 2-3 min, then verify
forge verify-contract <address> src/Vault.sol:Vault \
  --chain 5700 \
  --verifier blockscout \
  --verifier-url https://explorer.tanenbaum.io/api
```

If the API rejects verification, generate the Standard JSON and upload via the explorer UI:
```bash
forge verify-contract <address> src/Vault.sol:Vault \
  --chain 5700 \
  --verifier blockscout \
  --verifier-url https://explorer.tanenbaum.io/api \
  --show-standard-json-input > verification.json
```

For mainnet (`nevm`), swap the URLs and **add typed confirmation** (the PreToolUse hook in `settings.json` requires `DEPLOY TO NEVM MAINNET` before `forge script --broadcast` runs).

## Cast (Command-Line Interaction)

```bash
# Read contract state
cast call 0xVault "balanceOf(address)(uint256)" 0xUser --rpc-url tanenbaum

# Send a transaction
cast send 0xVault "deposit()" --value 1ether --private-key $PRIVATE_KEY --rpc-url tanenbaum

# Decode calldata
cast 4byte-decode 0xa9059cbb0000000000000000000000000123...

# Generate storage slot
cast keccak "balances"

# Get current block
cast block-number --rpc-url tanenbaum
```

`cast` is for throwaway interaction and debugging. For repeatable operations, write a script.

## Anvil (Local Dev)

```bash
# Local NEVM-like chain (defaults to chain ID 31337)
anvil

# Fork NEVM mainnet for realistic local testing
anvil --fork-url https://rpc.syscoin.org --fork-block-number 3000000
```

Anvil gives 10 funded accounts on startup. Use `--fork-url` to get live-state for integration testing without mainnet risk. Pin `--fork-block-number` for determinism.

## Fork Testing

```solidity
contract ForkTest is Test {
    uint256 nevmFork;

    function setUp() public {
        nevmFork = vm.createSelectFork(vm.rpcUrl("nevm"), 3_000_000);
    }

    function test_liveState() public {
        // Contracts and balances reflect NEVM at block 3_000_000
    }
}
```

Pin the block number or tests become non-deterministic. Use `vm.makePersistent(addr)` to keep state across fork switches if testing cross-chain flows.

## Pitfalls

| Mistake | Consequence |
|---------|-------------|
| `script/` vs `scripts/` confusion | Foundry uses singular; typing plural silently creates wrong structure |
| Using `require` instead of `vm.assume` in fuzz | Wastes fuzz runs on rejected inputs |
| Missing `vm.startBroadcast` in deploy script | Script runs but nothing deploys to chain |
| `--broadcast` without `--verify` | Contract deployed but unverified; separate re-verify step later |
| Unpinned `--fork-block-number` | Non-deterministic tests |
| Invariants with `fail_on_revert = true` by default | Handler reverts count as failures; usually you want `false` |
| Forgetting `forge install <dep>` uses submodules | New clone with `--recurse-submodules=false` leaves `lib/` empty |
| Hardcoding addresses in tests | Use `makeAddr("label")` for readable traces |
| `forge test` without `-vvv` | Revert reasons hidden; always run verbose on failures |
| Mixing Hardhat and Foundry deps without aligning solc | `foundry.toml` and `hardhat.config.ts` must use the same compiler version |

## Syscoin-Specific Notes

- NEVM verification via Blockscout: use `--verifier blockscout --verifier-url https://explorer.tanenbaum.io/api` (or `https://explorer.syscoin.org/api` for mainnet). API keys are not required; any non-empty string works for `[etherscan]` in `foundry.toml`.
- **Verification timing**: `--verify` on `forge script` races NEVM's ~2.5 min block time and will often fail with "not a smart contract". Always deploy and verify as separate steps with a wait in between.
- `forge install` and `forge update` pin submodules at commit hashes — commit the submodule pointer after updating.
- Foundry reads `.env` from the project root (where `foundry.toml` lives). If the Foundry project is in a subdirectory, symlink the parent `.env` into it: `ln -sf "../.env" <project>/.env`.
- Public NEVM RPC is rate-limited. For CI invariant runs (`[profile.ci]`), configure a paid RPC endpoint in `[rpc_endpoints]`.

## Mixing with Hardhat (Dual-Framework Projects)

Both rules (`hardhat.md` + `foundry.md`) coexist in this config. If a project uses both:
- Put Solidity sources in a location both can read (Foundry `src/` = Hardhat `contracts/` — use symlinks or aligned paths).
- Keep the solc version identical in `foundry.toml` and `hardhat.config.ts` or verification artifacts diverge.
- Use Foundry for fuzzing/invariants; Hardhat for deploy scripts and JS-heavy tooling. Don't duplicate test coverage.

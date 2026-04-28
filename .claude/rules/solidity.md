---
paths: ["**/*.sol"]
description: Solidity language rules for NEVM contracts — framework-agnostic. Loaded when Claude reads any .sol file.
---

# Solidity Rules (NEVM)

These rules apply to every `.sol` file regardless of framework (Hardhat, Foundry, Remix). Framework-specific conventions live in `hardhat.md` / `foundry.md`.

Syscoin NEVM is fully EVM-compatible — standard Solidity works unchanged. The only NEVM-specific facts a contract author needs:

| Parameter | Mainnet | Testnet (Tanenbaum) |
|-----------|---------|---------------------|
| Chain ID  | 57      | 5700                |
| RPC URL   | https://rpc.syscoin.org | https://rpc.tanenbaum.io |
| Explorer  | https://explorer.syscoin.org (Blockscout-compatible) | https://tanenbaum.io |
| Faucet    | —       | https://faucet.tanenbaum.io |

Everything else below is standard Solidity discipline.

## Compiler & Pragma

- Pin the compiler version explicitly — never use `^` or `>=` ranges in production: `pragma solidity 0.8.24;`
- Target a modern version (0.8.20+) unless a specific dep forces older. 0.8.x has built-in over/underflow checks; pre-0.8 requires `SafeMath`.
- Set `optimizer: { enabled: true, runs: 200 }` by default; raise `runs` for frequently-called code, lower for one-shot deploys.
- Enable `viaIR` only when you hit "stack too deep" — it's slower to compile.

## Visibility & Mutability

- Be explicit about visibility on every function and state variable. Never rely on the default.
- Prefer `external` over `public` for functions called only from outside — cheaper gas on calldata.
- Mark state variables `immutable` when set once in the constructor; `constant` when known at compile time. Both save storage reads.
- Use `private` by default for state; promote to `internal` only when a child contract needs it.

## Errors & Reverts

- Use **custom errors** over `require(..., "string")`. Custom errors are cheaper and let the ABI encode args.
  ```solidity
  error InsufficientBalance(uint256 available, uint256 required);
  if (balance < amount) revert InsufficientBalance(balance, amount);
  ```
- Reserve `require` for simple boolean guards on external inputs when gas doesn't matter. Never do `require(success, string)` after a low-level call — use `if (!success) revert X();`.
- `assert` is for invariants that must never be false. It consumes all remaining gas pre-0.8.x — don't use it for input validation.

## Access Control

- Use OpenZeppelin's `Ownable` / `AccessControl` rather than rolling your own. If you must roll your own, use a 2-step ownership transfer (propose + accept).
- **Never** authorize with `tx.origin`. Always use `msg.sender`. `tx.origin` breaks under phishing via malicious contracts.
- Gate admin functions with modifiers, not inline checks — easier to audit.
- Consider timelocks on privileged functions that can brick or drain a contract.

## External Calls & Reentrancy

- Follow **Checks → Effects → Interactions** order:
  1. Validate inputs (checks)
  2. Update state (effects)
  3. Call external contracts (interactions)
- Use OpenZeppelin's `ReentrancyGuard` for functions that make external calls, transfer ETH, or interact with untrusted tokens.
- Never trust the return value of a low-level `.call` without checking `success`. Use `SafeERC20` for ERC-20 transfers — some tokens don't return a bool.
- Avoid `.transfer()` and `.send()` on ETH (2300 gas stipend breaks with proxies/multisigs). Use `.call{value: ...}("")` and check the return.

## Arithmetic

- 0.8.x checks over/underflow automatically — don't wrap in `SafeMath`.
- Use `unchecked { }` blocks **only** when you've proven no overflow is possible (e.g. `for` loop counters bounded by array length) and you need the gas.
- Integer division truncates. Order of operations matters: `(a * b) / c`, not `(a / c) * b`, unless you need to cap the intermediate.

## Tokens

- ERC-20: use **OpenZeppelin's `SafeERC20`** for transfers from arbitrary tokens. Handles non-compliant tokens that don't return bool or return false on success.
- Never assume `balanceOf` equals the amount you just deposited — fee-on-transfer tokens take a cut. Compute `balanceAfter - balanceBefore` when correctness matters.
- ERC-721 / ERC-1155: use `safeTransferFrom` only when the recipient is a contract that implements the receiver hook. For EOAs, `transferFrom` is fine.

## Storage Layout

- Order state variables from largest to smallest within a struct/contract to enable packing. Two `uint128`s share a slot; a `uint128` next to a `uint256` wastes 16 bytes.
- Mark rarely-changed values `immutable` when possible — they live in contract bytecode, not storage.
- Avoid dynamic arrays of structs with strings inside — expensive to iterate and prone to DoS via length.

## Events

- Emit an event for every state-changing action. Indexers rely on this.
- Index up to 3 parameters per event (`indexed`). Put addresses and IDs in `indexed` slots for filter-ability.
- Don't emit secrets — events are public forever.

## Proxy / Upgradeable Contracts

- Use OpenZeppelin's `TransparentUpgradeableProxy` or `UUPSUpgradeable`, not hand-rolled `delegatecall` patterns.
- Never declare state variables in a proxy contract itself. Storage collisions brick the contract.
- Initialize via `initializer` functions, not constructors. Add `_disableInitializers()` in the constructor of implementation contracts.
- Test upgrades with `@openzeppelin/hardhat-upgrades` or Foundry's upgrade tooling; storage layout diffs are the #1 source of bugs.

## NatSpec

Document every external/public function:

```solidity
/// @notice Deposits SYS into the user's vault balance.
/// @dev Requires caller to have approved `amount` on the token first.
/// @param token The ERC-20 token to deposit.
/// @param amount The amount in the token's smallest unit.
/// @return newBalance The user's vault balance after the deposit.
function deposit(address token, uint256 amount) external returns (uint256 newBalance);
```

- `@notice` is user-facing (shown in wallets). Write for end users.
- `@dev` is for developers integrating with this contract.
- Document every error with `@notice`: `/// @notice Thrown when the caller is not the owner.`

## Style

- One contract per file. Filename matches contract name (`Vault.sol` → `contract Vault`).
- Function order: constructor → receive → fallback → external → public → internal → private. Views/pures last within each group.
- Events declared at the top of the contract, errors just below.
- Use SPDX license identifier on the first line: `// SPDX-License-Identifier: MIT`.

## Anti-patterns (reject on sight)

| Don't | Why |
|-------|-----|
| `tx.origin` for auth | Phishing via malicious contracts |
| `block.timestamp` for randomness | Miner-manipulable |
| `blockhash(block.number - 1)` for randomness | Same |
| Unbounded loops over user-supplied arrays | DoS risk |
| `selfdestruct` | Deprecated in 0.8.x; Cancun removes the refund |
| Inline assembly without extensive comments | Hard to audit |
| Hardcoded addresses without constants | Unverifiable magic values |
| `public` state variables when `external` getter would suffice | Forces internal vs external visibility confusion |

## Syscoin NEVM — deployment verification

Block explorer verification uses Blockscout-compatible endpoints (`/api`), not Etherscan. For Hardhat, use `@nomicfoundation/hardhat-verify` with a `customChains` entry. For Foundry, pass `--verifier blockscout --verifier-url`. Verification is expected as part of every public deployment.

## NEVM block-time semantics

NEVM block time is **~2.5 minutes** (PoW merge-mined with Bitcoin), versus Ethereum's ~12 seconds. Practical consequences for time-based logic:

- `block.timestamp` advances slowly. Cooldowns, vesting cliffs, auction windows feel chunkier than on Ethereum.
- Use `block.timestamp` directly for time gates; do **not** use `block.number * average_block_time` — block intervals are variable.
- Tests that simulate time passing should use `vm.warp()` (Foundry) or `time.increase()` (Hardhat helpers), not loops over `mine`.
- Effective finality is fast via Chainlocks (masternode-signed checkpoints), but raw block confirmations are slow. Don't hardcode "wait N blocks" patterns lifted from Ethereum guides.

---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.mts"
  - "**/*.cts"
description: TypeScript rules for NEVM client/app code — Ethers v6 primary, Viem secondary, wagmi for React. Loaded on any TS file.
---

# TypeScript Rules (NEVM Client Code)

Applies to frontend, backend, and integration code that interacts with NEVM. Overlaps intentionally with `hardhat.md` for dev-time TS (scripts, tests) — they cover different layers.

## Type Safety

### Never `any`

```typescript
// ❌
function process(data: any) { return data.value; }

// ✅
interface VaultState { balance: bigint; owner: `0x${string}` }
function process(data: VaultState): bigint { return data.balance; }
```

- Use `unknown` at trust boundaries (JSON parse, RPC response, user input) and narrow with type guards before use.
- Use template literal types for addresses: `` `0x${string}` `` (ethers and viem both export this).
- Explicit return types on every exported function — lets `tsc` catch regressions at the call site.

### `import type` for type-only imports

```typescript
import type { Contract, BaseContract } from "ethers";
import { ethers } from "ethers"; // runtime
```

Prevents type imports from bloating runtime bundles.

## NEVM Chain Constants

Centralize in one file, import everywhere:

```typescript
// src/chains.ts
export const NEVM_MAINNET = {
  id: 57,
  name: "Syscoin Mainnet",
  nativeCurrency: { name: "Syscoin", symbol: "SYS", decimals: 18 },
  rpcUrls: { default: { http: ["https://rpc.syscoin.org"] } },
  blockExplorers: { default: { name: "Syscoin Explorer", url: "https://explorer.syscoin.org" } },
} as const;

export const NEVM_TESTNET = {
  id: 5700,
  name: "Syscoin Tanenbaum Testnet",
  nativeCurrency: { name: "Testnet SYS", symbol: "tSYS", decimals: 18 },
  rpcUrls: { default: { http: ["https://rpc.tanenbaum.io"] } },
  blockExplorers: { default: { name: "Tanenbaum Explorer", url: "https://tanenbaum.io" } },
} as const;
```

Use `as const` so the object becomes a literal type (e.g. `id: 57` not `id: number`). Tooling (wagmi, viem) requires literal chain IDs.

## Ethers v6 (Primary)

### Provider

```typescript
import { JsonRpcProvider } from "ethers";

const provider = new JsonRpcProvider("https://rpc.syscoin.org", { chainId: 57, name: "nevm" });
```

Pass chainId/name explicitly — skips the startup `eth_chainId` round-trip and makes errors clearer on misconfig.

### Contract Reads

```typescript
import { Contract } from "ethers";
import { vaultAbi } from "./abis";

const vault = new Contract(VAULT_ADDRESS, vaultAbi, provider);
const balance: bigint = await vault.balanceOf(userAddress);
```

Use typechain-generated types for real projects — `Vault__factory.connect(address, signer)` gives you a typed `Vault` contract instance.

### Sending Transactions

Always follow this flow:

```typescript
async function deposit(vault: Vault, amount: bigint): Promise<string> {
  // 1. Static call first — reverts locally without gas cost
  await vault.deposit.staticCall({ value: amount });

  // 2. Estimate gas (optional; ethers auto-estimates, but explicit catches issues)
  const gasLimit = await vault.deposit.estimateGas({ value: amount });

  // 3. Send
  const tx = await vault.deposit({ value: amount, gasLimit: (gasLimit * 120n) / 100n });

  // 4. Wait
  const receipt = await tx.wait();
  if (!receipt || receipt.status !== 1) throw new Error("Transaction reverted");

  return receipt.hash;
}
```

- `staticCall` catches reverts without broadcasting. Do this before `.send` when UX matters.
- `tx.wait()` returns `TransactionReceipt | null`. Null means the tx was replaced or dropped — always handle it.
- Buffer gas by 20% (`gasLimit * 120n / 100n`) for reliability. Syscoin NEVM gas is cheap; the safety margin is worth it.

## Viem (Secondary)

For projects that prefer Viem:

```typescript
import { createPublicClient, createWalletClient, custom, http } from "viem";
import { NEVM_MAINNET } from "./chains";

const publicClient = createPublicClient({ chain: NEVM_MAINNET, transport: http() });
const walletClient = createWalletClient({ chain: NEVM_MAINNET, transport: custom(window.ethereum!) });

const balance = await publicClient.readContract({
  address: VAULT_ADDRESS,
  abi: vaultAbi,
  functionName: "balanceOf",
  args: [userAddress],
});
```

Viem has better type inference for ABIs than ethers v6. If the project is greenfield and the team is comfortable, prefer Viem. If the project uses Hardhat's ecosystem, ethers v6 is the path of least resistance.

## wagmi (React)

```typescript
import { WagmiProvider, createConfig, http } from "wagmi";
import { NEVM_MAINNET, NEVM_TESTNET } from "./chains";
import { injected } from "wagmi/connectors";

export const wagmiConfig = createConfig({
  chains: [NEVM_MAINNET, NEVM_TESTNET],
  connectors: [injected()],
  transports: {
    [NEVM_MAINNET.id]: http(),
    [NEVM_TESTNET.id]: http(),
  },
});
```

Use the typed hooks — `useReadContract`, `useWriteContract`, `useAccount`, `useBalance`. Don't hand-roll provider state in React; wagmi + TanStack Query handles caching, invalidation, and subscriptions.

## BigInt Discipline

All on-chain numeric types map to `bigint` in TypeScript. Never convert to `number` until the final display step.

```typescript
// ❌ Precision loss for large values
const amount = Number(await vault.balanceOf(user));

// ✅ Keep as bigint, format only for display
import { formatEther, parseEther } from "ethers";
const raw: bigint = await vault.balanceOf(user);
const display: string = formatEther(raw); // "1.234"
const input: bigint = parseEther("1.5"); // 1500000000000000000n
```

- Arithmetic: use `bigint` operators (`+`, `-`, `*`, `/`). Mixing `bigint` and `number` throws `TypeError`.
- Division truncates: `5n / 2n === 2n`. For fractions, multiply numerator by a scale factor first.
- JSON: `bigint` is **not** JSON-serializable by default. Use `toString()` on the way out, `BigInt(str)` on the way in.

## RPC Efficiency

### Batch reads with multicall

```typescript
import { Multicall3__factory } from "./typechain-types";

const multicall = Multicall3__factory.connect(MULTICALL_ADDRESS, provider);
const results = await multicall.aggregate3([
  { target: vaultA, allowFailure: false, callData: vaultAbi.encodeFunctionData("balanceOf", [user]) },
  { target: vaultB, allowFailure: false, callData: vaultAbi.encodeFunctionData("balanceOf", [user]) },
]);
```

One RPC call instead of N. Worth it when reading ≥3 contract states. Multicall3 is deployed at `0xcA11bde05977b3631167028862bE2a173976CA11` on most EVM chains — verify deployment on NEVM before using.

### Avoid `Promise.all` over many RPC calls

```typescript
// ❌ Fires N concurrent requests; public RPCs rate-limit
const balances = await Promise.all(users.map((u) => vault.balanceOf(u)));

// ✅ Multicall or sequential batched reads
```

Public NEVM RPC (`rpc.syscoin.org`) is shared and rate-limited. For heavy workloads, configure Alchemy/QuickNode and point `NEVM_RPC_URL` there.

## Wallet Connection (Pali + MetaMask)

Syscoin users often have **both** Pali Wallet and MetaMask installed. Both inject `window.ethereum`; the last one loaded wins unless the dApp explicitly picks.

```typescript
// EIP-6963: multi-provider discovery (preferred)
window.addEventListener("eip6963:announceProvider", (e: any) => {
  const { info, provider } = e.detail;
  // info.name === "Pali" | "MetaMask" | ...
  // info.uuid is stable per wallet install
});
window.dispatchEvent(new Event("eip6963:requestProvider"));
```

Use EIP-6963 discovery for multi-wallet UX. Libraries like `@web3-onboard/core` or wagmi's `injected` connector handle this. Falling back to bare `window.ethereum` picks whichever wallet injected last — fine for single-wallet users, confusing otherwise.

Pali is UTXO + NEVM dual-mode. MetaMask is NEVM-only. If the feature needs UTXO RPC, route through Pali explicitly (it exposes additional `sys_*` methods).

## Error Mapping

RPC errors arrive as opaque strings. Map to user-facing messages at the presentation layer:

```typescript
function userError(err: unknown): string {
  if (!(err instanceof Error)) return "Unknown error";
  const msg = err.message.toLowerCase();
  if (msg.includes("user rejected") || msg.includes("user denied")) return "Transaction rejected in wallet";
  if (msg.includes("insufficient funds")) return "Not enough SYS to cover gas";
  if (msg.includes("nonce too low")) return "Please retry — previous transaction still pending";
  if (msg.includes("replacement fee too low")) return "Gas price too low to replace pending tx";
  return "Transaction failed — check the explorer for details";
}
```

For custom errors thrown by contracts, decode the revert data:

```typescript
import { Interface } from "ethers";
const iface = new Interface(vaultAbi);
try {
  await vault.withdraw(amount);
} catch (err: any) {
  if (err.data) {
    const decoded = iface.parseError(err.data);
    // decoded.name, decoded.args
  }
}
```

## Pitfalls

| Mistake | Consequence |
|---------|-------------|
| `Number(bigint)` for token amounts | Silent precision loss above 2^53 |
| Missing `chainId` in provider config | Wrong-chain writes; funds lost if dangerous |
| `Promise.all` over many contract reads | Rate-limited; requests drop |
| Forgetting `await tx.wait()` | "Success" toast before the tx is actually mined |
| Trusting `receipt.status` alone | `null` receipt means replaced/dropped, not success |
| Hardcoding RPC URLs in multiple files | Drifts out of sync; centralize in `chains.ts` |
| Using `any` for RPC responses | Defeats the whole point of TS |
| Assuming `window.ethereum` is one wallet | Pali + MetaMask both inject; use EIP-6963 |
| Decimals hardcoded as 18 | True for SYS and most ERC-20s; some tokens use 6 or 8 |
| `parseEther("1.5")` used on non-18-decimal tokens | Wrong scale by orders of magnitude — use `parseUnits(value, decimals)` |

## Project Scaffolding

- Greenfield dApp: `pnpm create next-app` + wagmi + viem + ConnectKit/RainbowKit
- Greenfield node script: `npm init` + ethers v6 + dotenv
- Use `tsconfig.json` `"strict": true` and `"noUncheckedIndexedAccess": true` — both catch classes of NEVM bugs (undefined array lookups for missing tokens/accounts).

**Remember**: ethers or viem — pick one per package, don't mix. The types don't interop.

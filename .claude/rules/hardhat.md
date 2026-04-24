---
paths:
  - "**/hardhat.config.{ts,js,cts,mts}"
  - "**/scripts/**/*.{ts,js}"
  - "**/tasks/**/*.{ts,js}"
  - "**/test/**/*.{ts,js}"
description: Hardhat configuration and workflow rules for Syscoin NEVM projects. Primary framework per Syscoin's official docs.
---

# Hardhat Rules (NEVM)

Hardhat is the **primary** framework for Syscoin NEVM per the official docs. If this file loaded, the project is using Hardhat (or mixing Hardhat + Foundry — both rules attach).

Solidity-language rules live in `solidity.md`. This file is about config, scripts, tests, deploys, and verification.

## Project Layout

```
.
├── hardhat.config.ts      # Config (pin chain IDs, networks, verifier)
├── contracts/             # .sol sources
├── scripts/               # Deploy / operational scripts (ts/js)
│   └── deploy.ts
├── tasks/                 # Custom `task()` definitions (optional)
├── test/                  # Chai-style tests (ts/js)
└── .env                   # RPC URLs + PRIVATE_KEY (never committed)
```

Do not commit `artifacts/`, `cache/`, `typechain-types/`. They should be in `.gitignore`.

## Canonical Plugin Set

Install once:

```bash
npm i -D hardhat @nomicfoundation/hardhat-toolbox @nomicfoundation/hardhat-verify dotenv
```

`hardhat-toolbox` already bundles: `hardhat-ethers`, `hardhat-chai-matchers`, `hardhat-network-helpers`, `typechain`, `hardhat-gas-reporter`, `solidity-coverage`. Don't install those individually.

## `hardhat.config.ts` Template for NEVM

```typescript
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
import "dotenv/config";

const PRIVATE_KEY = process.env.PRIVATE_KEY ?? "";
const NEVM_RPC_URL = process.env.NEVM_RPC_URL ?? "https://rpc.syscoin.org";
const NEVM_TESTNET_RPC_URL = process.env.NEVM_TESTNET_RPC_URL ?? "https://rpc.tanenbaum.io";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: { enabled: true, runs: 200 },
      viaIR: false,
    },
  },
  networks: {
    hardhat: {
      chainId: 31337,
    },
    tanenbaum: {
      url: NEVM_TESTNET_RPC_URL,
      chainId: 5700,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    nevm: {
      url: NEVM_RPC_URL,
      chainId: 57,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
  },
  etherscan: {
    // NEVM explorers are Blockscout-compatible; hardhat-verify supports them
    // via customChains.
    apiKey: {
      tanenbaum: "abc",       // Blockscout doesn't require a real key
      nevm: "abc",
    },
    customChains: [
      {
        network: "tanenbaum",
        chainId: 5700,
        urls: {
          apiURL: "https://tanenbaum.io/api",
          browserURL: "https://tanenbaum.io",
        },
      },
      {
        network: "nevm",
        chainId: 57,
        urls: {
          apiURL: "https://explorer.syscoin.org/api",
          browserURL: "https://explorer.syscoin.org",
        },
      },
    ],
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS === "true",
    currency: "USD",
  },
  typechain: {
    outDir: "typechain-types",
    target: "ethers-v6",
  },
};

export default config;
```

Network naming: use **`tanenbaum`** for testnet and **`nevm`** for mainnet. Avoid `mainnet` as a key — that name is reserved-feeling and makes deploy commands dangerously ambiguous in error messages.

## Deploy Script Pattern

```typescript
// scripts/deploy.ts
import { ethers, network, run } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying on ${network.name} with ${deployer.address}`);
  console.log(`Balance: ${ethers.formatEther(await ethers.provider.getBalance(deployer.address))} SYS`);

  const Vault = await ethers.getContractFactory("Vault");
  const vault = await Vault.deploy(/* constructor args */);
  await vault.waitForDeployment();

  const address = await vault.getAddress();
  console.log(`Vault deployed: ${address}`);

  // Verify on explorer (wait a few blocks first)
  if (network.name === "tanenbaum" || network.name === "nevm") {
    console.log("Waiting 30s before verification...");
    await new Promise((r) => setTimeout(r, 30_000));
    await run("verify:verify", {
      address,
      constructorArguments: [],
    });
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
```

Run: `npx hardhat run scripts/deploy.ts --network tanenbaum`

**Never** deploy to `nevm` (mainnet) without user confirmation — the PreToolUse hook in `.claude/settings.json` enforces this, but the script itself should log prominently which network it's using.

## Test Pattern (Chai + ethers v6)

```typescript
// test/Vault.test.ts
import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

describe("Vault", () => {
  async function deployFixture() {
    const [owner, user] = await ethers.getSigners();
    const Vault = await ethers.getContractFactory("Vault");
    const vault = await Vault.deploy();
    return { vault, owner, user };
  }

  it("credits deposits to the caller", async () => {
    const { vault, user } = await loadFixture(deployFixture);
    await expect(vault.connect(user).deposit({ value: ethers.parseEther("1") }))
      .to.emit(vault, "Deposited")
      .withArgs(user.address, ethers.parseEther("1"));

    expect(await vault.balanceOf(user.address)).to.equal(ethers.parseEther("1"));
  });

  it("reverts with custom error on zero deposit", async () => {
    const { vault, user } = await loadFixture(deployFixture);
    await expect(vault.connect(user).deposit({ value: 0n }))
      .to.be.revertedWithCustomError(vault, "ZeroAmount");
  });
});
```

- **`loadFixture`** resets EVM state between tests for free (snapshot/revert). Never redeploy in each `it` — it's 10x slower.
- Assert custom errors with `revertedWithCustomError(contract, "Name")`, not `revertedWith("string")`.
- Use `bigint` literals (`1n`, `ethers.parseEther("1")`) — ethers v6 switched from `BigNumber` to native `bigint`.

## Fork Testing NEVM

To test against live NEVM state without mainnet risk:

```typescript
// hardhat.config.ts networks block
hardhat: {
  chainId: 57,
  forking: {
    url: process.env.NEVM_RPC_URL ?? "https://rpc.syscoin.org",
    blockNumber: 3_000_000, // pin for reproducible tests
  },
},
```

Run `npx hardhat test` — the in-memory fork reads state from the pinned block but executes your tx locally. Do **not** leave `blockNumber` unpinned; unpinned forks change every run and destroy test determinism.

## Verification

```bash
npx hardhat verify --network tanenbaum <address> <constructor-arg-1> <constructor-arg-2>
```

For contracts with complex constructor args or libraries, use the programmatic `run("verify:verify", ...)` form shown in the deploy script. Blockscout accepts verification within minutes of deployment — wait ~30s to let the contract index first.

## Tasks (custom CLI commands)

```typescript
// tasks/balance.ts
import { task } from "hardhat/config";

task("balance", "Prints an account's SYS balance")
  .addParam("account", "The account address")
  .setAction(async (args, hre) => {
    const balance = await hre.ethers.provider.getBalance(args.account);
    console.log(`${hre.ethers.formatEther(balance)} SYS`);
  });
```

Import in `hardhat.config.ts`: `import "./tasks/balance";`. Run: `npx hardhat balance --account 0x... --network tanenbaum`.

## Pitfalls

| Mistake | Consequence |
|---------|-------------|
| `PRIVATE_KEY` committed to git | Funds drained instantly by scrapers |
| Missing `--network <name>` flag | Script runs against in-memory Hardhat Network (localhost), silently |
| Stale `artifacts/` and `cache/` | Mysterious test failures; run `npx hardhat clean` when switching branches |
| Using `ethers.BigNumber` | Deprecated in ethers v6; use native `bigint` |
| `await contract.deployed()` | Deprecated; use `await contract.waitForDeployment()` in ethers v6 |
| Calling `.deploymentTransaction().wait()` before `waitForDeployment()` | Race — txn may not be mined yet |
| Hardcoding chain IDs in tests | Use `network.config.chainId` for portability |
| Forking mainnet without pinned `blockNumber` | Non-deterministic tests |
| Forgetting `loadFixture` | Tests take minutes instead of seconds |

## Syscoin-Specific Notes

- NEVM public RPC (`https://rpc.syscoin.org`) is shared and rate-limited. For heavy CI or mainnet writes, configure a paid provider (Alchemy, QuickNode, Blast) in `.env` and point `NEVM_RPC_URL` at it.
- Explorer verification uses Blockscout's API — no real API key required; pass any non-empty string to satisfy `hardhat-verify`.
- Gas prices on NEVM are typically low but spike during heavy use. Set `gasPrice` or `maxFeePerGas` via `--gas-price` or script overrides if a deploy stalls.
- Testnet faucet: https://faucet.tanenbaum.io — request tSYS before your first testnet deploy.

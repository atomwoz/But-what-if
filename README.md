# But What If?

> _A contract that won't steal your money._
> _Probably._

---

## The Premise

Every Ethereum address is a fingerprint of a 256-bit secret.

There are roughly `2^256` private keys. That is enough room for
everyone to sleep well, ignore the math, and pretend the grave is the
only lottery they are guaranteed to win.

_But what if?_

## The Contract

`ButWhatIf` does one thing. Every time you call `whatIf(myLuckyNumber)`, it:

1. Mixes three numbers from the block and your lucky number into a seed.
2. Treats that seed as a candidate private key `k`.
3. Derives the corresponding address.
4. Checks if that address is **you**.

If it is, congratulations. You found the private key equivalent of a
loaded gun under your pillow. The contract emits
`YouWon(you, yourBalance)` and returns `"You lucky bastard ;)"`.

If it isn't — and it won't be — the contract emits
`YouLost(you, yourBalance, definitelyNotYourKeyDigest)` and
returns zero. Nothing happened. Officially.

## The Bad News

The seed is
`keccak256(block.timestamp, block.number, block.prevrandao, myLuckyNumber)`.

Every block field is public. Your lucky number is calldata. Anyone
watching the mempool can compute `candidate` for the block this
transaction lands in — _before_ it lands.

So if `whatIf(...)` ever returns `"You lucky bastard ;)"`, the caller did
not win. The bots already took the money and left the receipt.

The contract does not move funds. It does not need to. It just makes the
noise and lets the network do the work.

## The Trick

Solidity does not give you a nice way to derive an address from a raw
private key. That normally needs elliptic curve scalar multiplication on
`secp256k1`.

`ecrecover` already does the curve math. It just needs to be asked
weirdly enough:

```solidity
ecrecover(bytes32(0), 27, bytes32(GX), bytes32(mulmod(k, GX, N)))
```

The inputs are chosen so that `ecrecover` returns the public key point for
private key `k`, and Solidity then exposes the corresponding address.

## Deployment

The contract is live on Ethereum mainnet:

**[`0x2B98F183F8fc859da491d50f2A0adEcF3E225612`](https://etherscan.io/address/0x2b98f183f8fc859da491d50f2a0adecf3e225612)**

## Running It

```bash
forge build
forge test -vv
```

Two tests live in `test/ButWhatIf.t.sol`:

- **Happy path** — a normal caller misses the cosmic odds, gets zero back,
  and receives `YouLost`.
- **Extraction path** — pins block state to a known seed, reconstructs
  `candidate` offchain, derives the victim address with `vm.addr`, pranks
  as them, and gets the worst possible `"You lucky bastard ;)"`.

The second test proves the seed is public and the candidate is already
recoverable before the transaction is dead in the ground.

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

`ButWhatIf` does one thing. Every time you call `whatIf(my_lucky_number)`, it:

1. Mixes three numbers from the block and your lucky number into a seed.
2. Treats that seed as a candidate private key `k`.
3. Derives the corresponding address.
4. Checks if that address is **you**.

If it is, congratulations. You found the private key equivalent of a
loaded gun under your pillow. The contract emits
`STEAL_MY_MONEY(you, your_balance)` and returns the digest of the key
that should not have existed.

If it isn't — and it won't be — the contract emits
`WHO_GOT_LUCKY(you, your_balance, definitely_not_your_key_digest)` and
you get back the string `"You lucky bastard ;)"`.

## The Bad News

The seed is
`keccak256(block.timestamp, block.number, block.prevrandao, my_lucky_number)`.

Every block field is public. Your lucky number is calldata. Anyone
watching the mempool can compute `candidate` for the block this
transaction lands in — _before_ it lands.

So if `whatIf(...)` ever returns the digest instead of the joke, the caller
did not win. The bots already took the money and left the receipt.

The contract does not move funds. It does not need to. It just makes the
noise and lets the bots bring knives.

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

## Running It

```bash
forge build
forge test -vv
```

Two tests live in `test/ButWhatIf.t.sol`:

- **Happy path** — a normal caller misses the cosmic odds, gets the
  string back, and receives the deeply dishonest `WHO_GOT_LUCKY`.
- **Extraction path** — pins block state to a known seed, reconstructs
  `candidate` offchain, derives the victim address with `vm.addr`, pranks
  as them, and watches the bad branch light up.

The second test proves the seed is public and the candidate is already
recoverable before the transaction is dead in the ground.

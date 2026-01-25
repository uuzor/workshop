# All4One: Privacy-Preserving Anti-Majority Prediction Market

**It's not about how much you bet. It's about how few agree with you.**

## Overview

All4One is a privacy-first contrarian betting market built on Aleo where:

- Users bet privately on binary outcomes
- All votes and bet sizes remain hidden until resolution
- The **minority side wins** (by bettor count, not stake)
- Early conviction is rewarded with bonus multipliers
- Early-but-lost bettors may receive partial compensation

This creates a unique game-theoretic environment where success requires predicting what others will predict, rather than simply following the crowd.

## Why Aleo?

All4One leverages Aleo's zero-knowledge capabilities for:

| Feature | Benefit |
|---------|---------|
| Private records | Votes remain hidden until resolution |
| ZK proofs | Resolution is verifiable without revealing individual bets |
| No front-running | Impossible to see and copy winning positions |
| No bandwagoning | Can't follow the crowd if you can't see the crowd |

On EVM chains, this would require complex commit-reveal schemes. On Aleo, it's native.

## Core Mechanics

### Minority Wins (Count-Based)

```
minority = outcome with FEWER bettors (not less money)
```

- 1 whale betting 10,000 tokens = 1 vote
- 10 users betting 100 tokens each = 10 votes
- **Count matters, stake doesn't** (for winning determination)

### Time-Segmented Conviction

Markets are divided into 4 time segments with conviction weights:

| Segment | Time Range | Weight | Description |
|---------|------------|--------|-------------|
| S0 | 0-25% | 1.5x | Highest conviction (early birds) |
| S1 | 25-50% | 1.3x | Strong conviction |
| S2 | 50-75% | 1.15x | Moderate conviction |
| S3 | 75-100% | 1.0x | No bonus (late joiners) |

Early bettors get higher **effective stake** for reward distribution.

### Dual-Pool Reward Distribution

After a 2% protocol fee, the distributable pool is split:

| Pool | Share | Distribution |
|------|-------|--------------|
| Winner Base Pool | 55% | Proportional to raw stake |
| Winner Conviction Pool | 35% | Proportional to effective stake |
| Temporal Compensation | 10% | For early-but-lost bettors |

### Reward Formulas

**Base Reward:**
```
R_base = bet_amount × base_pool / minority_pool
```

**Conviction Reward:**
```
effective_stake = bet_amount × conviction_weight
R_conviction = effective_stake × conviction_pool / total_minority_effective
```

**Total Winner Reward:**
```
R_total = R_base + R_conviction
```

### Temporal Compensation

Losers who bet early AND were in the minority at their segment's end can claim partial compensation:

```
compensation_weight = bet_amount × (conviction_weight - 1.0)
compensation = min(calculated_share, 30% of original stake)
```

This rewards early conviction even when the crowd flips late.

## Program Structure

### Records (Private)

```leo
record Bet {
    owner: address,      // The bettor
    market_id: field,    // Which market
    outcome: u8,         // 0 or 1
    amount: u64,         // Bet size
    segment: u8,         // Time segment (0-3)
}

record BetCommitment {
    owner: address,      // Resolver address
    market_id: field,
    outcome: u8,
    amount: u64,
    segment: u8,
    bettor: address,     // Original bettor
}
```

### Mappings (Public)

```leo
mapping markets: field => MarketConfig;        // Market configuration
mapping market_active: field => bool;          // Accepting bets?
mapping total_pool: field => u64;              // Total staked (hidden per-outcome)
mapping resolutions: field => Resolution;      // Final results
mapping payouts: field => u64;                 // Winner payouts
mapping compensations: field => u64;           // Loser compensations
```

### Transitions

| Transition | Description |
|------------|-------------|
| `create_market` | Create a new betting market |
| `place_bet` | Place a private bet |
| `close_market` | Stop accepting bets |
| `resolve_market` | Submit aggregated results |
| `calculate_winner_payout` | Calculate winner's reward |
| `calculate_compensation` | Calculate loser's compensation |
| `claim_reward` | Winner claims payout |
| `claim_compensation` | Eligible loser claims compensation |
| `refund` | Refund for invalid markets |
| `withdraw_fees` | Protocol fee withdrawal |

## Market Lifecycle

```
1. CREATE MARKET
   └─ Set question, duration, resolver, min_bettors
   └─ 4 time segments automatically calculated

2. BETTING PHASE (Segments S0-S3)
   └─ Users place private bets
   └─ Only total pool visible, not per-outcome
   └─ Each bet creates Bet + BetCommitment records

3. CLOSE MARKET
   └─ Resolver closes market after end_block
   └─ No more bets accepted

4. RESOLVE MARKET
   └─ Resolver aggregates all BetCommitments off-chain
   └─ Submits: counts, pools, effective stakes per outcome
   └─ Minority determined by COUNT

5. CALCULATE PAYOUTS
   └─ Resolver processes each winner's BetCommitment
   └─ Records base + conviction rewards

6. CLAIM PHASE
   └─ Winners claim rewards with their Bet record
   └─ Eligible losers claim compensation
```

## Security Properties

### Whale Resistance
- Minority determined by count, not stake
- Large bets increase risk without increasing influence
- Splitting across addresses is costly and detectable

### Privacy
- Votes remain private until resolution
- Bet sizes remain private
- Only final minority outcome is public

### Anti-Sniping
- Final segment has no conviction bonus
- All votes hidden anyway
- Can't wait to see which way wind blows

### Minimum Entropy
- Markets require minimum bettors on each side
- Prevents solo minority farming
- Invalid markets trigger refunds

## Build & Run

### Prerequisites

- [Leo](https://developer.aleo.org/leo/installation) installed
- Aleo account (for testnet)

### Build

```bash
cd all4one
leo build
```

### Run Demo

```bash
chmod +x run.sh
./run.sh
```

### Test Individual Transitions

```bash
# Create market
leo run create_market \
    <question_hash>field \
    <start_block>u32 \
    <end_block>u32 \
    <resolver_address> \
    <min_bettors>u64 \
    <fee_recipient_address>

# Place bet
leo run place_bet \
    <market_id>field \
    <outcome>u8 \
    <amount>u64 \
    <resolver_address> \
    <current_block>u32

# Close market
leo run close_market <market_id>field

# Resolve market
leo run resolve_market \
    <market_id>field \
    <outcome_0_count>u64 \
    <outcome_1_count>u64 \
    <outcome_0_pool>u64 \
    <outcome_1_pool>u64 \
    <outcome_0_effective>u64 \
    <outcome_1_effective>u64
```

## Game Theory

All4One creates unique strategic dynamics:

### Second-Order Thinking
You're not predicting the outcome. You're predicting what others will predict. Success requires understanding crowd psychology.

### Contrarian Advantage
Going against your gut might be profitable. The game rewards those who correctly anticipate minority positions.

### Conviction vs. Information
Early bets get conviction bonuses but have less information. Late bets have more information but no bonus. Choose your timing wisely.

### No Herding
Without visible vote counts, there's no crowd to follow. Every bet is a genuine independent decision.

## Example Scenario

**Question:** "Will Bitcoin hit $100k by end of 2024?"

| Bettor | Segment | Outcome | Amount | Effective |
|--------|---------|---------|--------|-----------|
| Alice | S0 | YES | 100 | 150 |
| Bob | S2 | YES | 100 | 115 |
| Carol | S0 | NO | 100 | 150 |

**Result:**
- YES: 2 bettors (MAJORITY)
- NO: 1 bettor (MINORITY)

**Carol wins!** Her rewards:
- Base: 100 × (294 × 0.55) / 100 = 161.7
- Conviction: 150 × (294 × 0.35) / 150 = 102.9
- **Total: ~264.6 tokens** (2.65x return)

Alice and Bob lose their stakes. If either had been minority at their segment end but got flipped, they could claim up to 30% back from compensation pool.

## Comparison to Polymarket

| Feature | Polymarket | All4One |
|---------|------------|---------|
| Winner | Correct prediction | Minority side |
| Visibility | Transparent odds | Hidden votes |
| Strategy | Follow smart money | Contrarian thinking |
| Privacy | Public positions | ZK-hidden |
| Chain | Polygon | Aleo |

All4One isn't competing with Polymarket—it's creating a new genre of prediction market.

## License

MIT

## Contributing

Contributions welcome! Please ensure all changes maintain the privacy guarantees and game-theoretic properties of the protocol.

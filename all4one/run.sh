#!/bin/bash

# All4One: Privacy-Preserving Anti-Majority Prediction Market
# Time-Segmented Dual-Pool Reward System Demo

# Check Leo is installed
if ! command -v leo &> /dev/null
then
    echo "leo is not installed."
    exit
fi

echo "
###############################################################################
#                                                                             #
#                          ALL4ONE BETTING GAME                               #
#              Privacy-Preserving Anti-Majority Prediction Market             #
#                                                                             #
#                    Time-Segmented Dual-Pool Rewards                         #
#                                                                             #
###############################################################################

It's not about how much you bet.
It's about how few agree with you.

KEY MECHANICS:
- Minority by COUNT wins (not by stake amount)
- Early bettors get conviction bonuses
- Early-but-lost bettors may receive partial compensation
- All votes remain private until resolution

POOL DISTRIBUTION (after 2% protocol fee):
┌─────────────────────────┬───────┬──────────────────────────────────┐
│ Pool                    │ Share │ Distribution                     │
├─────────────────────────┼───────┼──────────────────────────────────┤
│ Winner Base Pool        │  55%  │ Proportional to raw stake        │
│ Winner Conviction Pool  │  35%  │ Proportional to effective stake  │
│ Temporal Compensation   │  10%  │ For early-but-lost bettors       │
└─────────────────────────┴───────┴──────────────────────────────────┘

TIME SEGMENTS & CONVICTION WEIGHTS:
┌─────────┬────────────┬────────┬────────────────────────────────────┐
│ Segment │ Time Range │ Weight │ Description                        │
├─────────┼────────────┼────────┼────────────────────────────────────┤
│   S0    │   0-25%    │  1.5x  │ Highest conviction (early birds)   │
│   S1    │  25-50%    │  1.3x  │ Strong conviction                  │
│   S2    │  50-75%    │ 1.15x  │ Moderate conviction                │
│   S3    │  75-100%   │  1.0x  │ No bonus (late joiners)            │
└─────────┴────────────┴────────┴────────────────────────────────────┘

"

echo "
DEMO PARTICIPANTS:

1. MARKET CREATOR / RESOLVER / FEE RECIPIENT
   private_key: APrivateKey1zkp8wKHF9zFX1j4YJrK3JhxtyKDmPbRu9LrnEW8Ki56UQ3G
   address: aleo1rfez44epy0m7nv4pskvjy6vex64tnt0xy90fyhrg49cwe0t9ws8sh6nhhr

2. BETTOR 1 (Segment S0, outcome 0 - YES)
   private_key: APrivateKey1zkpHmSu9zuhyuCJqVfQE8p82HXpCTLVa8Z2HUNaiy9mrug2
   address: aleo1c45etea8czkyscyqawxs7auqjz08daaagp2zq4qjydkhxt997q9s77rsp2
   Bets: 100 tokens on YES in early segment (1.5x conviction)

3. BETTOR 2 (Segment S2, outcome 0 - YES)
   private_key: APrivateKey1zkp6NHwbT7PkpnEFeBidz5ZkZ14W8WXZmJ6kjKbEHYdMmf2
   address: aleo1uc6jphye8y9gfqtezrz240ak963sdgugd7s96qpuw6k7jz9axs8q2qnhxc
   Bets: 100 tokens on YES in mid segment (1.15x conviction)

4. BETTOR 3 (Segment S0, outcome 1 - NO) <- THE MINORITY WINNER!
   private_key: APrivateKey1zkpBvpWuManMJY2NAAHzvMLx85Zt1CKJ7b64E6CqQxVdKq4
   address: aleo1whnlpcv4jzge7ch6u2xxk5l8sdprxgwt5g3w4c6s7rglwav9c5fqmgpwzq
   Bets: 100 tokens on NO in early segment (1.5x conviction)

SCENARIO:
Question: 'Will Bitcoin hit 100k by end of 2024?'
- 2 bettors say YES (Bettors 1 & 2) = MAJORITY
- 1 bettor says NO (Bettor 3) = MINORITY → WINS!
"

# ============================================
# STEP 0: CREATE MARKET
# ============================================

echo "
###############################################################################
#          STEP 0: Create a New Market with Time Segments                     #
###############################################################################

Market Parameters:
- Question: 'Will Bitcoin hit 100k by end of 2024?'
- Start Block: 1000
- End Block: 5000 (4000 blocks = 4 segments of 1000 blocks each)
- Min Bettors: 1 per side
- Protocol Fee: 2%
"

echo "
NETWORK=testnet3
PRIVATE_KEY=APrivateKey1zkp8wKHF9zFX1j4YJrK3JhxtyKDmPbRu9LrnEW8Ki56UQ3G
" > .env

echo "Running: leo run create_market <question_hash> <start_block> <end_block> <resolver> <min_bettors> <fee_recipient>"

leo run create_market \
    1234567890123456789012345678901234567890field \
    1000u32 \
    5000u32 \
    aleo1rfez44epy0m7nv4pskvjy6vex64tnt0xy90fyhrg49cwe0t9ws8sh6nhhr \
    1u64 \
    aleo1rfez44epy0m7nv4pskvjy6vex64tnt0xy90fyhrg49cwe0t9ws8sh6nhhr

echo "
✓ Market created with 4 time segments:
  - S0: Blocks 1000-1999 (1.5x conviction)
  - S1: Blocks 2000-2999 (1.3x conviction)
  - S2: Blocks 3000-3999 (1.15x conviction)
  - S3: Blocks 4000-4999 (1.0x conviction)
"

# ============================================
# STEP 1: BETTOR 1 PLACES BET (Segment S0)
# ============================================

echo "
###############################################################################
#     STEP 1: Bettor 1 Places Bet in Segment S0 (Early Bird - 1.5x)           #
###############################################################################

Bettor 1 is an early believer! They bet 100 tokens on YES at block 1500.
Their effective stake = 100 × 1.5 = 150 (for conviction rewards)
"

echo "
NETWORK=testnet3
PRIVATE_KEY=APrivateKey1zkpHmSu9zuhyuCJqVfQE8p82HXpCTLVa8Z2HUNaiy9mrug2
" > .env

leo run place_bet \
    4812435067807710567096064256851772651374938633818239070992464953921986901915field \
    0u8 \
    100u64 \
    aleo1rfez44epy0m7nv4pskvjy6vex64tnt0xy90fyhrg49cwe0t9ws8sh6nhhr \
    1500u32

echo "
✓ Bettor 1's early bet recorded privately.
  Segment: S0 (1.5x conviction weight)
  Effective Stake: 150

                  CURRENT STATE (ALL HIDDEN!)
          ┌──────────┬─────────┬────────┬───────────┐
          │ Outcome  │ Bettors │  Pool  │ Effective │
          ├──────────┼─────────┼────────┼───────────┤
          │   YES    │    ?    │   ???  │    ???    │
          │   NO     │    ?    │   ???  │    ???    │
          ├──────────┼─────────┼────────┼───────────┤
          │  TOTAL   │    1    │   100  │  (hidden) │
          └──────────┴─────────┴────────┴───────────┘
"

# ============================================
# STEP 2: BETTOR 3 PLACES BET (Segment S0, THE CONTRARIAN!)
# ============================================

echo "
###############################################################################
#     STEP 2: Bettor 3 Places Contrarian Bet in Segment S0 (1.5x)             #
###############################################################################

Bettor 3 is also an early bettor, but they're betting AGAINST the expected crowd!
They bet 100 tokens on NO at block 1800.
"

echo "
NETWORK=testnet3
PRIVATE_KEY=APrivateKey1zkpBvpWuManMJY2NAAHzvMLx85Zt1CKJ7b64E6CqQxVdKq4
" > .env

leo run place_bet \
    4812435067807710567096064256851772651374938633818239070992464953921986901915field \
    1u8 \
    100u64 \
    aleo1rfez44epy0m7nv4pskvjy6vex64tnt0xy90fyhrg49cwe0t9ws8sh6nhhr \
    1800u32

echo "
✓ Bettor 3's contrarian bet recorded privately.
  Segment: S0 (1.5x conviction weight)
  Effective Stake: 150

                  CURRENT STATE (ALL HIDDEN!)
          ┌──────────┬─────────┬────────┬───────────┐
          │ Outcome  │ Bettors │  Pool  │ Effective │
          ├──────────┼─────────┼────────┼───────────┤
          │   YES    │    ?    │   ???  │    ???    │
          │   NO     │    ?    │   ???  │    ???    │
          ├──────────┼─────────┼────────┼───────────┤
          │  TOTAL   │    2    │   200  │  (hidden) │
          └──────────┴─────────┴────────┴───────────┘
"

# ============================================
# STEP 3: BETTOR 2 PLACES BET (Segment S2)
# ============================================

echo "
###############################################################################
#      STEP 3: Bettor 2 Places Bet in Segment S2 (Later - 1.15x)              #
###############################################################################

Bettor 2 joins later at block 3500 (Segment S2).
They bet 100 tokens on YES but get less conviction bonus.
"

echo "
NETWORK=testnet3
PRIVATE_KEY=APrivateKey1zkp6NHwbT7PkpnEFeBidz5ZkZ14W8WXZmJ6kjKbEHYdMmf2
" > .env

leo run place_bet \
    4812435067807710567096064256851772651374938633818239070992464953921986901915field \
    0u8 \
    100u64 \
    aleo1rfez44epy0m7nv4pskvjy6vex64tnt0xy90fyhrg49cwe0t9ws8sh6nhhr \
    3500u32

echo "
✓ Bettor 2's late bet recorded privately.
  Segment: S2 (1.15x conviction weight)
  Effective Stake: 115

                  CURRENT STATE (STILL ALL HIDDEN!)
          ┌──────────┬─────────┬────────┬───────────┐
          │ Outcome  │ Bettors │  Pool  │ Effective │
          ├──────────┼─────────┼────────┼───────────┤
          │   YES    │    ?    │   ???  │    ???    │
          │   NO     │    ?    │   ???  │    ???    │
          ├──────────┼─────────┼────────┼───────────┤
          │  TOTAL   │    3    │   300  │  (hidden) │
          └──────────┴─────────┴────────┴───────────┘

  No one knows the vote distribution!
  No bandwagoning possible!
"

# ============================================
# STEP 4: CLOSE MARKET
# ============================================

echo "
###############################################################################
#                        STEP 4: Close the Market                             #
###############################################################################

After block 5000, the resolver closes the market.
"

echo "
NETWORK=testnet3
PRIVATE_KEY=APrivateKey1zkp8wKHF9zFX1j4YJrK3JhxtyKDmPbRu9LrnEW8Ki56UQ3G
" > .env

leo run close_market \
    4812435067807710567096064256851772651374938633818239070992464953921986901915field

echo "
✓ Market closed. No more bets accepted.
"

# ============================================
# STEP 5: RESOLVE MARKET
# ============================================

echo "
###############################################################################
#          STEP 5: Resolve Market with Full Aggregation Data                  #
###############################################################################

The resolver processes all BetCommitment records off-chain and submits:
- Count per outcome (for minority determination)
- Pool per outcome (for base rewards)
- Effective stakes per outcome (for conviction rewards)

Aggregated Data:
┌──────────┬─────────┬────────┬───────────────────────────────┐
│ Outcome  │ Bettors │  Pool  │ Effective Stake               │
├──────────┼─────────┼────────┼───────────────────────────────┤
│   YES    │    2    │   200  │ 150 (S0) + 115 (S2) = 265     │
│   NO     │    1    │   100  │ 150 (S0) = 150                │
└──────────┴─────────┴────────┴───────────────────────────────┘

MINORITY by COUNT: NO (1 bettor vs 2 bettors)
"

leo run resolve_market \
    4812435067807710567096064256851772651374938633818239070992464953921986901915field \
    2u64 \
    1u64 \
    200u64 \
    100u64 \
    265u64 \
    150u64

echo "
###############################################################################
#                       RESOLUTION COMPLETE!                                  #
###############################################################################

              FINAL RESULTS (NOW PUBLIC)
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  MINORITY OUTCOME: NO (Outcome 1)                           │
│  WINNER: Bettor 3!                                          │
│                                                             │
│  Vote Distribution:                                         │
│  ┌──────────┬─────────┬────────┬───────────┐                │
│  │ Outcome  │ Bettors │  Pool  │ Effective │                │
│  ├──────────┼─────────┼────────┼───────────┤                │
│  │   YES    │    2    │   200  │    265    │  <- MAJORITY   │
│  │   NO     │    1    │   100  │    150    │  <- MINORITY   │
│  └──────────┴─────────┴────────┴───────────┘                │
│                                                             │
└─────────────────────────────────────────────────────────────┘

REWARD CALCULATION:

Total Pool: 300 tokens
Protocol Fee (2%): 6 tokens
Distributable Pool: 294 tokens

┌─────────────────────────┬────────┬───────────────────────────┐
│ Pool                    │ Amount │ Formula                   │
├─────────────────────────┼────────┼───────────────────────────┤
│ Winner Base (55%)       │ 161.7  │ 294 × 0.55                │
│ Winner Conviction (35%) │ 102.9  │ 294 × 0.35                │
│ Temporal Compensation   │  29.4  │ 294 × 0.10                │
└─────────────────────────┴────────┴───────────────────────────┘

BETTOR 3'S REWARDS (the only minority winner):

Base Reward:
  = 100 × 161.7 / 100 = 161.7 tokens

Conviction Reward:
  = 150 × 102.9 / 150 = 102.9 tokens
  (Full 35% because they're the only minority bettor!)

TOTAL PAYOUT: ~264.6 tokens

Bettor 3 bet 100 tokens and wins ~265 tokens (2.65x return)!

The early conviction bonus (1.5x) gave them maximum conviction rewards!
"

# ============================================
# TEMPORAL COMPENSATION EXPLANATION
# ============================================

echo "
###############################################################################
#                    TEMPORAL COMPENSATION (For Future Reference)             #
###############################################################################

In this scenario, Bettors 1 & 2 lost (they bet on majority).

COULD they get temporal compensation?

Bettor 1 (S0, YES):
- Bet early (S0) ✓
- Was their outcome minority at S0 end? NO (they were majority)
- RESULT: No compensation

Bettor 2 (S2, YES):
- Bet later (S2)
- Was their outcome minority at S2 end? NO (they were majority)
- RESULT: No compensation

WHEN DOES COMPENSATION APPLY?
If someone bets early AND their side was minority at that segment's end,
but later the crowd flipped and they became majority (and lost),
they can claim up to 30% of their stake from the compensation pool.

This rewards early conviction even when the crowd flips late!
"

# ============================================
# GAME THEORY INSIGHTS
# ============================================

echo "
###############################################################################
#                          GAME THEORY INSIGHTS                               #
###############################################################################

ALL4ONE creates unique dynamics:

1. WHALE RESISTANCE
   └─ Minority determined by COUNT, not stake
   └─ A whale betting 10000 tokens counts as 1 vote
   └─ Splitting across addresses is costly and detectable

2. CONVICTION REWARDS
   └─ Early bettors get 1.5x effective stake
   └─ Rewards early conviction and risk-taking
   └─ Late joiners get no conviction bonus

3. ANTI-SNIPING
   └─ Final segment (S3) has 1.0x weight - no bonus
   └─ Can't wait until the end to see which way to bet
   └─ All votes are hidden anyway!

4. TEMPORAL COMPENSATION
   └─ Protects early believers who got flipped
   └─ Up to 30% recovery for early-but-lost bettors
   └─ Only applies to segments S0-S2

5. PSYCHOLOGICAL WARFARE
   └─ You're not predicting the outcome
   └─ You're predicting what others will predict
   └─ Second-order thinking required

This is what makes ALL4ONE uniquely suited for Aleo's privacy features!

###############################################################################
"

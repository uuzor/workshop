# Premier League Virtual Betting - Enhanced System Architecture

## Overview
A comprehensive betting platform with seasons, rounds, NFT badges, and platform tokens.

## System Components

### 1. **league_token.aleo** - $LEAGUE Token
- Platform utility token
- Total supply with 30% airdrop allocation
- Public and private balances
- Used for betting and rewards

### 2. **team_badges.aleo** - NFT Team Badges
- 20 unique Premier League team badges (NFTs)
- Badge holders get betting bonuses
- Marketplace with 2.5% fees
- Collectible system

### 3. **premier_league_betting.aleo** - Main Betting Contract
- Season-based betting (36 rounds per season)
- 10 matches per round (every 15 minutes)
- Match betting with 3-5% house edge
- Season winner pool (2% of total bets)
- Team standings and scores

## Game Mechanics

### Season Structure
```
Season 1
├── Round 1 (10 matches) - Time: 0 min
├── Round 2 (10 matches) - Time: 15 min
├── Round 3 (10 matches) - Time: 30 min
├── ...
└── Round 36 (10 matches) - Time: 525 min (8.75 hours)

Total: 360 matches per season
```

### Match Distribution
- 20 teams total
- 10 matches per round (20 teams / 2 = 10 matches)
- Each team plays once per round
- Round-robin scheduling

### Betting Types

#### 1. Match Betting (Paid)
- Bet on: Home Win / Draw / Away Win
- Stake: User-defined amount of $LEAGUE tokens
- House Edge: 3-5% (configurable)
- Payout: Stake × Odds (minus house edge)

#### 2. Season Winner Betting (Free Entry)
- Bet on which team will win the season
- Entry: Free (no stake required)
- Prize Pool: 2% of total match betting pool for that season
- Winner: Team with highest points at end of season

### NFT Badge Bonuses
- Holding a team's badge gives betting bonus
- Bonus types:
  - **Odds Boost**: +5% better odds when betting on your team
  - **House Edge Reduction**: 1% lower house edge
  - **Season Pool Entry**: Automatic entry to season pool

### Economics

#### Revenue Streams
1. **Match Betting House Edge**: 3-5% of all bets
2. **NFT Marketplace Fees**: 2.5% on all badge sales
3. **Season Pool Rake**: Platform keeps interest/overflow

#### Token Distribution
- **Total Supply**: 1,000,000,000 $LEAGUE
- **Airdrop (30%)**: 300,000,000 $LEAGUE to early users
- **Betting Rewards (40%)**: 400,000,000 $LEAGUE for winners
- **NFT Rewards (10%)**: 100,000,000 $LEAGUE for badge holders
- **Team/Development (20%)**: 200,000,000 $LEAGUE

## Data Structures

### Season
```leo
struct Season {
    id: u8,
    current_round: u8,      // 1-36
    start_time: u64,
    status: u8,             // 0: scheduled, 1: active, 2: finished
    total_betting_pool: u64,
}
```

### Round
```leo
struct Round {
    season_id: u8,
    round_number: u8,
    start_time: u64,
    status: u8,
}
```

### Match
```leo
struct Match {
    id: field,
    season_id: u8,
    round_number: u8,
    home_team: u8,
    away_team: u8,
    home_score: u8,
    away_score: u8,
    status: u8,
}
```

### Team Standing
```leo
struct Standing {
    team_id: u8,
    season_id: u8,
    points: u64,           // 3 for win, 1 for draw
    wins: u32,
    draws: u32,
    losses: u32,
    goals_for: u32,
    goals_against: u32,
}
```

### Match Bet
```leo
record MatchBet {
    owner: address,
    match_id: field,
    bet_type: u8,          // 1: home, 2: draw, 3: away
    stake: u64,
    odds: u64,
    potential_payout: u64,
    has_badge_bonus: bool,
}
```

### Season Bet
```leo
record SeasonBet {
    owner: address,
    season_id: u8,
    predicted_winner: u8,  // team_id
    entry_time: u64,
}
```

### Team Badge (NFT)
```leo
record TeamBadge {
    owner: address,
    team_id: u8,
    badge_id: field,       // Unique ID
    mint_number: u32,      // Which # badge (e.g., #5 of Man City)
    rarity: u8,            // 1: common, 2: rare, 3: legendary
}
```

## Smart Contract Functions

### league_token.aleo

```leo
// Minting
- mint_public(receiver: address, amount: u64)
- mint_private(receiver: address, amount: u64) -> token

// Transfers
- transfer_public(receiver: address, amount: u64)
- transfer_private(sender: token, receiver: address, amount: u64)

// Airdrop
- claim_airdrop(user: address) -> token
- check_airdrop_eligibility(user: address) -> bool
```

### team_badges.aleo

```leo
// Minting
- mint_badge(team_id: u8, receiver: address) -> TeamBadge

// Marketplace
- list_badge(badge: TeamBadge, price: u64) -> Listing
- buy_badge(listing: Listing, payment: token) -> TeamBadge
- cancel_listing(listing: Listing) -> TeamBadge

// Bonuses
- get_betting_bonus(badge: TeamBadge) -> u8
- verify_badge_ownership(owner: address, team_id: u8) -> bool
```

### premier_league_betting.aleo

```leo
// Season Management
- start_season(season_id: u8)
- end_season(season_id: u8)
- start_round(season_id: u8, round_number: u8)

// Match Management
- schedule_matches(season_id: u8, round_number: u8)
- simulate_match(match_id: field, home_score: u8, away_score: u8)

// Betting
- place_match_bet(match_id: field, bet_type: u8, stake_token: token) -> MatchBet
- place_season_bet(season_id: u8, team_id: u8) -> SeasonBet

// Settlement
- settle_match_bet(bet: MatchBet) -> token
- settle_season_bets(season_id: u8)

// Standings
- update_standings(match_id: field)
- get_season_winner(season_id: u8) -> u8
```

## Odds Calculation

### Base Odds (No Badge)
```
Team Strength Difference | Home Win | Draw | Away Win
------------------------|----------|------|----------
+20 or more            | 1.50x    | 4.00x| 6.00x
+10 to +19             | 1.80x    | 3.50x| 4.50x
0 to +9                | 2.20x    | 3.20x| 3.40x
-9 to 0                | 3.40x    | 3.20x| 2.20x
-19 to -10             | 4.50x    | 3.50x| 1.80x
-20 or less            | 6.00x    | 4.00x| 1.50x
```

### With Badge Bonus
- Odds multiplied by 1.05 (5% boost)
- House edge reduced from 5% to 4%

### House Edge Application
```
Effective Odds = Base Odds × (1 - House Edge)
Example: 2.00x odds with 5% edge = 2.00 × 0.95 = 1.90x payout
```

## Season Pool Distribution

### Prize Pool Calculation
```
Total Season Bets: 1,000,000 $LEAGUE
Season Pool (2%): 20,000 $LEAGUE

Distribution:
- 1st Place (50%): 10,000 $LEAGUE
- 2nd Place (30%): 6,000 $LEAGUE
- 3rd Place (20%): 4,000 $LEAGUE

Split among all winners who predicted correctly
```

## Match Scheduling Algorithm

### Round-Robin Format
```python
# Pseudo-code for 20 teams, 10 matches per round
round 1:  1v20, 2v19, 3v18, 4v17, 5v16, 6v15, 7v14, 8v13, 9v12, 10v11
round 2:  20v12, 1v11, 2v10, 3v9, 4v8, 5v7, 6v19, 13v18, 14v17, 15v16
...continues rotating
```

## Implementation Timeline

### Phase 1: Core Infrastructure (Week 1)
- [ ] $LEAGUE token contract
- [ ] Basic betting contract
- [ ] Season and round management

### Phase 2: NFT System (Week 2)
- [ ] Team badges contract
- [ ] Marketplace functionality
- [ ] Badge bonus integration

### Phase 3: Advanced Features (Week 3)
- [ ] Season pool betting
- [ ] Standings tracking
- [ ] Match scheduling algorithm

### Phase 4: Testing & Deployment (Week 4)
- [ ] Integration testing
- [ ] Security audit
- [ ] Testnet deployment

## Key Technical Considerations

### 1. Time Management
- Rounds every 15 minutes (900 seconds)
- Use block timestamps for scheduling
- Allow admin to trigger rounds manually

### 2. Randomness
- Use commit-reveal for match results
- Oracle integration for fair outcomes
- Backup manual input by admin

### 3. Gas Optimization
- Batch processing for multiple bets
- Lazy settlement (settle on claim)
- Efficient storage structures

### 4. Security
- Reentrancy protection
- Overflow/underflow checks
- Access control for admin functions
- Badge ownership verification

## User Journey

### New User
1. Claim airdrop → Receive 100 $LEAGUE
2. Buy team badge → Spend $LEAGUE on favorite team
3. Place season bet → Free entry, predict winner
4. Place match bets → Use $LEAGUE tokens
5. Earn rewards → Receive winnings in $LEAGUE

### Badge Holder
1. Own team badge → Get 5% odds boost
2. Bet on team matches → Lower house edge
3. Collect all badges → Unlock special bonuses
4. Trade badges → Marketplace with 2.5% fee

---

This architecture provides a complete, engaging betting platform with tokenomics, NFTs, and season-long gameplay!

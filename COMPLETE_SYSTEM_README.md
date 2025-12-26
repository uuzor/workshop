# Premier League Virtual Betting - Complete System

A comprehensive betting platform on Aleo blockchain with seasons, NFTs, and platform tokens.

## 🎯 System Overview

This is a complete betting ecosystem consisting of three smart contracts:

1. **league_token.aleo** - $LEAGUE platform token with airdrop
2. **team_badges.aleo** - NFT badges for 20 Premier League teams
3. **premier_league_betting.aleo** - Main betting contract with seasons

## ✨ Features

### Platform Token ($LEAGUE)
- **Total Supply**: 1,000,000,000 tokens
- **Airdrop**: 30% (300M tokens) for early users
- **Per User**: 100 $LEAGUE on claim
- Public and private balances
- Used for all betting

### NFT Team Badges
- **20 Unique Teams**: All Premier League clubs
- **Betting Bonuses**: 5% odds boost for badge holders
- **Marketplace**: Trade badges with 2.5% fees
- **Rarity Levels**: Common, Rare, Legendary

### Betting System
- **Seasons**: 36 rounds per season
- **Matches**: 10 matches per round (every 15 minutes)
- **Total Matches**: 360 matches per season
- **Match Betting**: Paid with $LEAGUE tokens
- **Season Betting**: Free entry, prize pool from 2% of all bets
- **House Edge**: 4% on match bets
- **Badge Bonus**: 5% better odds for badge holders

## 📊 Game Economics

### Revenue Distribution
```
Every 100 $LEAGUE bet:
├── 4 $LEAGUE → House (4% edge)
├── 2 $LEAGUE → Season Pool (2%)
└── 94 $LEAGUE → Potential payout
```

### Season Pool
- Accumulates 2% from all match bets
- Distributed to users who correctly predicted season winner
- Free entry for all users

### Badge Benefits
```
Without Badge: Base odds 2.00x → Effective 1.92x (4% house edge)
With Badge:    Base odds 2.00x × 1.05 = 2.10x → Effective 2.016x
Advantage:     +5% better payout!
```

## 🏗️ Architecture

### Contract Interactions
```
User
  │
  ├─→ league_token.aleo
  │     ├─ Claim airdrop (100 $LEAGUE)
  │     ├─ Transfer tokens
  │     └─ Check balance
  │
  ├─→ team_badges.aleo
  │     ├─ Mint team badge NFT
  │     ├─ Trade on marketplace (2.5% fee)
  │     └─ Get betting bonus
  │
  └─→ premier_league_betting.aleo
        ├─ Place match bets (paid)
        ├─ Place season bets (free)
        ├─ View standings
        └─ Claim winnings
```

## 🚀 Quick Start

### 1. Build All Contracts
```bash
# Build $LEAGUE token
cd league_token && leo build

# Build team badges
cd ../team_badges && leo build

# Build betting contract
cd ../premier_league_betting && leo build
```

### 2. Run Complete System Test
```bash
cd /home/user/workshop
./TEST_COMPLETE_SYSTEM.sh
```

### 3. Individual Contract Tests

#### Test $LEAGUE Token
```bash
cd league_token

# Initialize supply
leo run initialize_supply

# Claim airdrop
leo run claim_airdrop

# Transfer tokens
leo run transfer_public <receiver> <amount>
```

#### Test Team Badges
```bash
cd team_badges

# Mint badge for Manchester City
leo run mint_badge 1u8 <your_address> 1u8

# List badge for sale
leo run list_badge <badge_record> 1000u64

# Buy badge
leo run buy_badge <listing_record> <buyer_address>
```

#### Test Betting Contract
```bash
cd premier_league_betting

# Add teams
leo run add_team 1u8 123456field 95u8  # Man City
leo run add_team 2u8 234567field 92u8  # Arsenal

# Start season
leo run start_season 1u8 <timestamp>

# Schedule match
leo run schedule_match <match_id> 1u8 1u8 1u8 2u8

# Place bet
leo run place_match_bet <match_id> 1u8 100u64 true 1u8

# Simulate match
leo run simulate_match <match_id> 2u8 1u8

# Place season bet (free)
leo run place_season_bet 1u8 1u8 <timestamp>
```

## 📋 Contract Reference

### league_token.aleo Functions

| Function | Type | Description |
|----------|------|-------------|
| `initialize_supply` | Admin | Set total supply and airdrop pool |
| `claim_airdrop` | User | Claim 100 $LEAGUE (one-time) |
| `mint_public` | Admin | Mint tokens publicly |
| `mint_private` | Admin | Mint private tokens |
| `transfer_public` | User | Transfer public tokens |
| `transfer_private` | User | Transfer private tokens |
| `transfer_priv_to_pub` | User | Convert private → public |
| `transfer_pub_to_priv` | User | Convert public → private |

### team_badges.aleo Functions

| Function | Type | Description |
|----------|------|-------------|
| `set_badge_bonus` | Admin | Set betting bonus % |
| `mint_badge` | Admin/User | Mint team badge NFT |
| `list_badge` | User | List badge for sale |
| `buy_badge` | User | Purchase listed badge |
| `cancel_listing` | User | Remove from marketplace |
| `transfer_badge` | User | Gift badge to another user |

### premier_league_betting.aleo Functions

| Function | Type | Description |
|----------|------|-------------|
| `add_team` | Admin | Add team to league |
| `start_season` | Admin | Start new season |
| `start_round` | Admin | Start round (15min intervals) |
| `schedule_match` | Admin | Schedule match in round |
| `simulate_match` | Oracle | Record match result |
| `place_match_bet` | User | Bet on match outcome |
| `place_season_bet` | User | Predict season winner (free) |
| `settle_match_bet` | User | Claim match winnings |

## 🎮 User Journey

### New User Flow
1. **Claim Airdrop** → Receive 100 $LEAGUE
2. **Buy Team Badge** → Get favorite team NFT
3. **Place Season Bet** → Free prediction for season winner
4. **Place Match Bets** → Bet on individual matches with badge bonus
5. **Win Rewards** → Collect winnings in $LEAGUE

### Badge Collector Flow
1. **Collect Badges** → Mint or buy all 20 teams
2. **Get Bonuses** → 5% better odds on all bets
3. **Trade Badges** → Buy/sell on marketplace
4. **Earn from Trading** → Platform takes only 2.5% fee

## 📈 Season Structure

```
Season 1 (8.75 hours)
├── Round 1  (0:00)   - 10 matches
├── Round 2  (0:15)   - 10 matches
├── Round 3  (0:30)   - 10 matches
├── Round 4  (0:45)   - 10 matches
├── Round 5  (1:00)   - 10 matches
├── ...
└── Round 36 (8:45)   - 10 matches

Total: 360 matches per season
Points: 3 for win, 1 for draw, 0 for loss
Winner: Team with most points
```

## 🏆 Team List (20 Premier League Teams)

1. Manchester City (95)
2. Arsenal (92)
3. Liverpool (93)
4. Chelsea (88)
5. Manchester United (87)
6. Tottenham (86)
7. Newcastle (84)
8. Brighton (82)
9. Aston Villa (81)
10. West Ham (79)
11. Fulham (77)
12. Brentford (76)
13. Crystal Palace (75)
14. Wolves (74)
15. Bournemouth (72)
16. Nottingham Forest (71)
17. Everton (70)
18. Burnley (68)
19. Sheffield United (66)
20. Luton Town (65)

## 🔒 Security Features

- **Zero-Knowledge Proofs**: Bet privacy
- **Aleo Blockchain**: Provable computations
- **No Reentrancy**: Safe contract design
- **Overflow Protection**: Built-in checks
- **Access Control**: Admin-only functions

## 🛠️ Development

### Project Structure
```
workshop/
├── league_token/
│   ├── src/main.leo
│   ├── program.json
│   └── build/
├── team_badges/
│   ├── src/main.leo
│   ├── program.json
│   └── build/
├── premier_league_betting/
│   ├── src/main.leo
│   ├── program.json
│   ├── build/
│   └── ARCHITECTURE.md
└── TEST_COMPLETE_SYSTEM.sh
```

### Build Requirements
- Rust 1.92.0+
- Leo 3.4.0
- Aleo CLI

### Gas Optimization
- Lazy settlement (settle on claim)
- Batch operations where possible
- Efficient storage structures
- Minimal on-chain computation

## 📊 Analytics Tracking

The system tracks:
- Total betting volume per season
- Season pool size
- House balance
- Badge mint counts
- Match outcomes
- Team standings (wins, draws, losses, goals)
- Marketplace volume and fees

## 🎯 Roadmap

### Phase 1 (Completed) ✅
- Core token contract
- NFT badge system
- Basic betting mechanics

### Phase 2 (Next)
- Automated round scheduling
- Oracle integration for randomness
- Advanced odds calculation

### Phase 3 (Future)
- Multiple betting markets
- Live betting
- Team-specific bonuses
- Tournament modes

## 📄 License

MIT License - See LICENSE file

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request

## 🔗 Links

- [Aleo Documentation](https://developer.aleo.org/)
- [Leo Language](https://docs.leo-lang.org/)
- [Architecture Details](./premier_league_betting/ARCHITECTURE.md)

---

**Built with ❤️ on Aleo Blockchain**

Revolutionizing sports betting with privacy, NFTs, and tokenomics!

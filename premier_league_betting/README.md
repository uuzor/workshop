# Premier League Virtual Betting Game

A privacy-focused virtual betting platform built on the Aleo blockchain, inspired by Bet9ja's virtual football betting mechanics.

## Features

- **20 Premier League Teams**: Full roster with realistic strength ratings
- **Match Simulation**: AI-powered match results using verifiable randomness
- **Privacy-Preserving Bets**: User bets are private, results are public
- **Multiple Betting Markets**: Home/Draw/Away (expandable to 20+ markets)
- **Dynamic Odds**: Calculated based on team strength
- **Instant Settlement**: Automated payout system
- **Zero-Knowledge Proofs**: Verifiable fairness without revealing user data

## Quick Start

### Prerequisites

- Aleo CLI installed ([installation guide](https://developer.aleo.org/guides/introduction/installation))
- Leo programming environment

### Installation

```bash
# Clone or navigate to the project
cd premier_league_betting

# Build the program
leo build

# Run tests (if available)
leo test
```

### Usage

#### 1. Initialize Season (Admin Only)

```bash
leo run initialize_season 1u8
```

#### 2. Schedule a Match (Admin Only)

```bash
# Schedule Man City vs Arsenal
leo run schedule_match 1u8 2u8 1735200000u64
```

#### 3. Place a Bet

```bash
# Bet on home win (bet_type 1), stake 100 tokens, odds 2.00x (200)
leo run place_bet <match_id> 1u8 100u64 200u64
```

#### 4. Simulate Match (Oracle/Admin)

```bash
leo run simulate_match <match_id> <random_seed> <timestamp>
```

#### 5. Settle Bet

```bash
leo run settle_bet <betting_ticket_record>
```

## Contract Structure

### Data Types

- **Team**: Contains team ID, overall strength, attack, and defense ratings
- **Match**: Match details including teams, kickoff time, and status
- **MatchResult**: Final scores and random seed used
- **BettingTicket** (Record): Private user bet with stake and odds
- **BettingPool**: Public aggregated betting data per match
- **Payout** (Record): Private winnings record

### Key Functions

| Function | Type | Description |
|----------|------|-------------|
| `initialize_season` | Admin | Set up 20 teams with stats |
| `schedule_match` | Admin | Create new match |
| `place_bet` | User | Place private bet on match |
| `simulate_match` | Oracle | Generate match result |
| `settle_bet` | User | Claim winnings |

### Betting Types

Currently supported:
- **1**: Home Win
- **2**: Draw
- **3**: Away Win

Future expansion:
- Over/Under goals
- Correct score
- Both teams to score
- And 17+ more markets

## Architecture

```
┌─────────────────────────────────────┐
│     Premier League Betting          │
├─────────────────────────────────────┤
│                                     │
│  Private Layer (Records)            │
│  • User betting tickets             │
│  • Winnings/payouts                 │
│                                     │
├─────────────────────────────────────┤
│                                     │
│  Public Layer (Mappings)            │
│  • Team statistics                  │
│  • Match schedules                  │
│  • Match results                    │
│  • Betting pool totals              │
│                                     │
└─────────────────────────────────────┘
```

## Security

- **Randomness**: Uses commit-reveal scheme or oracle-provided seeds
- **Access Control**: Admin-only functions for match management
- **Input Validation**: All user inputs are validated
- **Privacy**: Zero-knowledge proofs ensure bet privacy
- **Transparency**: Match results and pools are publicly verifiable

## Roadmap

- [x] Core betting engine (Home/Draw/Away)
- [x] Match simulation with randomness
- [x] Privacy-preserving betting tickets
- [ ] Extended betting markets (20+ types)
- [ ] Token integration for payments
- [ ] Oracle integration for randomness
- [ ] Frontend interface
- [ ] Season leaderboards
- [ ] Historical statistics

## Development

### Testing Locally

```bash
# Build
leo build

# Run specific function
leo run <function_name> <arguments>

# Example: Schedule match
leo run schedule_match 1u8 2u8 1735200000u64
```

### Deployment

```bash
# Deploy to testnet
leo deploy --network testnet3

# Deploy to mainnet (after thorough testing)
leo deploy --network mainnet
```

## Documentation

For comprehensive documentation on Aleo smart contract development and the architecture of this betting system, see:

- [PREMIER_LEAGUE_BETTING_ANALYSIS.md](../PREMIER_LEAGUE_BETTING_ANALYSIS.md) - Full analysis and design document
- [Aleo Developer Docs](https://developer.aleo.org/)
- [Leo Language Docs](https://docs.leo-lang.org/)

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Disclaimer

This is a demonstration project for educational purposes. Ensure compliance with local gambling regulations before deploying to production.

## Support

For questions and support:
- GitHub Issues: [Create an issue](https://github.com/your-repo/issues)
- Aleo Discord: [Join the community](https://aleo.org/discord)
- Documentation: [Read the full analysis](../PREMIER_LEAGUE_BETTING_ANALYSIS.md)

---

Built with ❤️ on Aleo blockchain

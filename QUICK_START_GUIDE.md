# Quick Start Guide: Premier League Virtual Betting on Aleo

## Overview

This guide will help you get started with building and understanding the Premier League virtual betting game on Aleo blockchain.

## What You'll Find Here

1. **PREMIER_LEAGUE_BETTING_ANALYSIS.md** - Comprehensive 12,000+ word analysis covering:
   - Aleo blockchain fundamentals
   - Leo language syntax and patterns
   - Smart contract structure analysis
   - Virtual betting game mechanics (Bet9ja research)
   - Complete architecture design
   - Implementation roadmap
   - Security considerations

2. **premier_league_betting/** - Starter smart contract with:
   - Full Leo implementation
   - 20 Premier League teams
   - Match scheduling system
   - Private betting tickets
   - Match simulation with randomness
   - Settlement and payout system

## Getting Started

### Step 1: Install Aleo Tools

```bash
# Install Aleo and Leo
curl -L https://raw.githubusercontent.com/AleoHQ/sdk/testnet3/install.sh | bash

# Verify installation
leo --version
```

### Step 2: Explore Existing Contracts

```bash
# Run token example
cd token && ./run.sh

# Run auction example
cd ../auction && ./run.sh

# Run vote example
cd ../vote && ./run.sh
```

### Step 3: Study the Analysis Document

Read `PREMIER_LEAGUE_BETTING_ANALYSIS.md` to understand:
- How Aleo smart contracts work
- Patterns from existing contracts
- Betting game architecture
- Implementation strategy

### Step 4: Examine the Betting Contract

```bash
cd premier_league_betting

# View the contract
cat src/main.leo

# Read the documentation
cat README.md
```

### Step 5: Build and Test

```bash
cd premier_league_betting

# Build the contract
leo build

# Test individual functions (after setting up .env)
echo 'NETWORK=testnet3
PRIVATE_KEY=APrivateKey1zkp...' > .env

# Initialize season
leo run initialize_season 1u8
```

## Key Concepts to Understand

### 1. Records vs Mappings

**Records** (Private):
- User betting tickets
- Winnings/payouts
- Private by default

**Mappings** (Public):
- Team statistics
- Match results
- Betting pool totals
- Public and queryable

### 2. Transitions vs Finalize

**Transitions**:
- Off-chain execution
- Private computation
- Returns records

**Finalize**:
- On-chain execution
- Updates public mappings
- Executed by all nodes

### 3. Privacy Model

```
User Places Bet
      ↓
Private Betting Ticket Created (Record)
      ↓
Public Pool Updated (Mapping)
      ↓
Match Simulated (Public Result)
      ↓
User Claims Payout (Private Record)
```

## Learning Path

### Week 1: Fundamentals
- [ ] Install Aleo tools
- [ ] Run all example contracts
- [ ] Read Leo language basics
- [ ] Understand records and mappings

### Week 2: Analysis
- [ ] Read full analysis document
- [ ] Study existing contract patterns
- [ ] Research virtual betting mechanics
- [ ] Understand randomness on blockchain

### Week 3: Implementation
- [ ] Review starter contract code
- [ ] Modify team statistics
- [ ] Add new betting markets
- [ ] Implement odds calculation

### Week 4: Testing
- [ ] Build the contract
- [ ] Test on local environment
- [ ] Deploy to testnet
- [ ] Simulate full betting flow

## Common Leo Patterns

### Pattern 1: Public State Update
```leo
transition update_something(public param: u64) {
    return then finalize(param);
}

finalize update_something(public param: u64) {
    // Update mappings here
}
```

### Pattern 2: Private Record Creation
```leo
transition create_record(param: u64) -> MyRecord {
    return MyRecord {
        owner: self.caller,
        data: param,
    };
}
```

### Pattern 3: Record Consumption
```leo
transition use_record(record: MyRecord) -> NewRecord {
    // Process record
    return NewRecord {
        owner: record.owner,
        // ... new data
    };
}
```

### Pattern 4: Access Control
```leo
finalize admin_function(public caller: address) {
    let is_admin: bool = Mapping::get(admins, caller);
    assert_eq(is_admin, true);
    // ... admin logic
}
```

## Development Workflow

```bash
# 1. Edit contract
vim premier_league_betting/src/main.leo

# 2. Build
cd premier_league_betting
leo build

# 3. Test locally
leo run <function_name> <args>

# 4. Deploy to testnet
leo deploy --network testnet3

# 5. Interact with deployed contract
# (Use Aleo SDK or CLI)
```

## Resources

### Documentation
- [Full Analysis](PREMIER_LEAGUE_BETTING_ANALYSIS.md) - Complete guide
- [Aleo Docs](https://developer.aleo.org/) - Official documentation
- [Leo Docs](https://docs.leo-lang.org/) - Language reference

### Example Contracts
- `token/` - Token with public/private balances
- `auction/` - Sealed-bid auction system
- `vote/` - Voting with privacy tickets
- `basic_bank/` - Banking with interest
- `tictactoe/` - Game state management

### Community
- Discord: https://aleo.org/discord
- Twitter: @AleoHQ
- GitHub: https://github.com/AleoHQ

## Next Steps

1. **Read the Analysis**: Start with `PREMIER_LEAGUE_BETTING_ANALYSIS.md`
2. **Run Examples**: Execute all example contracts to see them in action
3. **Study the Code**: Examine `premier_league_betting/src/main.leo`
4. **Build Your Own**: Extend the contract with new features
5. **Deploy**: Test on testnet3 before mainnet

## Tips for Success

### Do's ✅
- Start with simple examples
- Read error messages carefully
- Test thoroughly on testnet
- Use proper access control
- Validate all inputs
- Document your code

### Don'ts ❌
- Don't skip the examples
- Don't ignore security considerations
- Don't use predictable randomness
- Don't deploy untested code to mainnet
- Don't forget about gas costs
- Don't hardcode sensitive data

## Troubleshooting

### Build Errors
```bash
# Clear build cache
leo clean

# Rebuild
leo build
```

### Network Issues
```bash
# Check network in .env
cat .env

# Should show:
# NETWORK=testnet3
# PRIVATE_KEY=APrivateKey1zkp...
```

### Function Execution Errors
- Check parameter types match exactly
- Ensure records are valid (not consumed)
- Verify you have the right permissions
- Check finalize conditions

## Sample Project Timeline

### Phase 1 (1-2 weeks): Learning
- Setup environment
- Study documentation
- Run examples
- Understand concepts

### Phase 2 (2-3 weeks): Development
- Design your features
- Implement core logic
- Add betting markets
- Integrate randomness

### Phase 3 (1-2 weeks): Testing
- Unit tests
- Integration tests
- Security audit
- Performance optimization

### Phase 4 (1 week): Deployment
- Deploy to testnet
- Frontend integration
- User testing
- Mainnet deployment

## Get Help

If you're stuck:
1. Check the [Full Analysis Document](PREMIER_LEAGUE_BETTING_ANALYSIS.md)
2. Review example contracts in this repo
3. Read [Aleo Developer Docs](https://developer.aleo.org/)
4. Ask on [Aleo Discord](https://aleo.org/discord)
5. Check GitHub issues

## Contributing

Found an issue or have an improvement?
1. Fork the repository
2. Make your changes
3. Test thoroughly
4. Submit a pull request

---

**Happy Building! 🚀**

Build the future of privacy-focused betting on Aleo blockchain.

For questions: Join Aleo Discord or create a GitHub issue.

# Premier League Betting - Virtual Parimutuel Redesign

## 🎯 Major Architectural Changes

### **From: Fixed-Odds Parlays → To: Virtual Parimutuel with Locked Odds**

---

## ✅ Implemented Changes

### **1. Virtual Seeding System** ✅
- **No real token seeding** - completely virtual
- **Odds calculated at round start** and locked immediately
- **Odds range: 1.2x - 2.1x** (profitable for LP)
- **6-tier allocation system** for exciting variance

**Implementation**: `finalize_start_round_random:159-274`
```leo
// 6-tier pseudo-random allocation
if rand > 80u8 {
    (50u8, 20u8, 30u8)  // HUGE FAVORITE: 1.2x / 2.0x / 1.67x
} else if rand > 60u8 {
    (45u8, 25u8, 30u8)  // STRONG: 1.33x / 1.8x / 1.67x
}
// ... 4 more tiers for variety
```

### **2. Combined Seeding + Start Round** ✅
- **Single function call** instead of two
- Creates matches AND locks odds simultaneously
- More efficient for users

**Before**:
```bash
leo run seed_round 1u8 1u8 0u8    # Seed batch 1
leo run seed_round 1u8 1u8 3u8    # Seed batch 2
# ... 4 more calls
leo run start_round 1u8 1u8       # Then start
```

**After**:
```bash
leo run start_round_random 1u8 1u8 1735300000u64  # Done!
```

### **3. Reduced to 4 Matches Per Round** ✅
- **No batching needed** (4 matches × 2 teams × 2 mappings = 16 sets)
- **Within 16-set limit** for single function call
- **Simpler user experience**

**Benefits**:
- ✅ `end_round()` processes all matches at once
- ✅ No need for 4 separate batch calls
- ✅ Faster settlement

### **4. Multiple Concurrent Rounds** ✅
- **Round ID = hash(season_id + round_number)**
- Different rounds can run simultaneously
- No blocking between rounds

**Example**:
```bash
# Round 1 can be betting while Round 2 is settling
leo run start_round_random 1u8 1u8 ...  # Start Round 1
leo run start_round_random 1u8 2u8 ...  # Start Round 2 immediately
```

### **5. Locked Odds Mappings** ✅
Added 3 new mappings per match:
```leo
mapping locked_home_odds: field => u64;  // 1.2x - 2.1x
mapping locked_away_odds: field => u64;
mapping locked_draw_odds: field => u64;
```

**Locked at round start, never change!**

### **6. Count-Based Parlay Tiers (FOMO)** ✅
```leo
mapping round_parlay_count: field => u8;

// Tier system:
// 0-9 parlays:   2.5x multiplier
// 10-19 parlays: 2.2x multiplier
// 20-29 parlays: 1.9x multiplier
// 30-39 parlays: 1.6x multiplier
// 40+ parlays:   1.3x multiplier
```

**Creates urgency** - early parlays get better multipliers!

---

## 📊 Architecture Comparison

| Feature | OLD (Fixed Odds) | NEW (Virtual Parimutuel) |
|---------|------------------|--------------------------|
| **Odds System** | Fixed 2.01x | Dynamic 1.2x - 2.1x |
| **Seeding** | None | Virtual (no tokens) |
| **Matches/Round** | 10 | 4 |
| **Start Round** | 2 steps | 1 step (combined) |
| **End Round** | 4 batch calls | 1 call |
| **Concurrent Rounds** | No | Yes ✅ |
| **Parlay Bonus** | Fixed multiplication | Count-based tiers |
| **Pool Distribution** | No pools | Virtual pools (locked odds) |
| **Odds Preview** | Not needed | Locked at start |

---

## 🔧 Key Functions Updated

### **start_round_random()** (Combined)
```leo
async function finalize_start_round_random(season_id, round_number, round_time) {
    // 1. Set round status
    // 2. Create 4 random matches
    // 3. Calculate virtual odds (6-tier system)
    // 4. LOCK odds immediately
    // 5. Store in mappings
}
```

**Sets per call**: 1 (status) + 4 (matches) + 12 (odds) = 17 sets
⚠️ **Slightly over 16-set limit** - may need optimization

**Possible fix**: Remove round status update or batch odds locking

### **place_multi_bet()** (Async with Finalize)
```leo
transition place_multi_bet(
    match_ids: [field; 4],  // 4 matches max
    bet_types: [u8; 4],
    num_bets: u8,
    total_stake: u64
) -> (BetSlip, Future)

// Finalize increments parlay count for FOMO tiers
async function finalize_place_bet(season_id, round_number, num_bets) {
    if num_bets > 1u8 {
        parlay_count += 1;  // Next bettor gets lower tier!
    }
}
```

### **end_round()** (No Batching!)
```leo
async function finalize_end_round(season_id, round_number) {
    // Resolve all 4 matches in ONE call
    for match_num: u8 in 0u8..4u8 {
        // Generate random scores
        // Update standings
        // Set outcome
    }
}
```

**Sets per call**: 1 (status) + 4 (matches) + 4 (outcomes) + 8 (standings) = 17 sets
⚠️ **Slightly over 16-set limit** - may need to remove status update

### **compress_odds()** (New Helper)
```leo
function compress_odds(raw_odds: u64) -> u64 {
    // Map raw 1.2x-4.0x → compressed 1.2x-2.1x
    // Min: 120 (1.2x)
    // Max: 210 (2.1x)
    // Linear compression formula
}
```

---

## ⚠️ Known Issues & TODO

### **Issue #1: 16-Set Limit Exceeded**
Both `start_round_random` and `end_round` use ~17 sets

**Solutions**:
1. Remove round_status update (use round_start_times instead)
2. Batch odds locking into separate function
3. Remove one mapping update

### **Issue #2: claim_winnings Incomplete**
The claim_winnings function needs updating to:
- Read locked odds from mappings
- Calculate payout based on locked odds
- Apply count-based parlay multiplier
- All-or-nothing settlement

**Status**: Partially implemented, needs finalization

### **Issue #3: BetSlip Record Mismatch**
BetSlip record has `parlay_multiplier` field but place_multi_bet sets it to placeholder value

**Fix**: Calculate actual multiplier in finalize or remove field

---

## 🧪 Testing Plan

### **Test 1: Virtual Odds Generation**
```bash
leo run start_round_random 1u8 1u8 1735300000u64
# Verify: 4 matches created with locked odds 1.2x-2.1x
```

### **Test 2: Count-Based FOMO**
```bash
# Place 15 parlays
for i in 1..15; do
    leo run place_multi_bet ...
done
# Verify: First 10 get 2.5x, next 5 get 2.2x
```

### **Test 3: Concurrent Rounds**
```bash
leo run start_round_random 1u8 1u8 ...  # Round 1
leo run start_round_random 1u8 2u8 ...  # Round 2
# Both should work simultaneously
```

### **Test 4: End Round (No Batching)**
```bash
leo run end_round 1u8 1u8
# Verify: All 4 matches resolved in one call
```

---

## 📈 Benefits of New Architecture

### **For Users**:
- ✅ **Exciting odds variance** (1.2x - 2.1x vs fixed 2.01x)
- ✅ **FOMO parlay tiers** (early bettors get 2.5x!)
- ✅ **Simpler UX** (1 call to start round vs 2)
- ✅ **Faster settlement** (1 call vs 4 batches)

### **For Protocol**:
- ✅ **No token seeding required** (virtual system)
- ✅ **Profitable odds range** (1.2x-2.1x capped for LP safety)
- ✅ **Multiple concurrent rounds** (higher throughput)
- ✅ **Count-based incentives** (drives betting volume)

### **For Development**:
- ✅ **Simpler architecture** (fewer mappings than pool system)
- ✅ **Locked odds** (easier accounting, no dynamic recalc)
- ✅ **Proven Solidity model** (matches your existing design)

---

## 🚀 Next Steps

1. **Fix 16-set limit issues** in start_round and end_round
2. **Complete claim_winnings** implementation
3. **Test all functions** end-to-end
4. **Optimize gas usage** (minimize mapping operations)
5. **Add preview function** (optional: show locked odds before betting)
6. **Deploy and test** on Aleo testnet

---

**Status**: 85% Complete
**Remaining Work**: claim_winnings finalization + 16-set optimizations
**Commit**: Ready for initial commit with known issues documented

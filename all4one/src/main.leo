// All4One: Privacy-Preserving Anti-Majority Prediction Market
// Version: 1.0 (Aleo-native, privacy-preserving)
//
// Core Mechanics:
// - Users bet privately on outcomes
// - Votes and bet sizes remain hidden until resolution
// - At resolution, the outcome with the FEWEST BETTORS wins (count-based, not stake-based)
// - Rewards use time-segmented conviction logic
// - Early but narrowly losing bettors may receive partial compensation
//
// Pool Allocation (after protocol fee):
// - Winner Base Pool:        55% - Proportional to raw stake
// - Winner Conviction Pool:  35% - Proportional to effective stake (time-weighted)
// - Temporal Compensation:   10% - For early-but-lost bettors
//
// Time Segments (conviction weights):
// - S0 (0-25%):   1.5x  (highest conviction)
// - S1 (25-50%):  1.3x
// - S2 (50-75%):  1.15x
// - S3 (75-100%): 1.0x  (no bonus)
//
// It's not about how much you bet.
// It's about how few agree with you.

program all4one.aleo {

    // ============================================
    // CONSTANTS (scaled by 1000 for precision)
    // ============================================

    // Pool distribution (in basis points, 10000 = 100%)
    const BASE_POOL_BPS: u64 = 5500u64;           // 55%
    const CONVICTION_POOL_BPS: u64 = 3500u64;     // 35%
    const COMPENSATION_POOL_BPS: u64 = 1000u64;   // 10%

    // Protocol fee (in basis points)
    const PROTOCOL_FEE_BPS: u64 = 200u64;         // 2%

    // Conviction weights (scaled by 100 for precision)
    const WEIGHT_S0: u64 = 150u64;                // 1.5x
    const WEIGHT_S1: u64 = 130u64;                // 1.3x
    const WEIGHT_S2: u64 = 115u64;                // 1.15x
    const WEIGHT_S3: u64 = 100u64;                // 1.0x

    // Compensation cap (30% of original stake max)
    const COMPENSATION_CAP_BPS: u64 = 3000u64;    // 30%

    // Number of segments
    const NUM_SEGMENTS: u8 = 4u8;

    // ============================================
    // DATA STRUCTURES
    // ============================================

    // Market configuration - public so users can discover markets
    struct MarketConfig {
        creator: address,           // Who created the market
        resolver: address,          // Who can resolve the market
        start_block: u32,           // Block when betting opens
        end_block: u32,             // Block when betting closes
        segment_blocks: u32,        // Blocks per segment (end_block - start_block) / 4
        question_hash: field,       // Hash of the question
        min_bettors: u64,           // Minimum bettors per side for valid resolution
        fee_recipient: address,     // Where protocol fees go
    }

    // Resolution result - only visible after market resolves
    struct Resolution {
        minority_outcome: u8,           // Which side (0 or 1) is minority by COUNT
        outcome_0_count: u64,           // Number of bettors on outcome 0
        outcome_1_count: u64,           // Number of bettors on outcome 1
        outcome_0_pool: u64,            // Total amount bet on outcome 0
        outcome_1_pool: u64,            // Total amount bet on outcome 1
        outcome_0_effective: u64,       // Effective stake (time-weighted) outcome 0
        outcome_1_effective: u64,       // Effective stake (time-weighted) outcome 1
        distributable_pool: u64,        // Total after protocol fee
        is_valid: bool,                 // Whether resolution met minimum entropy
    }

    // Per-segment aggregation data (for temporal compensation calculation)
    struct SegmentData {
        outcome_0_count: u64,
        outcome_1_count: u64,
        outcome_0_pool: u64,
        outcome_1_pool: u64,
    }

    // ============================================
    // PUBLIC MAPPINGS (On-Chain State)
    // ============================================

    // Market registry: market_id => MarketConfig
    mapping markets: field => MarketConfig;

    // Market status: market_id => is_active
    mapping market_active: field => bool;

    // Total pool per market (hidden per-outcome breakdown)
    mapping total_pool: field => u64;

    // Total bettor count per market
    mapping bettor_count: field => u64;

    // Resolution results: market_id => Resolution
    mapping resolutions: field => Resolution;

    // Segment data for compensation: hash(market_id, segment) => SegmentData
    mapping segment_snapshots: field => SegmentData;

    // Winner payouts: hash(market_id, bettor) => payout_amount
    mapping payouts: field => u64;

    // Compensation payouts: hash(market_id, bettor) => compensation_amount
    mapping compensations: field => u64;

    // Claim tracking: hash(market_id, bettor) => has_claimed
    mapping claims: field => bool;

    // Protocol fees collected: market_id => fee_amount
    mapping fees_collected: field => u64;

    // ============================================
    // PRIVATE RECORDS
    // ============================================

    // Private bet record - owned by bettor, proves their bet for claiming
    // Includes segment for conviction weight calculation
    record Bet {
        owner: address,             // The bettor
        market_id: field,           // Which market
        outcome: u8,                // Their vote: 0 or 1
        amount: u64,                // How much they bet
        segment: u8,                // Time segment when bet was placed (0-3)
    }

    // Bet commitment - owned by resolver for off-chain aggregation
    record BetCommitment {
        owner: address,             // The resolver address
        market_id: field,
        outcome: u8,
        amount: u64,
        segment: u8,
        bettor: address,            // Original bettor
    }

    // Payout record - winner's claim to their winnings
    record RewardPayout {
        owner: address,             // The recipient
        market_id: field,
        base_reward: u64,           // From base pool
        conviction_reward: u64,     // From conviction pool
        compensation: u64,          // From temporal compensation (losers only)
        total: u64,                 // Total payout
    }

    // ============================================
    // HELPER FUNCTIONS
    // ============================================

    // Get conviction weight for a segment (scaled by 100)
    inline get_conviction_weight(segment: u8) -> u64 {
        if segment == 0u8 {
            return WEIGHT_S0;
        } else if segment == 1u8 {
            return WEIGHT_S1;
        } else if segment == 2u8 {
            return WEIGHT_S2;
        } else {
            return WEIGHT_S3;
        }
    }

    // Calculate effective stake (amount * conviction_weight / 100)
    inline calculate_effective_stake(amount: u64, segment: u8) -> u64 {
        let weight: u64 = get_conviction_weight(segment);
        return amount * weight / 100u64;
    }

    // Calculate compensation weight for eligible losers
    // k_i = amount * (weight - 100) / 100
    inline calculate_compensation_weight(amount: u64, segment: u8) -> u64 {
        let weight: u64 = get_conviction_weight(segment);
        if weight <= 100u64 {
            return 0u64; // Final segment gets no compensation
        }
        return amount * (weight - 100u64) / 100u64;
    }

    // ============================================
    // TRANSITIONS
    // ============================================

    // 1. CREATE MARKET
    // Creates a new betting market with time segments
    transition create_market(
        public question_hash: field,
        public start_block: u32,
        public end_block: u32,
        public resolver: address,
        public min_bettors: u64,
        public fee_recipient: address
    ) -> field {
        // Validate inputs
        assert(end_block > start_block);
        assert(min_bettors >= 1u64);

        // Calculate segment length
        let duration: u32 = end_block - start_block;
        let segment_blocks: u32 = duration / 4u32;
        assert(segment_blocks > 0u32);

        // Generate unique market ID
        let market_id: field = BHP256::hash_to_field(question_hash);

        return market_id then finalize(
            market_id,
            self.caller,
            resolver,
            start_block,
            end_block,
            segment_blocks,
            question_hash,
            min_bettors,
            fee_recipient
        );
    }

    finalize create_market(
        market_id: field,
        creator: address,
        resolver: address,
        start_block: u32,
        end_block: u32,
        segment_blocks: u32,
        question_hash: field,
        min_bettors: u64,
        fee_recipient: address
    ) {
        let config: MarketConfig = MarketConfig {
            creator: creator,
            resolver: resolver,
            start_block: start_block,
            end_block: end_block,
            segment_blocks: segment_blocks,
            question_hash: question_hash,
            min_bettors: min_bettors,
            fee_recipient: fee_recipient,
        };

        Mapping::set(markets, market_id, config);
        Mapping::set(market_active, market_id, true);
        Mapping::set(total_pool, market_id, 0u64);
        Mapping::set(bettor_count, market_id, 0u64);

        // Initialize segment snapshots
        let empty_segment: SegmentData = SegmentData {
            outcome_0_count: 0u64,
            outcome_1_count: 0u64,
            outcome_0_pool: 0u64,
            outcome_1_pool: 0u64,
        };

        let seg0_key: field = BHP256::hash_to_field(market_id + 0field);
        let seg1_key: field = BHP256::hash_to_field(market_id + 1field);
        let seg2_key: field = BHP256::hash_to_field(market_id + 2field);
        let seg3_key: field = BHP256::hash_to_field(market_id + 3field);

        Mapping::set(segment_snapshots, seg0_key, empty_segment);
        Mapping::set(segment_snapshots, seg1_key, empty_segment);
        Mapping::set(segment_snapshots, seg2_key, empty_segment);
        Mapping::set(segment_snapshots, seg3_key, empty_segment);
    }

    // 2. PLACE BET (Private with time segment)
    // User places a private bet - their choice AND timing are hidden
    transition place_bet(
        public market_id: field,
        outcome: u8,                    // Private: 0 or 1
        amount: u64,                    // Private: bet amount
        public resolver: address,       // Must match market resolver
        public current_block: u32       // Current block height for segment calculation
    ) -> (Bet, BetCommitment) {
        // Validate outcome is binary
        assert(outcome == 0u8 || outcome == 1u8);

        // Bet amount must be positive
        assert(amount > 0u64);

        // Segment will be calculated in finalize based on block height
        // For now, we pass a placeholder that will be verified
        let segment: u8 = 0u8; // Placeholder, actual segment set based on block

        // Create bet record for bettor
        let bet: Bet = Bet {
            owner: self.caller,
            market_id: market_id,
            outcome: outcome,
            amount: amount,
            segment: segment,
        };

        // Create commitment record for resolver
        let commitment: BetCommitment = BetCommitment {
            owner: resolver,
            market_id: market_id,
            outcome: outcome,
            amount: amount,
            segment: segment,
            bettor: self.caller,
        };

        return (bet, commitment) then finalize(market_id, amount, resolver, current_block);
    }

    finalize place_bet(
        market_id: field,
        amount: u64,
        resolver: address,
        current_block: u32
    ) {
        // Verify market exists and is active
        let config: MarketConfig = Mapping::get(markets, market_id);
        let active: bool = Mapping::get(market_active, market_id);
        assert(active);

        // Verify resolver matches
        assert_eq(resolver, config.resolver);

        // Verify within betting window
        assert(current_block >= config.start_block);
        assert(current_block < config.end_block);

        // Calculate segment (0-3) based on block position
        let blocks_elapsed: u32 = current_block - config.start_block;
        let segment_index: u32 = blocks_elapsed / config.segment_blocks;
        // Cap at segment 3
        let segment: u8 = if segment_index >= 4u32 { 3u8 } else { segment_index as u8 };

        // Update total pool
        let current_pool: u64 = Mapping::get_or_use(total_pool, market_id, 0u64);
        Mapping::set(total_pool, market_id, current_pool + amount);

        // Increment bettor count
        let current_count: u64 = Mapping::get_or_use(bettor_count, market_id, 0u64);
        Mapping::set(bettor_count, market_id, current_count + 1u64);
    }

    // 3. CLOSE MARKET
    // Resolver closes the market to new bets
    transition close_market(public market_id: field) {
        return then finalize(market_id, self.caller);
    }

    finalize close_market(
        market_id: field,
        caller: address
    ) {
        let config: MarketConfig = Mapping::get(markets, market_id);
        assert_eq(caller, config.resolver);
        Mapping::set(market_active, market_id, false);
    }

    // 4. RESOLVE MARKET
    // Resolver submits aggregated results with effective stake calculations
    // Minority determined by COUNT (not amount)
    transition resolve_market(
        public market_id: field,
        public outcome_0_count: u64,
        public outcome_1_count: u64,
        public outcome_0_pool: u64,
        public outcome_1_pool: u64,
        public outcome_0_effective: u64,    // Sum of effective stakes for outcome 0
        public outcome_1_effective: u64     // Sum of effective stakes for outcome 1
    ) {
        return then finalize(
            market_id,
            outcome_0_count,
            outcome_1_count,
            outcome_0_pool,
            outcome_1_pool,
            outcome_0_effective,
            outcome_1_effective,
            self.caller
        );
    }

    finalize resolve_market(
        market_id: field,
        outcome_0_count: u64,
        outcome_1_count: u64,
        outcome_0_pool: u64,
        outcome_1_pool: u64,
        outcome_0_effective: u64,
        outcome_1_effective: u64,
        caller: address
    ) {
        // Only resolver can resolve
        let config: MarketConfig = Mapping::get(markets, market_id);
        assert_eq(caller, config.resolver);

        // Market must be closed
        let active: bool = Mapping::get(market_active, market_id);
        assert(!active);

        // Verify pool totals match recorded total
        let recorded_pool: u64 = Mapping::get(total_pool, market_id);
        assert_eq(recorded_pool, outcome_0_pool + outcome_1_pool);

        // Calculate protocol fee
        let fee: u64 = recorded_pool * PROTOCOL_FEE_BPS / 10000u64;
        let distributable_pool: u64 = recorded_pool - fee;

        // Record fee
        Mapping::set(fees_collected, market_id, fee);

        // Check minimum entropy (enough bettors on each side)
        let is_valid: bool = outcome_0_count >= config.min_bettors &&
                             outcome_1_count >= config.min_bettors;

        // Determine minority by COUNT (not amount!)
        // In case of tie, outcome 0 wins (arbitrary but deterministic)
        let minority_outcome: u8 = 0u8;
        if (outcome_1_count < outcome_0_count) {
            minority_outcome = 1u8;
        }

        // Store resolution
        let resolution: Resolution = Resolution {
            minority_outcome: minority_outcome,
            outcome_0_count: outcome_0_count,
            outcome_1_count: outcome_1_count,
            outcome_0_pool: outcome_0_pool,
            outcome_1_pool: outcome_1_pool,
            outcome_0_effective: outcome_0_effective,
            outcome_1_effective: outcome_1_effective,
            distributable_pool: distributable_pool,
            is_valid: is_valid,
        };

        Mapping::set(resolutions, market_id, resolution);
    }

    // 5. CALCULATE WINNER PAYOUT
    // Resolver calculates payout for a winning bettor (minority side)
    // Uses dual-pool distribution: base (55%) + conviction (35%)
    transition calculate_winner_payout(
        commitment: BetCommitment,
        public base_reward: u64,
        public conviction_reward: u64
    ) {
        return then finalize(
            commitment.market_id,
            commitment.outcome,
            commitment.amount,
            commitment.segment,
            commitment.bettor,
            base_reward,
            conviction_reward,
            self.caller
        );
    }

    finalize calculate_winner_payout(
        market_id: field,
        outcome: u8,
        bet_amount: u64,
        segment: u8,
        bettor: address,
        base_reward: u64,
        conviction_reward: u64,
        caller: address
    ) {
        // Get resolution
        let resolution: Resolution = Mapping::get(resolutions, market_id);
        assert(resolution.is_valid);

        // Bet must be on minority side
        assert_eq(outcome, resolution.minority_outcome);

        // Verify caller is resolver
        let config: MarketConfig = Mapping::get(markets, market_id);
        assert_eq(caller, config.resolver);

        // Calculate pool shares
        let base_pool: u64 = resolution.distributable_pool * BASE_POOL_BPS / 10000u64;
        let conviction_pool: u64 = resolution.distributable_pool * CONVICTION_POOL_BPS / 10000u64;

        // Get minority totals
        let minority_pool: u64 = if resolution.minority_outcome == 0u8 {
            resolution.outcome_0_pool
        } else {
            resolution.outcome_1_pool
        };

        let minority_effective: u64 = if resolution.minority_outcome == 0u8 {
            resolution.outcome_0_effective
        } else {
            resolution.outcome_1_effective
        };

        // Verify base reward calculation
        // base_reward = bet_amount * base_pool / minority_pool
        let expected_base: u64 = bet_amount * base_pool / minority_pool;
        assert(base_reward <= expected_base + 1u64); // Allow 1 unit rounding tolerance

        // Verify conviction reward calculation
        // conviction_reward = effective_stake * conviction_pool / minority_effective
        let effective_stake: u64 = bet_amount * get_conviction_weight(segment) / 100u64;
        let expected_conviction: u64 = effective_stake * conviction_pool / minority_effective;
        assert(conviction_reward <= expected_conviction + 1u64);

        // Record total payout
        let total_payout: u64 = base_reward + conviction_reward;
        let claim_key: field = BHP256::hash_to_field(bettor);
        let unique_key: field = BHP256::hash_to_field(claim_key + market_id);
        Mapping::set(payouts, unique_key, total_payout);
    }

    // 6. CALCULATE TEMPORAL COMPENSATION
    // For early-but-lost bettors who showed conviction
    // Only for segments S0, S1, S2 (not S3)
    transition calculate_compensation(
        commitment: BetCommitment,
        public compensation_amount: u64,
        public was_segment_minority: bool    // Was this outcome minority at segment end?
    ) {
        return then finalize(
            commitment.market_id,
            commitment.outcome,
            commitment.amount,
            commitment.segment,
            commitment.bettor,
            compensation_amount,
            was_segment_minority,
            self.caller
        );
    }

    finalize calculate_compensation(
        market_id: field,
        outcome: u8,
        bet_amount: u64,
        segment: u8,
        bettor: address,
        compensation_amount: u64,
        was_segment_minority: bool,
        caller: address
    ) {
        // Get resolution
        let resolution: Resolution = Mapping::get(resolutions, market_id);
        assert(resolution.is_valid);

        // Bet must NOT be on minority side (this is for losers)
        assert(outcome != resolution.minority_outcome);

        // Verify caller is resolver
        let config: MarketConfig = Mapping::get(markets, market_id);
        assert_eq(caller, config.resolver);

        // Only segments 0, 1, 2 are eligible (not final segment)
        assert(segment < 3u8);

        // Must have been minority at segment end
        assert(was_segment_minority);

        // Calculate compensation pool
        let comp_pool: u64 = resolution.distributable_pool * COMPENSATION_POOL_BPS / 10000u64;

        // Calculate compensation weight
        let weight: u64 = get_conviction_weight(segment);
        let comp_weight: u64 = bet_amount * (weight - 100u64) / 100u64;

        // Verify compensation doesn't exceed cap (30% of original stake)
        let max_comp: u64 = bet_amount * COMPENSATION_CAP_BPS / 10000u64;
        assert(compensation_amount <= max_comp);

        // Record compensation
        let claim_key: field = BHP256::hash_to_field(bettor);
        let unique_key: field = BHP256::hash_to_field(claim_key + market_id);
        Mapping::set(compensations, unique_key, compensation_amount);
    }

    // 7. CLAIM WINNER REWARD
    // Winner uses their Bet record to claim their payout
    transition claim_reward(bet: Bet) -> RewardPayout {
        return RewardPayout {
            owner: bet.owner,
            market_id: bet.market_id,
            base_reward: 0u64,
            conviction_reward: 0u64,
            compensation: 0u64,
            total: bet.amount,  // Placeholder, actual from mapping
        } then finalize(bet.market_id, bet.outcome, bet.owner);
    }

    finalize claim_reward(
        market_id: field,
        outcome: u8,
        bettor: address
    ) {
        // Get resolution
        let resolution: Resolution = Mapping::get(resolutions, market_id);
        assert(resolution.is_valid);

        // Bet must be on minority side
        assert_eq(outcome, resolution.minority_outcome);

        // Check not already claimed
        let claim_key: field = BHP256::hash_to_field(bettor);
        let unique_key: field = BHP256::hash_to_field(claim_key + market_id);
        let already_claimed: bool = Mapping::get_or_use(claims, unique_key, false);
        assert(!already_claimed);

        // Verify payout was calculated
        let payout: u64 = Mapping::get(payouts, unique_key);
        assert(payout > 0u64);

        // Mark as claimed
        Mapping::set(claims, unique_key, true);
    }

    // 8. CLAIM COMPENSATION
    // Eligible losers can claim temporal compensation
    transition claim_compensation(bet: Bet) -> RewardPayout {
        return RewardPayout {
            owner: bet.owner,
            market_id: bet.market_id,
            base_reward: 0u64,
            conviction_reward: 0u64,
            compensation: bet.amount,  // Placeholder
            total: bet.amount,
        } then finalize(bet.market_id, bet.outcome, bet.owner);
    }

    finalize claim_compensation(
        market_id: field,
        outcome: u8,
        bettor: address
    ) {
        // Get resolution
        let resolution: Resolution = Mapping::get(resolutions, market_id);
        assert(resolution.is_valid);

        // Bet must NOT be on minority side (losers only)
        assert(outcome != resolution.minority_outcome);

        // Check not already claimed
        let claim_key: field = BHP256::hash_to_field(bettor);
        let unique_key: field = BHP256::hash_to_field(claim_key + market_id);
        let already_claimed: bool = Mapping::get_or_use(claims, unique_key, false);
        assert(!already_claimed);

        // Verify compensation was calculated
        let comp: u64 = Mapping::get(compensations, unique_key);
        assert(comp > 0u64);

        // Mark as claimed
        Mapping::set(claims, unique_key, true);
    }

    // 9. REFUND (for invalid markets)
    // If market doesn't meet minimum entropy, bettors get refunds
    transition refund(bet: Bet) -> RewardPayout {
        return RewardPayout {
            owner: bet.owner,
            market_id: bet.market_id,
            base_reward: 0u64,
            conviction_reward: 0u64,
            compensation: 0u64,
            total: bet.amount,
        } then finalize(bet.market_id, bet.owner);
    }

    finalize refund(
        market_id: field,
        bettor: address
    ) {
        // Get resolution
        let resolution: Resolution = Mapping::get(resolutions, market_id);

        // Market must be INVALID (not enough entropy)
        assert(!resolution.is_valid);

        // Check not already refunded
        let claim_key: field = BHP256::hash_to_field(bettor);
        let unique_key: field = BHP256::hash_to_field(claim_key + market_id);
        let already_claimed: bool = Mapping::get_or_use(claims, unique_key, false);
        assert(!already_claimed);

        // Mark as refunded
        Mapping::set(claims, unique_key, true);
    }

    // 10. WITHDRAW PROTOCOL FEES
    // Fee recipient can withdraw collected fees
    transition withdraw_fees(public market_id: field) {
        return then finalize(market_id, self.caller);
    }

    finalize withdraw_fees(
        market_id: field,
        caller: address
    ) {
        let config: MarketConfig = Mapping::get(markets, market_id);
        assert_eq(caller, config.fee_recipient);

        // Clear fees (in real implementation, would transfer tokens)
        Mapping::set(fees_collected, market_id, 0u64);
    }
}

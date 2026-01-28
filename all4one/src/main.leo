// All4One: Privacy-Preserving Anti-Majority Prediction Market
// Version: 1.0 (Aleo-native, privacy-preserving)
//
// Core Mechanics:
// - Users bet privately on outcomes
// - Votes and bet sizes remain hidden until resolution
// - At resolution, the outcome with the FEWEST BETTORS wins (count-based)
// - Rewards use time-segmented conviction logic
// - Early but narrowly losing bettors may receive partial compensation
//
// It's not about how much you bet.
// It's about how few agree with you.

program all4one.aleo {

    // Pool distribution (basis points, 10000 = 100%)
    const BASE_POOL_BPS: u64 = 5500u64;
    const CONVICTION_POOL_BPS: u64 = 3500u64;
    const COMPENSATION_POOL_BPS: u64 = 1000u64;
    const PROTOCOL_FEE_BPS: u64 = 100u64;      // 1% protocol fee (fixed)
    const MAX_MAKER_FEE_BPS: u64 = 200u64;     // 2% max market maker fee
    const COMPENSATION_CAP_BPS: u64 = 3000u64;

    // Minimum market duration (~6 hours at 10s blocks)
    const MIN_DURATION_BLOCKS: u32 = 2160u32;

    // Conviction weights (scaled by 100)
    const WEIGHT_S0: u64 = 150u64;
    const WEIGHT_S1: u64 = 130u64;
    const WEIGHT_S2: u64 = 115u64;
    const WEIGHT_S3: u64 = 100u64;

    struct MarketConfig {
        creator: address,
        resolver: address,
        start_block: u32,
        end_block: u32,
        segment_blocks: u32,
        question_hash: field,
        min_bettors: u64,
        bet_amount: u64,           // Fixed bet amount - everyone bets exactly this
        fee_recipient: address,
        maker_fee_bps: u64,
    }

    struct Resolution {
        minority_outcome: u8,
        outcome_0_count: u64,
        outcome_1_count: u64,
        outcome_0_pool: u64,
        outcome_1_pool: u64,
        outcome_0_effective: u64,
        outcome_1_effective: u64,
        distributable_pool: u64,
        is_valid: bool,
    }

    mapping markets: field => MarketConfig;
    mapping market_active: field => bool;
    mapping total_pool: field => u64;
    mapping bettor_count: field => u64;
    mapping resolutions: field => Resolution;
    mapping payouts: field => u64;
    mapping compensations: field => u64;
    mapping claims: field => bool;
    mapping fees_collected: field => u64;
    mapping maker_fees: field => u64;

    record MarketReceipt {
        owner: address,
        market_id: field,
    }

    record Bet {
        owner: address,
        market_id: field,
        outcome: u8,
        amount: u64,
        segment: u8,
    }

    record Commitment {
        owner: address,
        market_id: field,
        outcome: u8,
        amount: u64,
        segment: u8,
        bettor: address,
    }

    record RewardPayout {
        owner: address,
        market_id: field,
        amount: u64,
    }

    // 1. CREATE MARKET
    async transition create_market(
        public question_hash: field,
        public start_block: u32,
        public end_block: u32,
        public resolver: address,
        public min_bettors: u64,
        public bet_amount: u64,
        public fee_recipient: address,
        public maker_fee_bps: u64
    ) -> (MarketReceipt, Future) {
        assert(end_block > start_block);
        assert(min_bettors >= 1u64);
        // Fixed bet amount must be positive
        assert(bet_amount > 0u64);
        let duration: u32 = end_block - start_block;
        // Minimum 6 hours duration
        assert(duration >= MIN_DURATION_BLOCKS);
        // Market maker fee capped at 2%
        assert(maker_fee_bps <= MAX_MAKER_FEE_BPS);
        let segment_blocks: u32 = duration / 4u32;
        assert(segment_blocks > 0u32);
        let market_id: field = BHP256::hash_to_field(question_hash);
        let receipt: MarketReceipt = MarketReceipt { owner: self.caller, market_id: market_id };
        return (receipt, finalize_create_market(market_id, self.caller, resolver, start_block, end_block, segment_blocks, question_hash, min_bettors, bet_amount, fee_recipient, maker_fee_bps));
    }

    async function finalize_create_market(
        market_id: field,
        creator: address,
        resolver: address,
        start_block: u32,
        end_block: u32,
        segment_blocks: u32,
        question_hash: field,
        min_bettors: u64,
        bet_amount: u64,
        fee_recipient: address,
        maker_fee_bps: u64
    ) {
        let config: MarketConfig = MarketConfig {
            creator: creator,
            resolver: resolver,
            start_block: start_block,
            end_block: end_block,
            segment_blocks: segment_blocks,
            question_hash: question_hash,
            min_bettors: min_bettors,
            bet_amount: bet_amount,
            fee_recipient: fee_recipient,
            maker_fee_bps: maker_fee_bps,
        };
        Mapping::set(markets, market_id, config);
        Mapping::set(market_active, market_id, true);
        Mapping::set(total_pool, market_id, 0u64);
        Mapping::set(bettor_count, market_id, 0u64);
    }

    // 2. PLACE BET (Fixed amount per market - prevents sybil attacks)
    async transition place_bet(
        public market_id: field,
        outcome: u8,
        public amount: u64,
        segment: u8,
        public resolver: address
    ) -> (Bet, Commitment, Future) {
        assert(outcome == 0u8 || outcome == 1u8);
        assert(amount > 0u64);
        assert(segment <= 3u8);
        let bet: Bet = Bet { owner: self.caller, market_id: market_id, outcome: outcome, amount: amount, segment: segment };
        let commitment: Commitment = Commitment { owner: resolver, market_id: market_id, outcome: outcome, amount: amount, segment: segment, bettor: self.caller };
        return (bet, commitment, finalize_place_bet(market_id, amount, resolver));
    }

    async function finalize_place_bet(market_id: field, amount: u64, resolver: address) {
        let config: MarketConfig = Mapping::get(markets, market_id);
        let active: bool = Mapping::get(market_active, market_id);
        assert(active);
        assert_eq(resolver, config.resolver);
        // CRITICAL: Enforce fixed bet amount - prevents sybil attacks
        assert_eq(amount, config.bet_amount);
        let current_pool: u64 = Mapping::get_or_use(total_pool, market_id, 0u64);
        Mapping::set(total_pool, market_id, current_pool + amount);
        let current_count: u64 = Mapping::get_or_use(bettor_count, market_id, 0u64);
        Mapping::set(bettor_count, market_id, current_count + 1u64);
    }

    // 3. CLOSE MARKET
    async transition close_market(public market_id: field) -> Future {
        return finalize_close_market(market_id, self.caller);
    }

    async function finalize_close_market(market_id: field, caller: address) {
        let config: MarketConfig = Mapping::get(markets, market_id);
        assert_eq(caller, config.resolver);
        Mapping::set(market_active, market_id, false);
    }

    // 4. RESOLVE MARKET
    async transition resolve_market(
        public market_id: field,
        public outcome_0_count: u64,
        public outcome_1_count: u64,
        public outcome_0_pool: u64,
        public outcome_1_pool: u64,
        public outcome_0_effective: u64,
        public outcome_1_effective: u64
    ) -> Future {
        return finalize_resolve_market(market_id, outcome_0_count, outcome_1_count, outcome_0_pool, outcome_1_pool, outcome_0_effective, outcome_1_effective, self.caller);
    }

    async function finalize_resolve_market(
        market_id: field,
        outcome_0_count: u64,
        outcome_1_count: u64,
        outcome_0_pool: u64,
        outcome_1_pool: u64,
        outcome_0_effective: u64,
        outcome_1_effective: u64,
        caller: address
    ) {
        let config: MarketConfig = Mapping::get(markets, market_id);
        assert_eq(caller, config.resolver);
        let active: bool = Mapping::get(market_active, market_id);
        assert(!active);
        let recorded_pool: u64 = Mapping::get(total_pool, market_id);
        assert_eq(recorded_pool, outcome_0_pool + outcome_1_pool);
        // Calculate protocol fee (1% fixed)
        let protocol_fee: u64 = recorded_pool * PROTOCOL_FEE_BPS / 10000u64;
        // Calculate market maker fee (0-2% set by creator)
        let maker_fee: u64 = recorded_pool * config.maker_fee_bps / 10000u64;
        let total_fees: u64 = protocol_fee + maker_fee;
        let distributable_pool: u64 = recorded_pool - total_fees;
        // Store fees separately
        Mapping::set(fees_collected, market_id, protocol_fee);
        Mapping::set(maker_fees, market_id, maker_fee);
        let is_valid: bool = outcome_0_count >= config.min_bettors && outcome_1_count >= config.min_bettors;
        // Minority by COUNT (not amount!) - use ternary for async function
        let minority_outcome: u8 = outcome_1_count < outcome_0_count ? 1u8 : 0u8;
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
    async transition calc_winner_payout(commitment: Commitment, public base_reward: u64, public conviction_reward: u64) -> Future {
        return finalize_calc_winner_payout(commitment.market_id, commitment.outcome, commitment.amount, commitment.segment, commitment.bettor, base_reward, conviction_reward, self.caller);
    }

    async function finalize_calc_winner_payout(
        market_id: field,
        outcome: u8,
        bet_amount: u64,
        segment: u8,
        bettor: address,
        base_reward: u64,
        conviction_reward: u64,
        caller: address
    ) {
        let resolution: Resolution = Mapping::get(resolutions, market_id);
        assert(resolution.is_valid);
        assert_eq(outcome, resolution.minority_outcome);
        let config: MarketConfig = Mapping::get(markets, market_id);
        assert_eq(caller, config.resolver);
        let total_payout: u64 = base_reward + conviction_reward;
        let claim_key: field = BHP256::hash_to_field(bettor);
        let unique_key: field = BHP256::hash_to_field(claim_key + market_id);
        Mapping::set(payouts, unique_key, total_payout);
    }

    // 6. CALCULATE TEMPORAL COMPENSATION
    async transition calc_compensation(commitment: Commitment, public compensation_amount: u64) -> Future {
        return finalize_calc_compensation(commitment.market_id, commitment.outcome, commitment.amount, commitment.segment, commitment.bettor, compensation_amount, self.caller);
    }

    async function finalize_calc_compensation(
        market_id: field,
        outcome: u8,
        bet_amount: u64,
        segment: u8,
        bettor: address,
        compensation_amount: u64,
        caller: address
    ) {
        let resolution: Resolution = Mapping::get(resolutions, market_id);
        assert(resolution.is_valid);
        assert(outcome != resolution.minority_outcome);
        let config: MarketConfig = Mapping::get(markets, market_id);
        assert_eq(caller, config.resolver);
        assert(segment < 3u8);
        let max_comp: u64 = bet_amount * COMPENSATION_CAP_BPS / 10000u64;
        assert(compensation_amount <= max_comp);
        let claim_key: field = BHP256::hash_to_field(bettor);
        let unique_key: field = BHP256::hash_to_field(claim_key + market_id);
        Mapping::set(compensations, unique_key, compensation_amount);
    }

    // 7. CLAIM WINNER REWARD
    async transition claim_reward(bet: Bet) -> (RewardPayout, Future) {
        let payout: RewardPayout = RewardPayout { owner: bet.owner, market_id: bet.market_id, amount: bet.amount };
        return (payout, finalize_claim_reward(bet.market_id, bet.outcome, bet.owner));
    }

    async function finalize_claim_reward(market_id: field, outcome: u8, bettor: address) {
        let resolution: Resolution = Mapping::get(resolutions, market_id);
        assert(resolution.is_valid);
        assert_eq(outcome, resolution.minority_outcome);
        let claim_key: field = BHP256::hash_to_field(bettor);
        let unique_key: field = BHP256::hash_to_field(claim_key + market_id);
        let already_claimed: bool = Mapping::get_or_use(claims, unique_key, false);
        assert(!already_claimed);
        let payout: u64 = Mapping::get(payouts, unique_key);
        assert(payout > 0u64);
        Mapping::set(claims, unique_key, true);
    }

    // 8. CLAIM COMPENSATION
    async transition claim_compensation(bet: Bet) -> (RewardPayout, Future) {
        let payout: RewardPayout = RewardPayout { owner: bet.owner, market_id: bet.market_id, amount: bet.amount };
        return (payout, finalize_claim_compensation(bet.market_id, bet.outcome, bet.owner));
    }

    async function finalize_claim_compensation(market_id: field, outcome: u8, bettor: address) {
        let resolution: Resolution = Mapping::get(resolutions, market_id);
        assert(resolution.is_valid);
        assert(outcome != resolution.minority_outcome);
        let claim_key: field = BHP256::hash_to_field(bettor);
        let unique_key: field = BHP256::hash_to_field(claim_key + market_id);
        let already_claimed: bool = Mapping::get_or_use(claims, unique_key, false);
        assert(!already_claimed);
        let comp: u64 = Mapping::get(compensations, unique_key);
        assert(comp > 0u64);
        Mapping::set(claims, unique_key, true);
    }

    // 9. REFUND
    async transition refund(bet: Bet) -> (RewardPayout, Future) {
        let payout: RewardPayout = RewardPayout { owner: bet.owner, market_id: bet.market_id, amount: bet.amount };
        return (payout, finalize_refund(bet.market_id, bet.owner));
    }

    async function finalize_refund(market_id: field, bettor: address) {
        let resolution: Resolution = Mapping::get(resolutions, market_id);
        assert(!resolution.is_valid);
        let claim_key: field = BHP256::hash_to_field(bettor);
        let unique_key: field = BHP256::hash_to_field(claim_key + market_id);
        let already_claimed: bool = Mapping::get_or_use(claims, unique_key, false);
        assert(!already_claimed);
        Mapping::set(claims, unique_key, true);
    }

    // 10. WITHDRAW PROTOCOL FEES
    async transition withdraw_fees(public market_id: field) -> Future {
        return finalize_withdraw_fees(market_id, self.caller);
    }

    async function finalize_withdraw_fees(market_id: field, caller: address) {
        let config: MarketConfig = Mapping::get(markets, market_id);
        assert_eq(caller, config.fee_recipient);
        Mapping::set(fees_collected, market_id, 0u64);
    }

    // 11. WITHDRAW MARKET MAKER FEES
    async transition withdraw_maker_fees(public market_id: field) -> Future {
        return finalize_withdraw_maker_fees(market_id, self.caller);
    }

    async function finalize_withdraw_maker_fees(market_id: field, caller: address) {
        let config: MarketConfig = Mapping::get(markets, market_id);
        // Only market creator can withdraw maker fees
        assert_eq(caller, config.creator);
        Mapping::set(maker_fees, market_id, 0u64);
    }
}

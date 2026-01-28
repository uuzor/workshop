// Premier League Virtual Betting - Enhanced with Randomness & Multi-Bet Slips
// Features: Random team matching, random scores, multi-bet functionality

program premier_league_betting.aleo {

    // ========================================
    // DATA STRUCTURES
    // ========================================

    struct Team {
        id: u8,
        name_hash: field,
        strength: u8,          // Overall rating 1-100
    }

    struct Season {
        id: u8,
        current_round: u8,     // 1-36
        start_time: u64,
        status: u8,            // 0: scheduled, 1: active, 2: finished
    }

    struct Match {
        id: field,
        season_id: u8,
        round_number: u8,
        home_team: u8,
        away_team: u8,
        home_score: u8,
        away_score: u8,
        status: u8,            // 0: scheduled, 1: finished
    }

    struct Standing {
        team_id: u8,
        season_id: u8,
        points: u32,
        wins: u16,
        draws: u16,
        losses: u16,
        goals_for: u16,
        goals_against: u16,
    }

    // Single bet entry in a slip
    struct BetEntry {
        match_id: field,
        bet_type: u8,          // 1: home, 2: draw, 3: away
        odds: u64,
    }

    // MULTI-BET SLIP - Users can bet on multiple matches at once
    // Now supports up to 4 bets per round!
    record BetSlip {
        owner: address,
        season_id: u8,
        round_number: u8,
        bets: [BetEntry; 4],   // Array of up to 4 bets (4 matches per round)
        num_bets: u8,          // How many bets are active (1-4)
        total_stake: u64,
        parlay_multiplier: u64, // Locked parlay multiplier at bet time
        has_badge_bonus: bool,
        slip_id: field,
    }

    // Winnings record
    record Winnings {
        owner: address,
        amount: u64,
        slip_id: field,
    }

    // ========================================
    // MAPPINGS
    // ========================================

    mapping teams: u8 => Team;
    mapping seasons: u8 => Season;
    mapping matches: field => Match;
    mapping standings: field => Standing;
    mapping season_pool: u8 => u64;
    mapping season_betting_volume: u8 => u64;
    mapping house_balance: u8 => u64;
    mapping round_start_times: field => u64;
    mapping match_outcomes: field => u8;

    // Track which teams are matched in current round
    mapping round_team_matched: field => bool;  // key = hash(season_id + round + team_id)

    // Track round status
    mapping round_status: field => u8;  // key = hash(season_id + round), value: 0=open, 1=betting, 2=ended

    // VIRTUAL PARIMUTUEL: Locked odds (calculated at round start, never change)
    // Odds stored in basis points (e.g., 150 = 1.5x, 210 = 2.1x)
    mapping locked_home_odds: field => u64;  // match_id => home win odds
    mapping locked_away_odds: field => u64;  // match_id => away win odds
    mapping locked_draw_odds: field => u64;  // match_id => draw odds

    // Count-based parlay tiers (FOMO mechanism)
    mapping round_parlay_count: field => u8;  // round_key => number of parlays placed

    // ========================================
    // TEAM MANAGEMENT
    // ========================================

    async transition add_team(
        public team_id: u8,
        public name_hash: field,
        public strength: u8
    ) -> Future {
        return finalize_add_team(team_id, name_hash, strength);
    }

    async function finalize_add_team(
        public team_id: u8,
        public name_hash: field,
        public strength: u8
    ) {
        assert(team_id >= 1u8 && team_id <= 20u8);
        assert(strength >= 1u8 && strength <= 100u8);

        Mapping::set(teams, team_id, Team {
            id: team_id,
            name_hash: name_hash,
            strength: strength,
        });
    }

    // ========================================
    // SEASON MANAGEMENT
    // ========================================

    async transition start_season(
        public season_id: u8,
        public start_time: u64
    ) -> Future {
        return finalize_start_season(season_id, start_time);
    }

    async function finalize_start_season(
        public season_id: u8,
        public start_time: u64
    ) {
        Mapping::set(seasons, season_id, Season {
            id: season_id,
            current_round: 0u8,  // Will be 1 when first round starts
            start_time: start_time,
            status: 1u8,  // active
        });

        Mapping::set(season_pool, season_id, 0u64);
        Mapping::set(season_betting_volume, season_id, 0u64);
    }

    // ========================================
    // ROUND MANAGEMENT WITH RANDOM MATCHING
    // ========================================

    // Start round with random team matching + VIRTUAL PARIMUTUEL ODDS
    // Creates 4 matches and locks odds (1.2x - 2.1x range) in one call
    async transition start_round_random(
        public season_id: u8,
        public round_number: u8,
        public round_time: u64
    ) -> Future {
        return finalize_start_round_random(season_id, round_number, round_time);
    }

    async function finalize_start_round_random(
        public season_id: u8,
        public round_number: u8,
        public round_time: u64
    ) {
        assert(round_number >= 1u8 && round_number <= 36u8);

        // Set round start time (status can be inferred from existence of this value)
        let round_key: field = BHP256::hash_to_field(season_id as field + round_number as field);
        Mapping::set(round_start_times, round_key, round_time);
        // Note: round_parlay_count initialized lazily in finalize_place_bet (saves 1 set operation)

        // Create 4 random matches with virtual parimutuel odds
        for match_num: u8 in 0u8..4u8 {
            // Generate random team IDs (1-20)
            let home_team: u8 = 1u8 + (ChaCha::rand_u8() % 20u8);
            let away_team: u8 = 1u8 + (ChaCha::rand_u8() % 20u8);

            // Ensure different teams
            let away_team_final: u8 = home_team == away_team ?
                (away_team % 20u8) + 1u8 : away_team;

            // Generate unique match ID
            let match_id: field = BHP256::hash_to_field(
                season_id as field + round_number as field + (match_num + 1u8) as field
            );

            // Create and store the match
            Mapping::set(matches, match_id, Match {
                id: match_id,
                season_id: season_id,
                round_number: round_number,
                home_team: home_team,
                away_team: away_team_final,
                home_score: 0u8,
                away_score: 0u8,
                status: 0u8,  // not started
            });

            // CALCULATE AND LOCK VIRTUAL ODDS (1.2x - 2.1x range)
            // Use pseudo-random allocation to create varied odds
            let seed: field = BHP256::hash_to_field(match_id);
            let rand: u8 = (seed as u8) % 100u8;  // 0-99

            // 6-tier allocation system for exciting variance
            let (home_pct, away_pct, draw_pct) = if rand > 80u8 {
                (50u8, 20u8, 30u8)  // HUGE FAVORITE: 1.2x / 2.0x / 1.67x
            } else if rand > 60u8 {
                (45u8, 25u8, 30u8)  // STRONG: 1.33x / 1.8x / 1.67x
            } else if rand > 40u8 {
                (40u8, 30u8, 30u8)  // MODERATE: 1.5x / 1.67x / 1.67x
            } else if rand > 20u8 {
                (35u8, 35u8, 30u8)  // BALANCED: 1.71x / 1.71x / 1.67x
            } else if rand > 10u8 {
                (30u8, 40u8, 30u8)  // AWAY FAVORED: 1.67x / 1.5x / 1.67x
            } else {
                (25u8, 45u8, 30u8)  // AWAY STRONG: 1.8x / 1.33x / 1.67x
            };

            // Calculate raw odds (totalPool / outcomePool)
            // Total virtual pool = 100%, so odds = 100 / percentage
            let raw_home: u64 = (10000u64 / home_pct as u64);  // e.g., 10000/50 = 200 = 2.0x
            let raw_away: u64 = (10000u64 / away_pct as u64);
            let raw_draw: u64 = (10000u64 / draw_pct as u64);

            // Compress to target 1.2x - 2.1x range
            let home_odds: u64 = compress_odds(raw_home);
            let away_odds: u64 = compress_odds(raw_away);
            let draw_odds: u64 = compress_odds(raw_draw);

            // LOCK ODDS (never change after this!)
            Mapping::set(locked_home_odds, match_id, home_odds);
            Mapping::set(locked_away_odds, match_id, away_odds);
            Mapping::set(locked_draw_odds, match_id, draw_odds);
        }

        // Note: Season current_round can be tracked off-chain via round_start_times
        // Removed season update to stay within 16-set limit (2 + 16 = 18 sets total)
    }

    // Compress raw odds to 1.2x - 2.1x profitable range
    // Input: raw_odds in basis points (e.g., 200 = 2.0x)
    // Output: compressed odds (120-210 = 1.2x-2.1x)
    function compress_odds(raw_odds: u64) -> u64 {
        // Minimum: 1.2x (120 basis points)
        if raw_odds < 120u64 { return 120u64; }

        // Maximum: 2.1x (210 basis points)
        if raw_odds > 400u64 { return 210u64; }

        // Linear compression: map 1.2x-4.0x → 1.2x-2.1x
        // Formula: 120 + (raw - 120) × (210 - 120) / (400 - 120)
        // = 120 + (raw - 120) × 90 / 280
        // = 120 + (raw - 120) × 0.32

        let excess: u64 = raw_odds - 120u64;
        let scaled: u64 = (excess * 32u64) / 100u64;
        return 120u64 + scaled;
    }

    // ========================================
    // VIRTUAL PARIMUTUEL MULTI-BET SYSTEM
    // ========================================

    // Place multi-bet slip with virtual parimutuel odds (1-4 matches per round)
    async transition place_multi_bet(
        season_id: u8,
        round_number: u8,
        match_ids: [field; 4],     // Array of match IDs (4 matches per round)
        bet_types: [u8; 4],        // Array of bet types (1=home, 2=away, 3=draw)
        num_bets: u8,              // How many bets (1-4)
        total_stake: u64,
        has_badge: bool
    ) -> (BetSlip, Future) {
        assert(total_stake >= 1u64);
        assert(num_bets >= 1u8 && num_bets <= 4u8);
        assert(bet_types[0u32] >= 1u8 && bet_types[0u32] <= 3u8);

        // Calculate locked odds for each bet (from locked odds mappings)
        // Note: In transition, we can't read mappings, so we use placeholder odds
        // The actual locked odds will be used during settlement in finalize
        let placeholder_odds: u64 = 150u64;  // 1.5x average

        // Create array of BetEntry structs
        let bets: [BetEntry; 4] = [
            BetEntry { match_id: match_ids[0u32], bet_type: bet_types[0u32], odds: placeholder_odds },
            BetEntry { match_id: match_ids[1u32], bet_type: bet_types[1u32], odds: placeholder_odds },
            BetEntry { match_id: match_ids[2u32], bet_type: bet_types[2u32], odds: placeholder_odds },
            BetEntry { match_id: match_ids[3u32], bet_type: bet_types[3u32], odds: placeholder_odds },
        ];

        // Generate slip ID
        let slip_id: field = BHP256::hash_to_field(
            match_ids[0u32] + match_ids[1u32] + total_stake as field
        );

        let bet_slip: BetSlip = BetSlip {
            owner: self.caller,
            season_id: season_id,
            round_number: round_number,
            bets: bets,
            num_bets: num_bets,
            total_stake: total_stake,
            parlay_multiplier: 100u64,  // Will be set in finalize
            has_badge_bonus: has_badge,
            slip_id: slip_id,
        };

        return (bet_slip, finalize_place_bet(season_id, round_number, num_bets));
    }

    // Finalize bet placement: increment parlay count for FOMO tiers
    async function finalize_place_bet(
        public season_id: u8,
        public round_number: u8,
        public num_bets: u8
    ) {
        // Only increment parlay count for multi-bets (2+ matches)
        if num_bets > 1u8 {
            let round_key: field = BHP256::hash_to_field(season_id as field + round_number as field);
            let current_count: u8 = Mapping::get_or_use(round_parlay_count, round_key, 0u8);
            Mapping::set(round_parlay_count, round_key, current_count + 1u8);
        }
    }

    // Calculate count-based parlay multiplier (FOMO mechanism)
    // Returns multiplier in basis points (e.g., 250 = 2.5x)
    function get_parlay_multiplier(parlay_count: u8) -> u64 {
        // Tier 1: First 10 parlays = 2.5x
        if parlay_count < 10u8 { return 250u64; }

        // Tier 2: Parlays 10-19 = 2.2x
        if parlay_count < 20u8 { return 220u64; }

        // Tier 3: Parlays 20-29 = 1.9x
        if parlay_count < 30u8 { return 190u64; }

        // Tier 4: Parlays 30-39 = 1.6x
        if parlay_count < 40u8 { return 160u64; }

        // Tier 5: Parlays 40+ = 1.3x
        return 130u64;
    }

    // ========================================
    // END ROUND WITH RANDOM SCORE GENERATION
    // ========================================

    // End round - resolves all 4 matches at once (no batching needed!)
    async transition end_round(
        public season_id: u8,
        public round_number: u8
    ) -> Future {
        return finalize_end_round(season_id, round_number);
    }

    async function finalize_end_round(
        public season_id: u8,
        public round_number: u8
    ) {
        // Round status can be inferred from match outcomes
        let round_key: field = BHP256::hash_to_field(season_id as field + round_number as field);

        // Resolve all 4 matches using FOR LOOP (no batching needed!)
        for match_num: u8 in 0u8..4u8 {
            // Get match ID
            let match_id: field = BHP256::hash_to_field(
                season_id as field + round_number as field + (match_num + 1u8) as field
            );
            let current_match: Match = Mapping::get(matches, match_id);

            // Generate random scores using ChaCha (0-5 goals typical)
            let home_score: u8 = ChaCha::rand_u8() % 6u8;
            let away_score: u8 = ChaCha::rand_u8() % 6u8;

            // Update match with scores
            Mapping::set(matches, match_id, Match {
                id: current_match.id,
                season_id: current_match.season_id,
                round_number: current_match.round_number,
                home_team: current_match.home_team,
                away_team: current_match.away_team,
                home_score: home_score,
                away_score: away_score,
                status: 1u8,  // finished
            });

            // Determine outcome (1=home, 2=draw, 3=away)
            let outcome: u8 = home_score > away_score ? 1u8 :
                (home_score < away_score ? 3u8 : 2u8);
            Mapping::set(match_outcomes, match_id, outcome);

            // Calculate points for each team
            let home_points_add: u32 = outcome == 1u8 ? 3u32 : (outcome == 2u8 ? 1u32 : 0u32);
            let away_points_add: u32 = outcome == 3u8 ? 3u32 : (outcome == 2u8 ? 1u32 : 0u32);

            // Update home team standings
            let home_key: field = BHP256::hash_to_field(season_id as field + current_match.home_team as field);
            let home_standing: Standing = Mapping::get_or_use(standings, home_key, Standing {
                team_id: current_match.home_team,
                season_id: season_id,
                points: 0u32,
                wins: 0u16,
                draws: 0u16,
                losses: 0u16,
                goals_for: 0u16,
                goals_against: 0u16,
            });

            Mapping::set(standings, home_key, Standing {
                team_id: home_standing.team_id,
                season_id: home_standing.season_id,
                points: home_standing.points + home_points_add,
                wins: home_standing.wins + (outcome == 1u8 ? 1u16 : 0u16),
                draws: home_standing.draws + (outcome == 2u8 ? 1u16 : 0u16),
                losses: home_standing.losses + (outcome == 3u8 ? 1u16 : 0u16),
                goals_for: home_standing.goals_for + home_score as u16,
                goals_against: home_standing.goals_against + away_score as u16,
            });

            // Update away team standings
            let away_key: field = BHP256::hash_to_field(season_id as field + current_match.away_team as field);
            let away_standing: Standing = Mapping::get_or_use(standings, away_key, Standing {
                team_id: current_match.away_team,
                season_id: season_id,
                points: 0u32,
                wins: 0u16,
                draws: 0u16,
                losses: 0u16,
                goals_for: 0u16,
                goals_against: 0u16,
            });

            Mapping::set(standings, away_key, Standing {
                team_id: away_standing.team_id,
                season_id: away_standing.season_id,
                points: away_standing.points + away_points_add,
                wins: away_standing.wins + (outcome == 3u8 ? 1u16 : 0u16),
                draws: away_standing.draws + (outcome == 2u8 ? 1u16 : 0u16),
                losses: away_standing.losses + (outcome == 1u8 ? 1u16 : 0u16),
                goals_for: away_standing.goals_for + away_score as u16,
                goals_against: away_standing.goals_against + home_score as u16,
            });
        }  // end for loop
    }

    // ========================================
    // CLAIM WINNINGS
    // ========================================

    // Claim winnings with virtual parimutuel locked odds
    // Note: For simplicity, payout calculation happens in transition (off-chain reads acceptable for claiming)
    async transition claim_winnings(
        slip: BetSlip
    ) -> (Winnings, Future) {
        // Calculate payout (will be verified in finalize)
        // This is a simplified version - in production, you'd want all logic in finalize
        // For now, we pass through to finalize for validation
        let estimated_payout: u64 = slip.total_stake * 2u64;  // Placeholder

        let winnings: Winnings = Winnings {
            owner: slip.owner,
            amount: estimated_payout,
            slip_id: slip.slip_id,
        };

        return (winnings, finalize_claim_winnings(
            slip.season_id,
            slip.round_number,
            slip.bets,
            slip.num_bets,
            slip.total_stake
        ));
    }

    async function finalize_claim_winnings(
        public season_id: u8,
        public round_number: u8,
        public bets: [BetEntry; 4],
        public num_bets: u8,
        public total_stake: u64
    ) {
        // Validate all bets won (all-or-nothing)
        // Check each active bet
        for i: u8 in 0u8..4u8 {
            if i < num_bets {
                let bet: BetEntry = bets[i as u32];
                let outcome: u8 = Mapping::get(match_outcomes, bet.match_id);

                // Assert bet won (transaction will fail if any bet lost)
                assert(bet.bet_type == outcome);
            }
        }

        // Track betting volume
        let volume: u64 = Mapping::get_or_use(season_betting_volume, season_id, 0u64);
        Mapping::set(season_betting_volume, season_id, volume + total_stake);

        // Protocol fee (5%)
        let protocol_fee: u64 = (total_stake * 500u64) / 10000u64;

        // Season pool (2%)
        let pool_contribution: u64 = (total_stake * 200u64) / 10000u64;

        // Update balances
        let house_total: u64 = Mapping::get_or_use(house_balance, 0u8, 0u64);
        Mapping::set(house_balance, 0u8, house_total + protocol_fee);

        let pool: u64 = Mapping::get_or_use(season_pool, season_id, 0u64);
        Mapping::set(season_pool, season_id, pool + pool_contribution);
    }

    // ========================================
    // HELPER FUNCTIONS
    // ========================================

    // Check if single bet won (off-chain)
    function check_bet_won(
        bet_type: u8,
        home_score: u8,
        away_score: u8
    ) -> bool {
        let outcome: u8 = home_score > away_score ? 1u8 :
            (home_score < away_score ? 3u8 : 2u8);
        return bet_type == outcome;
    }

    // Calculate parlay odds (off-chain)
    function calculate_parlay_odds(
        num_bets: u8,
        single_odds: u64
    ) -> u64 {
        return num_bets == 1u8 ? single_odds :
            num_bets == 2u8 ? (single_odds * single_odds) / 100u64 :
            num_bets == 3u8 ? (single_odds * single_odds * single_odds) / 10000u64 :
            400u64;  // Default multiplier
    }

    // Random scores are generated in finalize_end_round using ChaCha
}

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
    // Now supports up to 10 bets using arrays!
    record BetSlip {
        owner: address,
        season_id: u8,
        round_number: u8,
        bets: [BetEntry; 10],  // Array of up to 10 bets!
        num_bets: u8,          // How many bets are active (1-10)
        total_stake: u64,
        total_odds: u64,       // Accumulated parlay odds
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

    // Start round with random team matching (creates 10 matches)
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

        // Set round status to betting
        let round_key: field = BHP256::hash_to_field(season_id as field + round_number as field);
        Mapping::set(round_status, round_key, 1u8);  // betting open
        Mapping::set(round_start_times, round_key, round_time);

        // Create 10 random matches using FOR LOOP
        for match_num: u8 in 0u8..10u8 {
            // Generate random team IDs (1-20)
            let home_team: u8 = 1u8 + (ChaCha::rand_u8() % 20u8);
            let away_team: u8 = 1u8 + (ChaCha::rand_u8() % 20u8);

            // Ensure different teams
            let away_team_final: u8 = home_team == away_team ?
                (away_team % 20u8) + 1u8 : away_team;

            // Generate unique match ID (season + round + match_number)
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
        }

        // Update season current round
        let season: Season = Mapping::get(seasons, season_id);
        Mapping::set(seasons, season_id, Season {
            id: season.id,
            current_round: round_number,
            start_time: season.start_time,
            status: season.status,
        });
    }

    // ========================================
    // MULTI-BET SLIP FUNCTIONALITY
    // ========================================

    // Place multi-bet slip (1-10 matches) - NOW WITH ARRAYS!
    transition place_multi_bet(
        season_id: u8,
        round_number: u8,
        match_ids: [field; 10],    // Array of match IDs
        bet_types: [u8; 10],       // Array of bet types (1=home, 2=draw, 3=away)
        num_bets: u8,              // How many bets (1-10)
        total_stake: u64,
        has_badge: bool
    ) -> BetSlip {
        assert(total_stake >= 1u64);
        assert(num_bets >= 1u8 && num_bets <= 10u8);
        assert(bet_types[0u32] >= 1u8 && bet_types[0u32] <= 3u8);

        // Calculate odds for each bet (base 2.00x)
        let base_odds: u64 = 200u64;

        // Apply badge bonus if applicable (5%)
        let effective_odds: u64 = has_badge ?
            (base_odds * 105u64) / 100u64 : base_odds;

        // Apply house edge (4%)
        let final_odds: u64 = (effective_odds * 96u64) / 100u64;

        // Create array of BetEntry structs (using manual initialization for now)
        // Note: Leo doesn't support mutable local arrays, so we initialize all at once
        let bets: [BetEntry; 10] = [
            BetEntry { match_id: match_ids[0u32], bet_type: bet_types[0u32], odds: final_odds },
            BetEntry { match_id: match_ids[1u32], bet_type: bet_types[1u32], odds: final_odds },
            BetEntry { match_id: match_ids[2u32], bet_type: bet_types[2u32], odds: final_odds },
            BetEntry { match_id: match_ids[3u32], bet_type: bet_types[3u32], odds: final_odds },
            BetEntry { match_id: match_ids[4u32], bet_type: bet_types[4u32], odds: final_odds },
            BetEntry { match_id: match_ids[5u32], bet_type: bet_types[5u32], odds: final_odds },
            BetEntry { match_id: match_ids[6u32], bet_type: bet_types[6u32], odds: final_odds },
            BetEntry { match_id: match_ids[7u32], bet_type: bet_types[7u32], odds: final_odds },
            BetEntry { match_id: match_ids[8u32], bet_type: bet_types[8u32], odds: final_odds },
            BetEntry { match_id: match_ids[9u32], bet_type: bet_types[9u32], odds: final_odds },
        ];

        // Calculate parlay odds (multiply odds for each bet, dividing after each step to prevent overflow)
        let odds_2: u64 = (final_odds * final_odds) / 100u64;
        let odds_3: u64 = (odds_2 * final_odds) / 100u64;
        let odds_4: u64 = (odds_3 * final_odds) / 100u64;
        let odds_5: u64 = (odds_4 * final_odds) / 100u64;
        let odds_6: u64 = (odds_5 * final_odds) / 100u64;
        let odds_7: u64 = (odds_6 * final_odds) / 100u64;
        let odds_8: u64 = (odds_7 * final_odds) / 100u64;
        let odds_9: u64 = (odds_8 * final_odds) / 100u64;
        let odds_10: u64 = (odds_9 * final_odds) / 100u64;

        let total_odds: u64 = num_bets == 1u8 ? final_odds :
            num_bets == 2u8 ? odds_2 :
            num_bets == 3u8 ? odds_3 :
            num_bets == 4u8 ? odds_4 :
            num_bets == 5u8 ? odds_5 :
            num_bets == 6u8 ? odds_6 :
            num_bets == 7u8 ? odds_7 :
            num_bets == 8u8 ? odds_8 :
            num_bets == 9u8 ? odds_9 :
            odds_10;

        // Generate slip ID
        let slip_id: field = BHP256::hash_to_field(
            match_ids[0u32] + match_ids[1u32] + match_ids[2u32] + total_stake as field
        );

        return BetSlip {
            owner: self.caller,
            season_id: season_id,
            round_number: round_number,
            bets: bets,
            num_bets: num_bets,
            total_stake: total_stake,
            total_odds: total_odds,
            has_badge_bonus: has_badge,
            slip_id: slip_id,
        };
    }

    // ========================================
    // END ROUND WITH RANDOM SCORE GENERATION
    // ========================================

    // End round - resolves matches in batches (Aleo limit: 16 sets per finalize)
    // Call this function 4 times: batch 0-2, 3-5, 6-8, 9
    async transition end_round(
        public season_id: u8,
        public round_number: u8,
        public batch_start: u8  // 0, 3, 6, or 9
    ) -> Future {
        return finalize_end_round(season_id, round_number, batch_start);
    }

    async function finalize_end_round(
        public season_id: u8,
        public round_number: u8,
        public batch_start: u8
    ) {
        // Only mark round as ended on first batch
        if batch_start == 0u8 {
            let round_key: field = BHP256::hash_to_field(season_id as field + round_number as field);
            Mapping::set(round_status, round_key, 2u8);  // ended
        }

        // Determine batch size (3 for batches 0,3,6 and 1 for batch 9)
        let batch_size: u8 = batch_start == 9u8 ? 1u8 : 3u8;

        // Resolve matches in this batch using FOR LOOP
        for offset: u8 in 0u8..3u8 {
            let match_num: u8 = batch_start + offset;

            // Skip if beyond batch size (for last batch)
            if offset < batch_size {
            // Get match ID (same formula as creation)
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
            }  // end if offset < batch_size
        }  // end for loop
    }

    // ========================================
    // CLAIM WINNINGS
    // ========================================

    // Check if bet slip won and claim winnings
    async transition claim_winnings(
        slip: BetSlip
    ) -> (Winnings, Future) {
        // Check each bet in the slip
        let all_won: bool = true;

        // Note: In actual implementation, we'd check all bets
        // For now, simplified to return winnings

        let payout: u64 = slip.total_stake * slip.total_odds / 100u64;

        let winnings: Winnings = Winnings {
            owner: slip.owner,
            amount: payout,
            slip_id: slip.slip_id,
        };

        return (winnings, finalize_claim_winnings(slip.season_id, slip.total_stake));
    }

    async function finalize_claim_winnings(
        public season_id: u8,
        public stake: u64
    ) {
        // Track betting volume
        let volume: u64 = Mapping::get_or_use(season_betting_volume, season_id, 0u64);
        Mapping::set(season_betting_volume, season_id, volume + stake);

        // House edge (4%)
        let house_cut: u64 = (stake * 400u64) / 10000u64;

        // Season pool (2%)
        let pool_contribution: u64 = (stake * 200u64) / 10000u64;

        // Update balances
        let house_total: u64 = Mapping::get_or_use(house_balance, 0u8, 0u64);
        Mapping::set(house_balance, 0u8, house_total + house_cut);

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

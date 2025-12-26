// Premier League Virtual Betting - Enhanced Version
// Seasons with 36 rounds, 10 matches per round, NFT bonuses, season pools

program premier_league_betting.aleo {

    // ========================================
    // DATA STRUCTURES
    // ========================================

    struct Team {
        id: u8,
        name_hash: field,      // Hash of team name
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
        points: u32,           // 3 for win, 1 for draw, 0 for loss
        wins: u16,
        draws: u16,
        losses: u16,
        goals_for: u16,
        goals_against: u16,
    }

    // Match betting ticket
    record MatchBet {
        owner: address,
        match_id: field,
        bet_type: u8,          // 1: home, 2: draw, 3: away
        stake: u64,
        odds: u64,             // Multiplied by 100 (e.g., 200 = 2.00x)
        has_badge_bonus: bool,
        season_id: u8,
    }

    // Season winner bet (free entry)
    record SeasonBet {
        owner: address,
        season_id: u8,
        predicted_winner: u8,
        entry_time: u64,
    }

    // ========================================
    // MAPPINGS
    // ========================================

    // Teams
    mapping teams: u8 => Team;

    // Seasons
    mapping seasons: u8 => Season;

    // Matches
    mapping matches: field => Match;

    // Standings
    mapping standings: field => Standing;  // key = hash(season_id + team_id)

    // Season betting pool (2% of total bets)
    mapping season_pool: u8 => u64;  // season_id => pool amount

    // Total betting volume per season
    mapping season_betting_volume: u8 => u64;

    // House edge collected
    mapping house_balance: u8 => u64;  // key 0 = total house balance

    // Round timing (for 15-minute intervals)
    mapping round_start_times: field => u64;  // key = hash(season_id + round)

    // Match results for settlement
    mapping match_outcomes: field => u8;  // match_id => outcome (1/2/3)

    // ========================================
    // CONSTANTS (in logic)
    // ========================================

    // HOUSE_EDGE: 4% (400/10000)
    // SEASON_POOL_RATE: 2% (200/10000)
    // BADGE_BONUS: 5% (105/100 multiplier)
    // ROUNDS_PER_SEASON: 36
    // MATCHES_PER_ROUND: 10
    // ROUND_INTERVAL: 900 seconds (15 minutes)

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

    // Start a new season
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
            current_round: 1u8,
            start_time: start_time,
            status: 1u8,  // active
        });

        // Initialize season pool
        Mapping::set(season_pool, season_id, 0u64);
        Mapping::set(season_betting_volume, season_id, 0u64);
    }

    // Start a new round
    async transition start_round(
        public season_id: u8,
        public round_number: u8,
        public round_time: u64
    ) -> Future {
        return finalize_start_round(season_id, round_number, round_time);
    }

    async function finalize_start_round(
        public season_id: u8,
        public round_number: u8,
        public round_time: u64
    ) {
        assert(round_number >= 1u8 && round_number <= 36u8);

        // Calculate round timing key
        let round_key: field = BHP256::hash_to_field(season_id as field + round_number as field);
        Mapping::set(round_start_times, round_key, round_time);

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
    // MATCH MANAGEMENT
    // ========================================

    // Schedule a match
    async transition schedule_match(
        public match_id: field,
        public season_id: u8,
        public round_number: u8,
        public home_team: u8,
        public away_team: u8
    ) -> Future {
        return finalize_schedule_match(match_id, season_id, round_number, home_team, away_team);
    }

    async function finalize_schedule_match(
        public match_id: field,
        public season_id: u8,
        public round_number: u8,
        public home_team: u8,
        public away_team: u8
    ) {
        assert(home_team != away_team);
        assert(round_number >= 1u8 && round_number <= 36u8);

        Mapping::set(matches, match_id, Match {
            id: match_id,
            season_id: season_id,
            round_number: round_number,
            home_team: home_team,
            away_team: away_team,
            home_score: 0u8,
            away_score: 0u8,
            status: 0u8,  // scheduled
        });
    }

    // Simulate match and record result
    async transition simulate_match(
        public match_id: field,
        public home_score: u8,
        public away_score: u8
    ) -> Future {
        return finalize_simulate_match(match_id, home_score, away_score);
    }

    async function finalize_simulate_match(
        public match_id: field,
        public home_score: u8,
        public away_score: u8
    ) {
        let match_data: Match = Mapping::get(matches, match_id);

        // Update match with scores
        Mapping::set(matches, match_id, Match {
            id: match_data.id,
            season_id: match_data.season_id,
            round_number: match_data.round_number,
            home_team: match_data.home_team,
            away_team: match_data.away_team,
            home_score: home_score,
            away_score: away_score,
            status: 1u8,  // finished
        });

        // Determine outcome
        let outcome: u8 = home_score > away_score ? 1u8 : (home_score < away_score ? 3u8 : 2u8);
        Mapping::set(match_outcomes, match_id, outcome);

        // Update standings (simplified - just track points)
        let home_key: field = BHP256::hash_to_field(match_data.season_id as field + match_data.home_team as field);
        let away_key: field = BHP256::hash_to_field(match_data.season_id as field + match_data.away_team as field);

        // Get current standings or create defaults
        let home_standing: Standing = Mapping::get_or_use(standings, home_key, Standing {
            team_id: match_data.home_team,
            season_id: match_data.season_id,
            points: 0u32,
            wins: 0u16,
            draws: 0u16,
            losses: 0u16,
            goals_for: 0u16,
            goals_against: 0u16,
        });

        let away_standing: Standing = Mapping::get_or_use(standings, away_key, Standing {
            team_id: match_data.away_team,
            season_id: match_data.season_id,
            points: 0u32,
            wins: 0u16,
            draws: 0u16,
            losses: 0u16,
            goals_for: 0u16,
            goals_against: 0u16,
        });

        // Simple update based on outcome
        let home_points_add: u32 = outcome == 1u8 ? 3u32 : (outcome == 2u8 ? 1u32 : 0u32);
        let away_points_add: u32 = outcome == 3u8 ? 3u32 : (outcome == 2u8 ? 1u32 : 0u32);

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
    }

    // ========================================
    // MATCH BETTING
    // ========================================

    // Place a bet on a match
    transition place_match_bet(
        match_id: field,
        bet_type: u8,
        stake: u64,
        has_badge: bool,
        public season_id: u8
    ) -> MatchBet {
        assert(bet_type >= 1u8 && bet_type <= 3u8);
        assert(stake >= 1u64);

        // Calculate odds (simplified - base 2.00x)
        let base_odds: u64 = 200u64;

        // Apply badge bonus (5% boost = multiply by 1.05)
        let effective_odds: u64 = has_badge ?
            (base_odds * 105u64) / 100u64 :
            base_odds;

        // Apply house edge (4% = multiply by 0.96)
        let final_odds: u64 = (effective_odds * 96u64) / 100u64;

        return MatchBet {
            owner: self.caller,
            match_id: match_id,
            bet_type: bet_type,
            stake: stake,
            odds: final_odds,
            has_badge_bonus: has_badge,
            season_id: season_id,
        };
    }

    // Settle match bet and track pool
    async transition settle_match_bet(
        bet: MatchBet,
        public won: bool
    ) -> Future {
        return finalize_settle_match_bet(bet.season_id, bet.stake, won);
    }

    async function finalize_settle_match_bet(
        public season_id: u8,
        public stake: u64,
        public won: bool
    ) {
        // Add to season betting volume
        let volume: u64 = Mapping::get_or_use(season_betting_volume, season_id, 0u64);
        Mapping::set(season_betting_volume, season_id, volume + stake);

        // Calculate house edge (4%)
        let house_cut: u64 = (stake * 400u64) / 10000u64;

        // Calculate season pool contribution (2%)
        let pool_contribution: u64 = (stake * 200u64) / 10000u64;

        // Update house balance
        let house_total: u64 = Mapping::get_or_use(house_balance, 0u8, 0u64);
        Mapping::set(house_balance, 0u8, house_total + house_cut);

        // Update season pool
        let pool: u64 = Mapping::get_or_use(season_pool, season_id, 0u64);
        Mapping::set(season_pool, season_id, pool + pool_contribution);
    }

    // ========================================
    // SEASON BETTING (FREE)
    // ========================================

    // Place free season bet
    transition place_season_bet(
        public season_id: u8,
        predicted_winner: u8,
        public entry_time: u64
    ) -> SeasonBet {
        assert(predicted_winner >= 1u8 && predicted_winner <= 20u8);

        return SeasonBet {
            owner: self.caller,
            season_id: season_id,
            predicted_winner: predicted_winner,
            entry_time: entry_time,
        };
    }

    // ========================================
    // HELPER FUNCTIONS
    // ========================================

    // Calculate odds based on team strength (off-chain)
    function calculate_odds(
        home_strength: u8,
        away_strength: u8,
        bet_type: u8
    ) -> u64 {
        let diff: u8 = home_strength > away_strength ?
            home_strength - away_strength :
            away_strength - home_strength;

        // Home win odds
        let home_odds: u64 = diff > 20u8 ?
            (home_strength > away_strength ? 150u64 : 400u64) :
            200u64;

        // Return appropriate odds
        return bet_type == 1u8 ? home_odds : (bet_type == 2u8 ? 320u64 : 300u64);
    }

    // Check if bet won (off-chain)
    function check_bet_won(
        bet_type: u8,
        home_score: u8,
        away_score: u8
    ) -> bool {
        let outcome: u8 = home_score > away_score ? 1u8 : (home_score < away_score ? 3u8 : 2u8);
        return bet_type == outcome;
    }

    // Calculate payout (off-chain)
    function calculate_payout(
        stake: u64,
        odds: u64,
        won: bool
    ) -> u64 {
        return won ? (stake * odds) / 100u64 : 0u64;
    }
}

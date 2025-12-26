// Premier League Virtual Betting Game - Simplified Version
// Compatible with Leo 3.4.0

program premier_league_betting.aleo {

    // ========================================
    // DATA STRUCTURES
    // ========================================

    struct Team {
        id: u8,
        strength: u8,
    }

    struct Match {
        id: field,
        home_team: u8,
        away_team: u8,
        status: u8,        // 0: scheduled, 2: finished
    }

    struct MatchResult {
        match_id: field,
        home_score: u8,
        away_score: u8,
    }

    record BettingTicket {
        owner: address,
        match_id: field,
        bet_type: u8,      // 1: home_win, 2: draw, 3: away_win
        stake: u64,
        odds: u64,
    }

    // ========================================
    // MAPPINGS
    // ========================================

    mapping teams: u8 => Team;
    mapping matches: field => Match;
    mapping results: field => MatchResult;
    mapping admins: address => bool;

    // ========================================
    // ADMIN FUNCTIONS
    // ========================================

    // Initialize teams
    async transition add_team(
        public team_id: u8,
        public strength: u8
    ) -> Future {
        return finalize_add_team(self.caller, team_id, strength);
    }

    async function finalize_add_team(
        public admin: address,
        public team_id: u8,
        public strength: u8
    ) {
        // In production, verify admin status
        Mapping::set(teams, team_id, Team {
            id: team_id,
            strength: strength,
        });
    }

    // Schedule a new match
    async transition schedule_match(
        public match_id: field,
        public home_team: u8,
        public away_team: u8
    ) -> Future {
        return finalize_schedule_match(match_id, home_team, away_team);
    }

    async function finalize_schedule_match(
        public match_id: field,
        public home_team: u8,
        public away_team: u8
    ) {
        Mapping::set(matches, match_id, Match {
            id: match_id,
            home_team: home_team,
            away_team: away_team,
            status: 0u8,
        });
    }

    // ========================================
    // BETTING FUNCTIONS
    // ========================================

    // Place a bet - returns only a ticket (no finalize for simplicity)
    transition place_bet(
        match_id: field,
        bet_type: u8,
        stake: u64,
        odds: u64
    ) -> BettingTicket {
        assert(bet_type >= 1u8 && bet_type <= 3u8);
        assert(stake >= 1u64);

        return BettingTicket {
            owner: self.caller,
            match_id: match_id,
            bet_type: bet_type,
            stake: stake,
            odds: odds,
        };
    }

    // ========================================
    // MATCH SIMULATION
    // ========================================

    // Simulate match and store result
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
        // Store result
        Mapping::set(results, match_id, MatchResult {
            match_id: match_id,
            home_score: home_score,
            away_score: away_score,
        });

        // Update match status
        let match_data: Match = Mapping::get(matches, match_id);
        Mapping::set(matches, match_id, Match {
            id: match_data.id,
            home_team: match_data.home_team,
            away_team: match_data.away_team,
            status: 2u8,
        });
    }

    // ========================================
    // HELPER FUNCTIONS
    // ========================================

    // Check if a bet won (off-chain helper)
    function check_bet_won(
        bet_type: u8,
        home_score: u8,
        away_score: u8
    ) -> bool {
        let outcome: u8 = home_score > away_score ? 1u8 : (home_score < away_score ? 3u8 : 2u8);
        return bet_type == outcome;
    }

    // Calculate winnings
    function calculate_winnings(
        stake: u64,
        odds: u64,
        won: bool
    ) -> u64 {
        return won ? (stake * odds) / 100u64 : 0u64;
    }
}

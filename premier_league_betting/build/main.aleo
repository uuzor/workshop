program premier_league_betting.aleo;

record BettingTicket:
    owner as address.private;
    match_id as field.private;
    bet_type as u8.private;
    stake as u64.private;
    odds as u64.private;

struct Team:
    id as u8;
    strength as u8;

struct Match:
    id as field;
    home_team as u8;
    away_team as u8;
    status as u8;

struct MatchResult:
    match_id as field;
    home_score as u8;
    away_score as u8;

mapping teams:
    key as u8.public;
    value as Team.public;

mapping matches:
    key as field.public;
    value as Match.public;

mapping results:
    key as field.public;
    value as MatchResult.public;

mapping admins:
    key as address.public;
    value as boolean.public;

function add_team:
    input r0 as u8.public;
    input r1 as u8.public;
    async add_team self.caller r0 r1 into r2;
    output r2 as premier_league_betting.aleo/add_team.future;

finalize add_team:
    input r0 as address.public;
    input r1 as u8.public;
    input r2 as u8.public;
    cast r1 r2 into r3 as Team;
    set r3 into teams[r1];

function schedule_match:
    input r0 as field.public;
    input r1 as u8.public;
    input r2 as u8.public;
    async schedule_match r0 r1 r2 into r3;
    output r3 as premier_league_betting.aleo/schedule_match.future;

finalize schedule_match:
    input r0 as field.public;
    input r1 as u8.public;
    input r2 as u8.public;
    cast r0 r1 r2 0u8 into r3 as Match;
    set r3 into matches[r0];

function place_bet:
    input r0 as field.private;
    input r1 as u8.private;
    input r2 as u64.private;
    input r3 as u64.private;
    gte r1 1u8 into r4;
    lte r1 3u8 into r5;
    and r4 r5 into r6;
    assert.eq r6 true;
    gte r2 1u64 into r7;
    assert.eq r7 true;
    cast self.caller r0 r1 r2 r3 into r8 as BettingTicket.record;
    output r8 as BettingTicket.record;

function simulate_match:
    input r0 as field.public;
    input r1 as u8.public;
    input r2 as u8.public;
    async simulate_match r0 r1 r2 into r3;
    output r3 as premier_league_betting.aleo/simulate_match.future;

finalize simulate_match:
    input r0 as field.public;
    input r1 as u8.public;
    input r2 as u8.public;
    cast r0 r1 r2 into r3 as MatchResult;
    set r3 into results[r0];
    get matches[r0] into r4;
    cast r4.id r4.home_team r4.away_team 2u8 into r5 as Match;
    set r5 into matches[r0];

closure check_bet_won:
    input r0 as u8;
    input r1 as u8;
    input r2 as u8;
    gt r1 r2 into r3;
    lt r1 r2 into r4;
    ternary r4 3u8 2u8 into r5;
    ternary r3 1u8 r5 into r6;
    is.eq r0 r6 into r7;
    output r7 as boolean;

closure calculate_winnings:
    input r0 as u64;
    input r1 as u64;
    input r2 as boolean;
    mul r0 r1 into r3;
    div r3 100u64 into r4;
    ternary r2 r4 0u64 into r5;
    output r5 as u64;

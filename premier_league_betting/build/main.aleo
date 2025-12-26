program premier_league_betting.aleo;

record MatchBet:
    owner as address.private;
    match_id as field.private;
    bet_type as u8.private;
    stake as u64.private;
    odds as u64.private;
    has_badge_bonus as boolean.private;
    season_id as u8.private;

record SeasonBet:
    owner as address.private;
    season_id as u8.private;
    predicted_winner as u8.private;
    entry_time as u64.private;

struct Team:
    id as u8;
    name_hash as field;
    strength as u8;

struct Season:
    id as u8;
    current_round as u8;
    start_time as u64;
    status as u8;

struct Match:
    id as field;
    season_id as u8;
    round_number as u8;
    home_team as u8;
    away_team as u8;
    home_score as u8;
    away_score as u8;
    status as u8;

struct Standing:
    team_id as u8;
    season_id as u8;
    points as u32;
    wins as u16;
    draws as u16;
    losses as u16;
    goals_for as u16;
    goals_against as u16;

mapping teams:
    key as u8.public;
    value as Team.public;

mapping seasons:
    key as u8.public;
    value as Season.public;

mapping matches:
    key as field.public;
    value as Match.public;

mapping standings:
    key as field.public;
    value as Standing.public;

mapping season_pool:
    key as u8.public;
    value as u64.public;

mapping season_betting_volume:
    key as u8.public;
    value as u64.public;

mapping house_balance:
    key as u8.public;
    value as u64.public;

mapping round_start_times:
    key as field.public;
    value as u64.public;

mapping match_outcomes:
    key as field.public;
    value as u8.public;

function add_team:
    input r0 as u8.public;
    input r1 as field.public;
    input r2 as u8.public;
    async add_team r0 r1 r2 into r3;
    output r3 as premier_league_betting.aleo/add_team.future;

finalize add_team:
    input r0 as u8.public;
    input r1 as field.public;
    input r2 as u8.public;
    gte r0 1u8 into r3;
    lte r0 20u8 into r4;
    and r3 r4 into r5;
    assert.eq r5 true;
    gte r2 1u8 into r6;
    lte r2 100u8 into r7;
    and r6 r7 into r8;
    assert.eq r8 true;
    cast r0 r1 r2 into r9 as Team;
    set r9 into teams[r0];

function start_season:
    input r0 as u8.public;
    input r1 as u64.public;
    async start_season r0 r1 into r2;
    output r2 as premier_league_betting.aleo/start_season.future;

finalize start_season:
    input r0 as u8.public;
    input r1 as u64.public;
    cast r0 1u8 r1 1u8 into r2 as Season;
    set r2 into seasons[r0];
    set 0u64 into season_pool[r0];
    set 0u64 into season_betting_volume[r0];

function start_round:
    input r0 as u8.public;
    input r1 as u8.public;
    input r2 as u64.public;
    async start_round r0 r1 r2 into r3;
    output r3 as premier_league_betting.aleo/start_round.future;

finalize start_round:
    input r0 as u8.public;
    input r1 as u8.public;
    input r2 as u64.public;
    gte r1 1u8 into r3;
    lte r1 36u8 into r4;
    and r3 r4 into r5;
    assert.eq r5 true;
    cast r0 into r6 as field;
    cast r1 into r7 as field;
    add r6 r7 into r8;
    hash.bhp256 r8 into r9 as field;
    set r2 into round_start_times[r9];
    get seasons[r0] into r10;
    cast r10.id r1 r10.start_time r10.status into r11 as Season;
    set r11 into seasons[r0];

function schedule_match:
    input r0 as field.public;
    input r1 as u8.public;
    input r2 as u8.public;
    input r3 as u8.public;
    input r4 as u8.public;
    async schedule_match r0 r1 r2 r3 r4 into r5;
    output r5 as premier_league_betting.aleo/schedule_match.future;

finalize schedule_match:
    input r0 as field.public;
    input r1 as u8.public;
    input r2 as u8.public;
    input r3 as u8.public;
    input r4 as u8.public;
    is.neq r3 r4 into r5;
    assert.eq r5 true;
    gte r2 1u8 into r6;
    lte r2 36u8 into r7;
    and r6 r7 into r8;
    assert.eq r8 true;
    cast r0 r1 r2 r3 r4 0u8 0u8 0u8 into r9 as Match;
    set r9 into matches[r0];

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
    get matches[r0] into r3;
    cast r3.id r3.season_id r3.round_number r3.home_team r3.away_team r1 r2 1u8 into r4 as Match;
    set r4 into matches[r0];
    gt r1 r2 into r5;
    lt r1 r2 into r6;
    ternary r6 3u8 2u8 into r7;
    ternary r5 1u8 r7 into r8;
    set r8 into match_outcomes[r0];
    cast r3.season_id into r9 as field;
    cast r3.home_team into r10 as field;
    add r9 r10 into r11;
    hash.bhp256 r11 into r12 as field;
    cast r3.season_id into r13 as field;
    cast r3.away_team into r14 as field;
    add r13 r14 into r15;
    hash.bhp256 r15 into r16 as field;
    cast r3.home_team r3.season_id 0u32 0u16 0u16 0u16 0u16 0u16 into r17 as Standing;
    get.or_use standings[r12] r17 into r18;
    cast r3.away_team r3.season_id 0u32 0u16 0u16 0u16 0u16 0u16 into r19 as Standing;
    get.or_use standings[r16] r19 into r20;
    is.eq r8 1u8 into r21;
    is.eq r8 2u8 into r22;
    ternary r22 1u32 0u32 into r23;
    ternary r21 3u32 r23 into r24;
    is.eq r8 3u8 into r25;
    ternary r25 3u32 r23 into r26;
    add r18.points r24 into r27;
    ternary r21 1u16 0u16 into r28;
    add r18.wins r28 into r29;
    ternary r22 1u16 0u16 into r30;
    add r18.draws r30 into r31;
    ternary r25 1u16 0u16 into r32;
    add r18.losses r32 into r33;
    cast r1 into r34 as u16;
    add r18.goals_for r34 into r35;
    cast r2 into r36 as u16;
    add r18.goals_against r36 into r37;
    cast r18.team_id r18.season_id r27 r29 r31 r33 r35 r37 into r38 as Standing;
    set r38 into standings[r12];
    add r20.points r26 into r39;
    add r20.wins r32 into r40;
    add r20.draws r30 into r41;
    add r20.losses r28 into r42;
    cast r2 into r43 as u16;
    add r20.goals_for r43 into r44;
    cast r1 into r45 as u16;
    add r20.goals_against r45 into r46;
    cast r20.team_id r20.season_id r39 r40 r41 r42 r44 r46 into r47 as Standing;
    set r47 into standings[r16];

function place_match_bet:
    input r0 as field.private;
    input r1 as u8.private;
    input r2 as u64.private;
    input r3 as boolean.private;
    input r4 as u8.public;
    gte r1 1u8 into r5;
    lte r1 3u8 into r6;
    and r5 r6 into r7;
    assert.eq r7 true;
    gte r2 1u64 into r8;
    assert.eq r8 true;
    mul 200u64 105u64 into r9;
    div r9 100u64 into r10;
    ternary r3 r10 200u64 into r11;
    mul r11 96u64 into r12;
    div r12 100u64 into r13;
    cast self.caller r0 r1 r2 r13 r3 r4 into r14 as MatchBet.record;
    output r14 as MatchBet.record;

function settle_match_bet:
    input r0 as MatchBet.record;
    input r1 as boolean.public;
    async settle_match_bet r0.season_id r0.stake r1 into r2;
    output r2 as premier_league_betting.aleo/settle_match_bet.future;

finalize settle_match_bet:
    input r0 as u8.public;
    input r1 as u64.public;
    input r2 as boolean.public;
    get.or_use season_betting_volume[r0] 0u64 into r3;
    add r3 r1 into r4;
    set r4 into season_betting_volume[r0];
    mul r1 400u64 into r5;
    div r5 10000u64 into r6;
    mul r1 200u64 into r7;
    div r7 10000u64 into r8;
    get.or_use house_balance[0u8] 0u64 into r9;
    add r9 r6 into r10;
    set r10 into house_balance[0u8];
    get.or_use season_pool[r0] 0u64 into r11;
    add r11 r8 into r12;
    set r12 into season_pool[r0];

function place_season_bet:
    input r0 as u8.public;
    input r1 as u8.private;
    input r2 as u64.public;
    gte r1 1u8 into r3;
    lte r1 20u8 into r4;
    and r3 r4 into r5;
    assert.eq r5 true;
    cast self.caller r0 r1 r2 into r6 as SeasonBet.record;
    output r6 as SeasonBet.record;

closure calculate_odds:
    input r0 as u8;
    input r1 as u8;
    input r2 as u8;
    gt r0 r1 into r3;
    sub r0 r1 into r4;
    sub r1 r0 into r5;
    ternary r3 r4 r5 into r6;
    gt r6 20u8 into r7;
    ternary r3 150u64 400u64 into r8;
    ternary r7 r8 200u64 into r9;
    is.eq r2 1u8 into r10;
    is.eq r2 2u8 into r11;
    ternary r11 320u64 300u64 into r12;
    ternary r10 r9 r12 into r13;
    output r13 as u64;

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

closure calculate_payout:
    input r0 as u64;
    input r1 as u64;
    input r2 as boolean;
    mul r0 r1 into r3;
    div r3 100u64 into r4;
    ternary r2 r4 0u64 into r5;
    output r5 as u64;

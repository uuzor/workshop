program premier_league_betting.aleo;

struct BetEntry:
    match_id as field;
    bet_type as u8;
    odds as u64;

record BetSlip:
    owner as address.private;
    season_id as u8.private;
    round_number as u8.private;
    bet1 as BetEntry.private;
    bet2 as BetEntry.private;
    bet3 as BetEntry.private;
    bet4 as BetEntry.private;
    bet5 as BetEntry.private;
    total_stake as u64.private;
    total_odds as u64.private;
    has_badge_bonus as boolean.private;
    slip_id as field.private;

record Winnings:
    owner as address.private;
    amount as u64.private;
    slip_id as field.private;

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

mapping round_team_matched:
    key as field.public;
    value as boolean.public;

mapping round_status:
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
    cast r0 0u8 r1 1u8 into r2 as Season;
    set r2 into seasons[r0];
    set 0u64 into season_pool[r0];
    set 0u64 into season_betting_volume[r0];

function start_round_random:
    input r0 as u8.public;
    input r1 as u8.public;
    input r2 as u64.public;
    async start_round_random r0 r1 r2 into r3;
    output r3 as premier_league_betting.aleo/start_round_random.future;

finalize start_round_random:
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
    set 1u8 into round_status[r9];
    set r2 into round_start_times[r9];
    rand.chacha into r10 as u8;
    rem r10 20u8 into r11;
    add 1u8 r11 into r12;
    rand.chacha into r13 as u8;
    rem r13 20u8 into r14;
    add 1u8 r14 into r15;
    is.eq r12 r15 into r16;
    rem r15 20u8 into r17;
    add r17 1u8 into r18;
    ternary r16 r18 r15 into r19;
    cast r0 into r20 as field;
    cast r1 into r21 as field;
    add r20 r21 into r22;
    add r22 1field into r23;
    hash.bhp256 r23 into r24 as field;
    cast r24 r0 r1 r12 r19 0u8 0u8 0u8 into r25 as Match;
    set r25 into matches[r24];
    get seasons[r0] into r26;
    cast r26.id r1 r26.start_time r26.status into r27 as Season;
    set r27 into seasons[r0];

function place_multi_bet:
    input r0 as u8.private;
    input r1 as u8.private;
    input r2 as field.private;
    input r3 as u8.private;
    input r4 as field.private;
    input r5 as u8.private;
    input r6 as field.private;
    input r7 as u8.private;
    input r8 as field.private;
    input r9 as u8.private;
    input r10 as field.private;
    input r11 as u8.private;
    input r12 as u64.private;
    input r13 as boolean.private;
    gte r12 1u64 into r14;
    assert.eq r14 true;
    gte r3 1u8 into r15;
    lte r3 3u8 into r16;
    and r15 r16 into r17;
    assert.eq r17 true;
    mul 200u64 105u64 into r18;
    div r18 100u64 into r19;
    ternary r13 r19 200u64 into r20;
    mul r20 96u64 into r21;
    div r21 100u64 into r22;
    is.neq r4 0field into r23;
    ternary r23 1u8 0u8 into r24;
    add 1u8 r24 into r25;
    is.neq r6 0field into r26;
    ternary r26 1u8 0u8 into r27;
    add r25 r27 into r28;
    is.neq r8 0field into r29;
    ternary r29 1u8 0u8 into r30;
    add r28 r30 into r31;
    is.neq r10 0field into r32;
    ternary r32 1u8 0u8 into r33;
    add r31 r33 into r34;
    is.eq r34 1u8 into r35;
    is.eq r34 2u8 into r36;
    mul r22 r22 into r37;
    div r37 100u64 into r38;
    is.eq r34 3u8 into r39;
    mul r37 r22 into r40;
    div r40 10000u64 into r41;
    is.eq r34 4u8 into r42;
    mul r40 r22 into r43;
    div r43 1000000u64 into r44;
    mul r43 r22 into r45;
    div r45 100000000u64 into r46;
    ternary r42 r44 r46 into r47;
    ternary r39 r41 r47 into r48;
    ternary r36 r38 r48 into r49;
    ternary r35 r22 r49 into r50;
    add r2 r4 into r51;
    add r51 r6 into r52;
    add r52 r8 into r53;
    add r53 r10 into r54;
    cast r12 into r55 as field;
    add r54 r55 into r56;
    hash.bhp256 r56 into r57 as field;
    cast r2 r3 r22 into r58 as BetEntry;
    cast r4 r5 r22 into r59 as BetEntry;
    cast r6 r7 r22 into r60 as BetEntry;
    cast r8 r9 r22 into r61 as BetEntry;
    cast r10 r11 r22 into r62 as BetEntry;
    cast self.caller r0 r1 r58 r59 r60 r61 r62 r12 r50 r13 r57 into r63 as BetSlip.record;
    output r63 as BetSlip.record;

function end_round:
    input r0 as u8.public;
    input r1 as u8.public;
    async end_round r0 r1 into r2;
    output r2 as premier_league_betting.aleo/end_round.future;

finalize end_round:
    input r0 as u8.public;
    input r1 as u8.public;
    cast r0 into r2 as field;
    cast r1 into r3 as field;
    add r2 r3 into r4;
    hash.bhp256 r4 into r5 as field;
    set 2u8 into round_status[r5];
    cast r0 into r6 as field;
    cast r1 into r7 as field;
    add r6 r7 into r8;
    add r8 1field into r9;
    hash.bhp256 r9 into r10 as field;
    get matches[r10] into r11;
    rand.chacha into r12 as u8;
    rem r12 6u8 into r13;
    rand.chacha into r14 as u8;
    rem r14 6u8 into r15;
    cast r11.id r11.season_id r11.round_number r11.home_team r11.away_team r13 r15 1u8 into r16 as Match;
    set r16 into matches[r10];
    gt r13 r15 into r17;
    lt r13 r15 into r18;
    ternary r18 3u8 2u8 into r19;
    ternary r17 1u8 r19 into r20;
    set r20 into match_outcomes[r10];
    is.eq r20 1u8 into r21;
    is.eq r20 2u8 into r22;
    ternary r22 1u32 0u32 into r23;
    ternary r21 3u32 r23 into r24;
    is.eq r20 3u8 into r25;
    cast r0 into r26 as field;
    cast r11.home_team into r27 as field;
    add r26 r27 into r28;
    hash.bhp256 r28 into r29 as field;
    cast r11.home_team r0 0u32 0u16 0u16 0u16 0u16 0u16 into r30 as Standing;
    get.or_use standings[r29] r30 into r31;
    add r31.points r24 into r32;
    ternary r21 1u16 0u16 into r33;
    add r31.wins r33 into r34;
    ternary r22 1u16 0u16 into r35;
    add r31.draws r35 into r36;
    ternary r25 1u16 0u16 into r37;
    add r31.losses r37 into r38;
    cast r13 into r39 as u16;
    add r31.goals_for r39 into r40;
    cast r15 into r41 as u16;
    add r31.goals_against r41 into r42;
    cast r31.team_id r31.season_id r32 r34 r36 r38 r40 r42 into r43 as Standing;
    set r43 into standings[r29];

function claim_winnings:
    input r0 as BetSlip.record;
    mul r0.total_stake r0.total_odds into r1;
    div r1 100u64 into r2;
    cast r0.owner r2 r0.slip_id into r3 as Winnings.record;
    async claim_winnings r0.season_id r0.total_stake into r4;
    output r3 as Winnings.record;
    output r4 as premier_league_betting.aleo/claim_winnings.future;

finalize claim_winnings:
    input r0 as u8.public;
    input r1 as u64.public;
    get.or_use season_betting_volume[r0] 0u64 into r2;
    add r2 r1 into r3;
    set r3 into season_betting_volume[r0];
    mul r1 400u64 into r4;
    div r4 10000u64 into r5;
    mul r1 200u64 into r6;
    div r6 10000u64 into r7;
    get.or_use house_balance[0u8] 0u64 into r8;
    add r8 r5 into r9;
    set r9 into house_balance[0u8];
    get.or_use season_pool[r0] 0u64 into r10;
    add r10 r7 into r11;
    set r11 into season_pool[r0];

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

closure calculate_parlay_odds:
    input r0 as u8;
    input r1 as u64;
    is.eq r0 1u8 into r2;
    is.eq r0 2u8 into r3;
    mul r1 r1 into r4;
    div r4 100u64 into r5;
    is.eq r0 3u8 into r6;
    mul r4 r1 into r7;
    div r7 10000u64 into r8;
    ternary r6 r8 400u64 into r9;
    ternary r3 r5 r9 into r10;
    ternary r2 r1 r10 into r11;
    output r11 as u64;

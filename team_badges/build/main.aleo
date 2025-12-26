program team_badges.aleo;

record TeamBadge:
    owner as address.private;
    team_id as u8.private;
    badge_id as field.private;
    mint_number as u32.private;
    rarity as u8.private;

record Listing:
    owner as address.private;
    badge_id as field.private;
    team_id as u8.private;
    price as u64.private;
    listing_id as field.private;

mapping team_mint_count:
    key as u8.public;
    value as u32.public;

mapping badge_owners:
    key as field.public;
    value as address.public;

mapping active_listings:
    key as field.public;
    value as boolean.public;

mapping total_sales:
    key as u8.public;
    value as u64.public;

mapping marketplace_fees:
    key as u8.public;
    value as u64.public;

mapping badge_bonuses:
    key as u8.public;
    value as u8.public;

function set_badge_bonus:
    input r0 as u8.public;
    input r1 as u8.public;
    async set_badge_bonus r0 r1 into r2;
    output r2 as team_badges.aleo/set_badge_bonus.future;

finalize set_badge_bonus:
    input r0 as u8.public;
    input r1 as u8.public;
    set r1 into badge_bonuses[r0];

function mint_badge:
    input r0 as u8.public;
    input r1 as address.private;
    input r2 as u8.private;
    gte r0 1u8 into r3;
    lte r0 20u8 into r4;
    and r3 r4 into r5;
    assert.eq r5 true;
    gte r2 1u8 into r6;
    lte r2 3u8 into r7;
    and r6 r7 into r8;
    assert.eq r8 true;
    cast r0 into r9 as field;
    cast r2 into r10 as field;
    add r9 r10 into r11;
    hash.bhp256 r11 into r12 as field;
    cast r1 r0 r12 0u32 r2 into r13 as TeamBadge.record;
    async mint_badge r0 r12 r1 into r14;
    output r13 as TeamBadge.record;
    output r14 as team_badges.aleo/mint_badge.future;

finalize mint_badge:
    input r0 as u8.public;
    input r1 as field.public;
    input r2 as address.public;
    get.or_use team_mint_count[r0] 0u32 into r3;
    add r3 1u32 into r4;
    set r4 into team_mint_count[r0];
    set r2 into badge_owners[r1];

function list_badge:
    input r0 as TeamBadge.record;
    input r1 as u64.public;
    cast r1 into r2 as field;
    add r0.badge_id r2 into r3;
    hash.bhp256 r3 into r4 as field;
    cast r0.owner r0.badge_id r0.team_id r1 r4 into r5 as Listing.record;
    async list_badge r4 r0.badge_id into r6;
    output r5 as Listing.record;
    output r6 as team_badges.aleo/list_badge.future;

finalize list_badge:
    input r0 as field.public;
    input r1 as field.public;
    set true into active_listings[r0];

function buy_badge:
    input r0 as Listing.record;
    input r1 as address.public;
    mul r0.price 250u64 into r2;
    div r2 10000u64 into r3;
    cast r1 r0.team_id r0.badge_id 0u32 1u8 into r4 as TeamBadge.record;
    async buy_badge r0.listing_id r0.badge_id r1 r0.price r3 into r5;
    output r4 as TeamBadge.record;
    output r5 as team_badges.aleo/buy_badge.future;

finalize buy_badge:
    input r0 as field.public;
    input r1 as field.public;
    input r2 as address.public;
    input r3 as u64.public;
    input r4 as u64.public;
    set false into active_listings[r0];
    set r2 into badge_owners[r1];
    get.or_use total_sales[0u8] 0u64 into r5;
    add r5 r3 into r6;
    set r6 into total_sales[0u8];
    get.or_use marketplace_fees[0u8] 0u64 into r7;
    add r7 r4 into r8;
    set r8 into marketplace_fees[0u8];

function cancel_listing:
    input r0 as Listing.record;
    cast r0.owner r0.team_id r0.badge_id 0u32 1u8 into r1 as TeamBadge.record;
    async cancel_listing r0.listing_id into r2;
    output r1 as TeamBadge.record;
    output r2 as team_badges.aleo/cancel_listing.future;

finalize cancel_listing:
    input r0 as field.public;
    set false into active_listings[r0];

function transfer_badge:
    input r0 as TeamBadge.record;
    input r1 as address.private;
    cast r1 r0.team_id r0.badge_id r0.mint_number r0.rarity into r2 as TeamBadge.record;
    async transfer_badge r0.badge_id r1 into r3;
    output r2 as TeamBadge.record;
    output r3 as team_badges.aleo/transfer_badge.future;

finalize transfer_badge:
    input r0 as field.public;
    input r1 as address.public;
    set r1 into badge_owners[r0];

closure get_badge_bonus:
    input r0 as u8;
    gt r0 0u8 into r1;
    ternary r1 5u8 0u8 into r2;
    output r2 as u8;

closure has_badge_bonus:
    input r0 as boolean;
    assert.eq true true;
    output r0 as boolean;

closure calculate_marketplace_fee:
    input r0 as u64;
    mul r0 250u64 into r1;
    div r1 10000u64 into r2;
    output r2 as u64;

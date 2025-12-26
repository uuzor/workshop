program league_token.aleo;

record token:
    owner as address.private;
    amount as u64.private;

mapping account:
    key as address.public;
    value as u64.public;

mapping airdrop_claimed:
    key as address.public;
    value as boolean.public;

mapping airdrop_allocation:
    key as address.public;
    value as u64.public;

mapping total_supply:
    key as u8.public;
    value as u64.public;

mapping airdrop_remaining:
    key as u8.public;
    value as u64.public;

function initialize_supply:
    async initialize_supply into r0;
    output r0 as league_token.aleo/initialize_supply.future;

finalize initialize_supply:
    set 1000000000u64 into total_supply[0u8];
    set 300000000u64 into airdrop_remaining[0u8];

function set_airdrop_allocation:
    input r0 as address.public;
    input r1 as u64.public;
    async set_airdrop_allocation r0 r1 into r2;
    output r2 as league_token.aleo/set_airdrop_allocation.future;

finalize set_airdrop_allocation:
    input r0 as address.public;
    input r1 as u64.public;
    set r1 into airdrop_allocation[r0];

function mint_public:
    input r0 as address.public;
    input r1 as u64.public;
    async mint_public r0 r1 into r2;
    output r2 as league_token.aleo/mint_public.future;

finalize mint_public:
    input r0 as address.public;
    input r1 as u64.public;
    get.or_use account[r0] 0u64 into r2;
    add r2 r1 into r3;
    set r3 into account[r0];

function mint_private:
    input r0 as address.private;
    input r1 as u64.private;
    cast r0 r1 into r2 as token.record;
    output r2 as token.record;

function claim_airdrop:
    cast self.caller 100u64 into r0 as token.record;
    async claim_airdrop self.caller 100u64 into r1;
    output r0 as token.record;
    output r1 as league_token.aleo/claim_airdrop.future;

finalize claim_airdrop:
    input r0 as address.public;
    input r1 as u64.public;
    get.or_use airdrop_claimed[r0] false into r2;
    assert.eq r2 false;
    get.or_use airdrop_remaining[0u8] 0u64 into r3;
    gte r3 r1 into r4;
    assert.eq r4 true;
    set true into airdrop_claimed[r0];
    sub r3 r1 into r5;
    set r5 into airdrop_remaining[0u8];

function transfer_public:
    input r0 as address.public;
    input r1 as u64.public;
    async transfer_public self.caller r0 r1 into r2;
    output r2 as league_token.aleo/transfer_public.future;

finalize transfer_public:
    input r0 as address.public;
    input r1 as address.public;
    input r2 as u64.public;
    get.or_use account[r0] 0u64 into r3;
    sub r3 r2 into r4;
    set r4 into account[r0];
    get.or_use account[r1] 0u64 into r5;
    add r5 r2 into r6;
    set r6 into account[r1];

function transfer_private:
    input r0 as token.record;
    input r1 as address.private;
    input r2 as u64.private;
    sub r0.amount r2 into r3;
    cast r0.owner r3 into r4 as token.record;
    cast r1 r2 into r5 as token.record;
    output r4 as token.record;
    output r5 as token.record;

function transfer_priv_to_pub:
    input r0 as token.record;
    input r1 as address.public;
    input r2 as u64.public;
    sub r0.amount r2 into r3;
    cast r0.owner r3 into r4 as token.record;
    async transfer_priv_to_pub r1 r2 into r5;
    output r4 as token.record;
    output r5 as league_token.aleo/transfer_priv_to_pub.future;

finalize transfer_priv_to_pub:
    input r0 as address.public;
    input r1 as u64.public;
    get.or_use account[r0] 0u64 into r2;
    add r2 r1 into r3;
    set r3 into account[r0];

function transfer_pub_to_priv:
    input r0 as address.public;
    input r1 as u64.public;
    cast r0 r1 into r2 as token.record;
    async transfer_pub_to_priv self.caller r1 into r3;
    output r2 as token.record;
    output r3 as league_token.aleo/transfer_pub_to_priv.future;

finalize transfer_pub_to_priv:
    input r0 as address.public;
    input r1 as u64.public;
    get.or_use account[r0] 0u64 into r2;
    sub r2 r1 into r3;
    set r3 into account[r0];

closure get_balance:
    input r0 as u64;
    assert.eq true true;
    output r0 as u64;

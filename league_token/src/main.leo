// $LEAGUE Token - Platform utility token for Premier League Betting
// 30% airdrop allocation for early users

program league_token.aleo {

    // ========================================
    // DATA STRUCTURES
    // ========================================

    record token {
        owner: address,
        amount: u64,
    }

    // ========================================
    // MAPPINGS
    // ========================================

    // Public balances
    mapping account: address => u64;

    // Airdrop tracking
    mapping airdrop_claimed: address => bool;
    mapping airdrop_allocation: address => u64;

    // Total supply tracking
    mapping total_supply: u8 => u64;  // key 0 = total supply
    mapping airdrop_remaining: u8 => u64;  // key 0 = remaining airdrop

    // ========================================
    // CONSTANTS (embedded in logic)
    // ========================================

    // Total Supply: 1,000,000,000 $LEAGUE
    // Airdrop Pool: 300,000,000 $LEAGUE (30%)
    // Airdrop per user: 100 $LEAGUE (for 3M users max)

    // ========================================
    // ADMIN FUNCTIONS
    // ========================================

    // Initialize token supply
    async transition initialize_supply() -> Future {
        return finalize_initialize_supply();
    }

    async function finalize_initialize_supply() {
        // Set total supply: 1 billion tokens
        Mapping::set(total_supply, 0u8, 1000000000u64);

        // Set airdrop pool: 300 million tokens (30%)
        Mapping::set(airdrop_remaining, 0u8, 300000000u64);
    }

    // Set airdrop allocation for a user (admin only)
    async transition set_airdrop_allocation(
        public user: address,
        public amount: u64
    ) -> Future {
        return finalize_set_airdrop_allocation(user, amount);
    }

    async function finalize_set_airdrop_allocation(
        public user: address,
        public amount: u64
    ) {
        Mapping::set(airdrop_allocation, user, amount);
    }

    // ========================================
    // MINT FUNCTIONS
    // ========================================

    // Mint public tokens (admin only)
    async transition mint_public(
        public receiver: address,
        public amount: u64
    ) -> Future {
        return finalize_mint_public(receiver, amount);
    }

    async function finalize_mint_public(
        public receiver: address,
        public amount: u64
    ) {
        let receiver_amount: u64 = Mapping::get_or_use(account, receiver, 0u64);
        Mapping::set(account, receiver, receiver_amount + amount);
    }

    // Mint private tokens
    transition mint_private(
        receiver: address,
        amount: u64
    ) -> token {
        return token {
            owner: receiver,
            amount: amount,
        };
    }

    // ========================================
    // AIRDROP FUNCTIONS
    // ========================================

    // Claim airdrop (100 $LEAGUE for early users)
    async transition claim_airdrop() -> (token, Future) {
        // Each user gets 100 $LEAGUE
        let airdrop_amount: u64 = 100u64;

        let airdrop_token: token = token {
            owner: self.caller,
            amount: airdrop_amount,
        };

        return (airdrop_token, finalize_claim_airdrop(self.caller, airdrop_amount));
    }

    async function finalize_claim_airdrop(
        public user: address,
        public amount: u64
    ) {
        // Check if already claimed
        let already_claimed: bool = Mapping::get_or_use(airdrop_claimed, user, false);
        assert_eq(already_claimed, false);

        // Check if airdrop pool has enough
        let remaining: u64 = Mapping::get_or_use(airdrop_remaining, 0u8, 0u64);
        assert(remaining >= amount);

        // Mark as claimed
        Mapping::set(airdrop_claimed, user, true);

        // Decrease remaining airdrop
        Mapping::set(airdrop_remaining, 0u8, remaining - amount);
    }

    // ========================================
    // TRANSFER FUNCTIONS
    // ========================================

    // Transfer public tokens
    async transition transfer_public(
        public receiver: address,
        public amount: u64
    ) -> Future {
        return finalize_transfer_public(self.caller, receiver, amount);
    }

    async function finalize_transfer_public(
        public sender: address,
        public receiver: address,
        public amount: u64
    ) {
        let sender_amount: u64 = Mapping::get_or_use(account, sender, 0u64);
        Mapping::set(account, sender, sender_amount - amount);

        let receiver_amount: u64 = Mapping::get_or_use(account, receiver, 0u64);
        Mapping::set(account, receiver, receiver_amount + amount);
    }

    // Transfer private tokens
    transition transfer_private(
        sender: token,
        receiver: address,
        amount: u64
    ) -> (token, token) {
        let difference: u64 = sender.amount - amount;

        let remaining: token = token {
            owner: sender.owner,
            amount: difference,
        };

        let transferred: token = token {
            owner: receiver,
            amount: amount,
        };

        return (remaining, transferred);
    }

    // Convert private to public
    async transition transfer_priv_to_pub(
        sender: token,
        public receiver: address,
        public amount: u64
    ) -> (token, Future) {
        let difference: u64 = sender.amount - amount;

        let remaining: token = token {
            owner: sender.owner,
            amount: difference,
        };

        return (remaining, finalize_priv_to_pub(receiver, amount));
    }

    async function finalize_priv_to_pub(
        public receiver: address,
        public amount: u64
    ) {
        let receiver_amount: u64 = Mapping::get_or_use(account, receiver, 0u64);
        Mapping::set(account, receiver, receiver_amount + amount);
    }

    // Convert public to private
    async transition transfer_pub_to_priv(
        public receiver: address,
        public amount: u64
    ) -> (token, Future) {
        let transferred: token = token {
            owner: receiver,
            amount: amount,
        };

        return (transferred, finalize_pub_to_priv(self.caller, amount));
    }

    async function finalize_pub_to_priv(
        public sender: address,
        public amount: u64
    ) {
        let sender_amount: u64 = Mapping::get_or_use(account, sender, 0u64);
        Mapping::set(account, sender, sender_amount - amount);
    }

    // ========================================
    // QUERY FUNCTIONS
    // ========================================

    // Get balance (off-chain)
    function get_balance(account_balance: u64) -> u64 {
        return account_balance;
    }
}

// Premier League Team Badges - NFT system with betting bonuses
// 20 unique team badges, marketplace with 2.5% fees

program team_badges.aleo {

    // ========================================
    // DATA STRUCTURES
    // ========================================

    // Team Badge NFT
    record TeamBadge {
        owner: address,
        team_id: u8,           // 1-20 for 20 PL teams
        badge_id: field,       // Unique identifier
        mint_number: u32,      // Edition number (#1, #2, etc.)
        rarity: u8,            // 1: common, 2: rare, 3: legendary
    }

    // Marketplace listing
    record Listing {
        owner: address,        // Seller
        badge_id: field,
        team_id: u8,
        price: u64,            // In $LEAGUE tokens
        listing_id: field,
    }

    // ========================================
    // MAPPINGS
    // ========================================

    // Track total minted per team
    mapping team_mint_count: u8 => u32;

    // Badge ownership verification
    mapping badge_owners: field => address;

    // Active listings
    mapping active_listings: field => bool;

    // Marketplace stats
    mapping total_sales: u8 => u64;  // key 0 = total volume
    mapping marketplace_fees: u8 => u64;  // key 0 = accumulated fees

    // Badge bonuses (team_id => bonus percentage)
    mapping badge_bonuses: u8 => u8;

    // ========================================
    // ADMIN FUNCTIONS
    // ========================================

    // Set badge bonus for a team
    async transition set_badge_bonus(
        public team_id: u8,
        public bonus_percent: u8
    ) -> Future {
        return finalize_set_badge_bonus(team_id, bonus_percent);
    }

    async function finalize_set_badge_bonus(
        public team_id: u8,
        public bonus_percent: u8
    ) {
        // Default: 5% bonus for badge holders
        Mapping::set(badge_bonuses, team_id, bonus_percent);
    }

    // ========================================
    // MINTING FUNCTIONS
    // ========================================

    // Mint a new team badge
    async transition mint_badge(
        public team_id: u8,
        receiver: address,
        rarity: u8
    ) -> (TeamBadge, Future) {
        assert(team_id >= 1u8 && team_id <= 20u8);
        assert(rarity >= 1u8 && rarity <= 3u8);

        // Generate unique badge ID
        let badge_id: field = BHP256::hash_to_field(team_id as field + rarity as field);

        let badge: TeamBadge = TeamBadge {
            owner: receiver,
            team_id: team_id,
            badge_id: badge_id,
            mint_number: 0u32,  // Will be set in finalize
            rarity: rarity,
        };

        return (badge, finalize_mint_badge(team_id, badge_id, receiver));
    }

    async function finalize_mint_badge(
        public team_id: u8,
        public badge_id: field,
        public receiver: address
    ) {
        // Increment mint count for this team
        let current_count: u32 = Mapping::get_or_use(team_mint_count, team_id, 0u32);
        Mapping::set(team_mint_count, team_id, current_count + 1u32);

        // Record ownership
        Mapping::set(badge_owners, badge_id, receiver);
    }

    // ========================================
    // MARKETPLACE FUNCTIONS
    // ========================================

    // List badge for sale
    async transition list_badge(
        badge: TeamBadge,
        public price: u64
    ) -> (Listing, Future) {
        // Generate listing ID
        let listing_id: field = BHP256::hash_to_field(badge.badge_id + price as field);

        let listing: Listing = Listing {
            owner: badge.owner,
            badge_id: badge.badge_id,
            team_id: badge.team_id,
            price: price,
            listing_id: listing_id,
        };

        return (listing, finalize_list_badge(listing_id, badge.badge_id));
    }

    async function finalize_list_badge(
        public listing_id: field,
        public badge_id: field
    ) {
        // Mark listing as active
        Mapping::set(active_listings, listing_id, true);
    }

    // Buy badge from marketplace
    async transition buy_badge(
        listing: Listing,
        public buyer: address
    ) -> (TeamBadge, Future) {
        // Calculate marketplace fee (2.5% = 250/10000)
        let fee: u64 = (listing.price * 250u64) / 10000u64;
        let seller_amount: u64 = listing.price - fee;

        // Create badge for buyer (rarity defaulted to 1 for simplicity)
        let badge: TeamBadge = TeamBadge {
            owner: buyer,
            team_id: listing.team_id,
            badge_id: listing.badge_id,
            mint_number: 0u32,
            rarity: 1u8,
        };

        return (badge, finalize_buy_badge(listing.listing_id, listing.badge_id, buyer, listing.price, fee));
    }

    async function finalize_buy_badge(
        public listing_id: field,
        public badge_id: field,
        public buyer: address,
        public price: u64,
        public fee: u64
    ) {
        // Remove from active listings
        Mapping::set(active_listings, listing_id, false);

        // Update ownership
        Mapping::set(badge_owners, badge_id, buyer);

        // Track sales volume
        let total_vol: u64 = Mapping::get_or_use(total_sales, 0u8, 0u64);
        Mapping::set(total_sales, 0u8, total_vol + price);

        // Accumulate marketplace fees
        let total_fees: u64 = Mapping::get_or_use(marketplace_fees, 0u8, 0u64);
        Mapping::set(marketplace_fees, 0u8, total_fees + fee);
    }

    // Cancel listing
    async transition cancel_listing(
        listing: Listing
    ) -> (TeamBadge, Future) {
        // Return badge to owner
        let badge: TeamBadge = TeamBadge {
            owner: listing.owner,
            team_id: listing.team_id,
            badge_id: listing.badge_id,
            mint_number: 0u32,
            rarity: 1u8,
        };

        return (badge, finalize_cancel_listing(listing.listing_id));
    }

    async function finalize_cancel_listing(
        public listing_id: field
    ) {
        Mapping::set(active_listings, listing_id, false);
    }

    // ========================================
    // TRANSFER FUNCTION
    // ========================================

    // Transfer badge to another user
    async transition transfer_badge(
        badge: TeamBadge,
        receiver: address
    ) -> (TeamBadge, Future) {
        let transferred_badge: TeamBadge = TeamBadge {
            owner: receiver,
            team_id: badge.team_id,
            badge_id: badge.badge_id,
            mint_number: badge.mint_number,
            rarity: badge.rarity,
        };

        return (transferred_badge, finalize_transfer_badge(badge.badge_id, receiver));
    }

    async function finalize_transfer_badge(
        public badge_id: field,
        public new_owner: address
    ) {
        Mapping::set(badge_owners, badge_id, new_owner);
    }

    // ========================================
    // QUERY/HELPER FUNCTIONS
    // ========================================

    // Get badge bonus percentage (off-chain)
    function get_badge_bonus(team_id: u8) -> u8 {
        // Default 5% bonus
        return team_id > 0u8 ? 5u8 : 0u8;
    }

    // Check if badge provides bonus (off-chain)
    function has_badge_bonus(has_badge: bool) -> bool {
        return has_badge;
    }

    // Calculate marketplace fee (off-chain)
    function calculate_marketplace_fee(price: u64) -> u64 {
        // 2.5% fee
        return (price * 250u64) / 10000u64;
    }
}

#[test_only]
#[allow(unused_let_mut)]
module fee_rebate::test_fee_rebate;

use fee_rebate::fee_rebate::{Self, Config, Vault, PartnerBalance, AdminCap};
use sui::coin::{Self, Coin};
use sui::sui::SUI;
use sui::test_scenario as ts;

const ADMIN: address = @0x1;
const PARTNER: address = @0x2;
const USER: address = @0x3;

#[test]
fun test_set_partner() {
    let mut scenario = ts::begin(ADMIN);
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        fee_rebate::test_init(ctx);
    };

    ts::next_tx(&mut scenario, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut config = ts::take_shared<Config>(&scenario);

        // Test setting partner
        fee_rebate::set_partner(&admin_cap, &mut config, PARTNER);

        let (partner, fee_ratio, fee_amount) = fee_rebate::get_config_info(&config);
        assert!(partner == PARTNER, 0);
        assert!(fee_ratio == 0, 1);
        assert!(fee_amount == 0, 2);

        // Clean up
        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };
    ts::end(scenario);
}

#[test]
fun test_set_fee_ratio() {
    let mut scenario = ts::begin(ADMIN);
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        fee_rebate::test_init(ctx);
    };

    ts::next_tx(&mut scenario, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut config = ts::take_shared<Config>(&scenario);

        // Test setting fee ratio
        fee_rebate::set_fee_ratio(&admin_cap, &mut config, 50);

        let (partner, fee_ratio, fee_amount) = fee_rebate::get_config_info(&config);
        assert!(partner == @0x0, 0);
        assert!(fee_ratio == 50, 1);
        assert!(fee_amount == 0, 2);

        // Clean up
        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };
    ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = fee_rebate::EInvalidRatio)]
fun test_set_fee_ratio_invalid() {
    let mut scenario = ts::begin(ADMIN);
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        fee_rebate::test_init(ctx);
    };

    ts::next_tx(&mut scenario, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut config = ts::take_shared<Config>(&scenario);

        // This should fail
        fee_rebate::set_fee_ratio(&admin_cap, &mut config, 101);

        // Clean up
        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };
    ts::end(scenario);
}

#[test]
fun test_initialize_config() {
    let mut scenario = ts::begin(ADMIN);
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        fee_rebate::test_init(ctx);
    };

    ts::next_tx(&mut scenario, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut config = ts::take_shared<Config>(&scenario);

        // Test initializing all config at once
        fee_rebate::initialize_config(&admin_cap, &mut config, PARTNER, 30, 200);

        let (partner, fee_ratio, fee_amount) = fee_rebate::get_config_info(&config);
        assert!(partner == PARTNER, 0);
        assert!(fee_ratio == 30, 1);
        assert!(fee_amount == 200, 2);

        // Clean up
        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };
    ts::end(scenario);
}

#[test]
fun test_receive_fee_by_ratio() {
    let mut scenario = ts::begin(ADMIN);

    // Setup config
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        fee_rebate::test_init(ctx);
    };

    ts::next_tx(&mut scenario, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut config = ts::take_shared<Config>(&scenario);

        fee_rebate::initialize_config(&admin_cap, &mut config, PARTNER, 50, 100);

        // Clean up
        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };

    // Test receive fee by ratio
    ts::next_tx(&mut scenario, USER);
    {
        let config = ts::take_shared<Config>(&scenario);
        let mut vault = ts::take_shared<Vault>(&scenario);
        let mut pb = ts::take_shared<PartnerBalance>(&scenario);
        let ctx = ts::ctx(&mut scenario);

        let fee_coin = coin::mint_for_testing<SUI>(100, ctx);
        fee_rebate::receive_fee(fee_coin, &config, &mut vault, &mut pb, true, ctx);

        // Partner should get 50% = 50, vault should get 50
        assert!(fee_rebate::get_partner_balance(&pb) == 50, 0);
        assert!(fee_rebate::get_vault_balance(&vault) == 50, 1);

        // Clean up
        ts::return_shared(config);
        ts::return_shared(vault);
        ts::return_shared(pb);
    };

    ts::end(scenario);
}

#[test]
fun test_receive_fee_by_amount_case1() {
    let mut scenario = ts::begin(ADMIN);

    // Setup config
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        fee_rebate::test_init(ctx);
    };

    ts::next_tx(&mut scenario, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut config = ts::take_shared<Config>(&scenario);

        fee_rebate::initialize_config(&admin_cap, &mut config, PARTNER, 50, 100);

        // Clean up
        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };

    // Test Case 1: receive fee 50, option = amount, partner receives 50, vault receives 0
    ts::next_tx(&mut scenario, USER);
    {
        let mut config = ts::take_shared<Config>(&scenario);
        let mut vault = ts::take_shared<Vault>(&scenario);
        let mut pb = ts::take_shared<PartnerBalance>(&scenario);
        let ctx = ts::ctx(&mut scenario);

        let fee_coin = coin::mint_for_testing<SUI>(50, ctx);
        fee_rebate::receive_fee(fee_coin, &config, &mut vault, &mut pb, false, ctx);

        // Partner should get min(50, 100) = 50, vault should get 0
        assert!(fee_rebate::get_partner_balance(&pb) == 50, 0);
        assert!(fee_rebate::get_vault_balance(&vault) == 0, 1);

        // Clean up
        ts::return_shared(config);
        ts::return_shared(vault);
        ts::return_shared(pb);
    };

    ts::end(scenario);
}

#[test]
fun test_receive_fee_by_amount_case2() {
    let mut scenario = ts::begin(ADMIN);

    // Setup config
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        fee_rebate::test_init(ctx);
    };

    ts::next_tx(&mut scenario, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut config = ts::take_shared<Config>(&scenario);

        fee_rebate::initialize_config(&admin_cap, &mut config, PARTNER, 50, 100);

        // Clean up
        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };

    // Test Case 2: receive fee 150, option = amount, partner receives 100, vault receives 50
    ts::next_tx(&mut scenario, USER);
    {
        let mut config = ts::take_shared<Config>(&scenario);
        let mut vault = ts::take_shared<Vault>(&scenario);
        let mut pb = ts::take_shared<PartnerBalance>(&scenario);
        let ctx = ts::ctx(&mut scenario);

        let fee_coin = coin::mint_for_testing<SUI>(150, ctx);
        fee_rebate::receive_fee(fee_coin, &config, &mut vault, &mut pb, false, ctx);

        // Partner should get min(150, 100) = 100, vault should get 50
        assert!(fee_rebate::get_partner_balance(&pb) == 100, 0);
        assert!(fee_rebate::get_vault_balance(&vault) == 50, 1);

        // Clean up
        ts::return_shared(config);
        ts::return_shared(vault);
        ts::return_shared(pb);
    };

    ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = fee_rebate::ENoPartnerSet)]
fun test_receive_fee_no_partner() {
    let mut scenario = ts::begin(ADMIN);
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        fee_rebate::test_init(ctx);
    };

    // Don't set partner, try to receive fee
    ts::next_tx(&mut scenario, USER);
    {
        let mut config = ts::take_shared<Config>(&scenario);
        let mut vault = ts::take_shared<Vault>(&scenario);
        let mut pb = ts::take_shared<PartnerBalance>(&scenario);
        let ctx = ts::ctx(&mut scenario);

        let fee_coin = coin::mint_for_testing<SUI>(100, ctx);
        fee_rebate::receive_fee(fee_coin, &config, &mut vault, &mut pb, true, ctx); // Should fail

        // Clean up
        ts::return_shared(config);
        ts::return_shared(vault);
        ts::return_shared(pb);
    };

    ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = fee_rebate::EInsufficientBalance)]
fun test_receive_fee_zero_amount() {
    let mut scenario = ts::begin(ADMIN);

    // Setup config
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        fee_rebate::test_init(ctx);
    };

    ts::next_tx(&mut scenario, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut config = ts::take_shared<Config>(&scenario);

        fee_rebate::initialize_config(&admin_cap, &mut config, PARTNER, 50, 100);

        // Clean up
        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };

    // Try to receive zero fee
    ts::next_tx(&mut scenario, USER);
    {
        let mut config = ts::take_shared<Config>(&scenario);
        let mut vault = ts::take_shared<Vault>(&scenario);
        let mut pb = ts::take_shared<PartnerBalance>(&scenario);
        let ctx = ts::ctx(&mut scenario);

        let fee_coin = coin::mint_for_testing<SUI>(0, ctx);
        fee_rebate::receive_fee(fee_coin, &config, &mut vault, &mut pb, true, ctx); // Should fail

        // Clean up
        ts::return_shared(config);
        ts::return_shared(vault);
        ts::return_shared(pb);
    };

    ts::end(scenario);
}

#[test]
fun test_claim_partner_fee() {
    let mut scenario = ts::begin(ADMIN);

    // Setup and add some balance to partner
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        fee_rebate::test_init(ctx);
    };

    ts::next_tx(&mut scenario, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut config = ts::take_shared<Config>(&scenario);

        fee_rebate::initialize_config(&admin_cap, &mut config, PARTNER, 50, 100);

        // Clean up
        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };

    // Add fee
    ts::next_tx(&mut scenario, USER);
    {
        let mut config = ts::take_shared<Config>(&scenario);
        let mut vault = ts::take_shared<Vault>(&scenario);
        let mut pb = ts::take_shared<PartnerBalance>(&scenario);
        let ctx = ts::ctx(&mut scenario);

        let fee_coin = coin::mint_for_testing<SUI>(100, ctx);
        fee_rebate::receive_fee(fee_coin, &config, &mut vault, &mut pb, true, ctx);

        // Clean up
        ts::return_shared(config);
        ts::return_shared(vault);
        ts::return_shared(pb);
    };

    // Partner claims fee
    ts::next_tx(&mut scenario, PARTNER);
    {
        let mut config = ts::take_shared<Config>(&scenario);
        let mut pb = ts::take_shared<PartnerBalance>(&scenario);
        let ctx = ts::ctx(&mut scenario);

        assert!(fee_rebate::get_partner_balance(&pb) == 50, 0);

        fee_rebate::claim_partner_fee(&config, &mut pb, ctx);

        assert!(fee_rebate::get_partner_balance(&pb) == 0, 1);

        ts::return_shared(config);
        ts::return_shared(pb);
    };

    // Check that partner received the coin with correct amount
    ts::next_tx(&mut scenario, PARTNER);
    {
        let partner_coin = ts::take_from_sender<Coin<SUI>>(&scenario);
        assert!(coin::value(&partner_coin) == 50, 0); // Should receive exactly 50 SUI
        ts::return_to_sender(&scenario, partner_coin);
    };

    ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = fee_rebate::ENoPartnerSet)]
fun test_claim_partner_fee_wrong_caller() {
    let mut scenario = ts::begin(ADMIN);

    // Setup
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        fee_rebate::test_init(ctx);
    };

    ts::next_tx(&mut scenario, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut config = ts::take_shared<Config>(&scenario);

        fee_rebate::initialize_config(&admin_cap, &mut config, PARTNER, 50, 100);

        // Clean up
        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };

    // Add fee
    ts::next_tx(&mut scenario, USER);
    {
        let mut config = ts::take_shared<Config>(&scenario);
        let mut vault = ts::take_shared<Vault>(&scenario);
        let mut pb = ts::take_shared<PartnerBalance>(&scenario);
        let ctx = ts::ctx(&mut scenario);

        let fee_coin = coin::mint_for_testing<SUI>(100, ctx);
        fee_rebate::receive_fee(fee_coin, &config, &mut vault, &mut pb, true, ctx);

        // Clean up
        ts::return_shared(config);
        ts::return_shared(vault);
        ts::return_shared(pb);
    };

    // Non-partner tries to claim
    ts::next_tx(&mut scenario, USER);
    {
        let mut config = ts::take_shared<Config>(&scenario);
        let mut pb = ts::take_shared<PartnerBalance>(&scenario);
        let ctx = ts::ctx(&mut scenario);

        fee_rebate::claim_partner_fee(&config, &mut pb, ctx); // Should fail

        ts::return_shared(config);
        ts::return_shared(pb);
    };

    ts::end(scenario);
}

#[test]
fun test_claim_vault_fee() {
    let mut scenario = ts::begin(ADMIN);

    // Setup and add some balance to vault
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        fee_rebate::test_init(ctx);
    };

    ts::next_tx(&mut scenario, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut config = ts::take_shared<Config>(&scenario);

        fee_rebate::initialize_config(&admin_cap, &mut config, PARTNER, 50, 100);

        // Clean up
        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };

    // Add fee
    ts::next_tx(&mut scenario, USER);
    {
        let mut config = ts::take_shared<Config>(&scenario);
        let mut vault = ts::take_shared<Vault>(&scenario);
        let mut pb = ts::take_shared<PartnerBalance>(&scenario);
        let ctx = ts::ctx(&mut scenario);

        let fee_coin = coin::mint_for_testing<SUI>(100, ctx);
        fee_rebate::receive_fee(fee_coin, &config, &mut vault, &mut pb, true, ctx);

        // Clean up
        ts::return_shared(config);
        ts::return_shared(vault);
        ts::return_shared(pb);
    };

    // Admin claims vault fee
    ts::next_tx(&mut scenario, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut vault = ts::take_shared<Vault>(&scenario);
        let ctx = ts::ctx(&mut scenario);

        assert!(fee_rebate::get_vault_balance(&vault) == 50, 0);

        fee_rebate::claim_vault_fee(&admin_cap, &mut vault, ctx);

        assert!(fee_rebate::get_vault_balance(&vault) == 0, 1);

        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(vault);
    };

    // Check that admin received the coin with correct amount
    ts::next_tx(&mut scenario, ADMIN);
    {
        let admin_coin = ts::take_from_sender<Coin<SUI>>(&scenario);
        assert!(coin::value(&admin_coin) == 50, 0); // Should receive exactly 50 SUI
        ts::return_to_sender(&scenario, admin_coin);
    };

    ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = fee_rebate::EInsufficientBalance)]
fun test_claim_partner_fee_no_balance() {
    let mut scenario = ts::begin(ADMIN);

    // Setup
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        fee_rebate::test_init(ctx);
    };

    ts::next_tx(&mut scenario, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut config = ts::take_shared<Config>(&scenario);

        fee_rebate::initialize_config(&admin_cap, &mut config, PARTNER, 50, 100);

        // Clean up
        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };

    // Partner tries to claim without any balance
    ts::next_tx(&mut scenario, PARTNER);
    {
        let mut config = ts::take_shared<Config>(&scenario);
        let mut pb = ts::take_shared<PartnerBalance>(&scenario);
        let ctx = ts::ctx(&mut scenario);

        fee_rebate::claim_partner_fee(&config, &mut pb, ctx); // Should fail

        ts::return_shared(config);
        ts::return_shared(pb);
    };

    ts::end(scenario);
}

#[test]
#[expected_failure(abort_code = fee_rebate::EInsufficientBalance)]
fun test_claim_vault_fee_no_balance() {
    let mut scenario = ts::begin(ADMIN);

    // Admin tries to claim without any balance
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        fee_rebate::test_init(ctx);
    };

    ts::next_tx(&mut scenario, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut vault = ts::take_shared<Vault>(&scenario);
        let ctx = ts::ctx(&mut scenario);

        fee_rebate::claim_vault_fee(&admin_cap, &mut vault, ctx); // Should fail

        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(vault);
    };

    ts::end(scenario);
}

#[test]
fun test_multiple_fee_accumulation() {
    let mut scenario = ts::begin(ADMIN);

    // Setup
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        fee_rebate::test_init(ctx);
    };

    ts::next_tx(&mut scenario, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let mut config = ts::take_shared<Config>(&scenario);

        fee_rebate::initialize_config(&admin_cap, &mut config, PARTNER, 30, 100);

        // Clean up
        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };

    // Add multiple fees
    ts::next_tx(&mut scenario, USER);
    {
        let mut config = ts::take_shared<Config>(&scenario);
        let mut vault = ts::take_shared<Vault>(&scenario);
        let mut pb = ts::take_shared<PartnerBalance>(&scenario);
        let ctx = ts::ctx(&mut scenario);

        // First fee: 100 with 30% ratio -> partner gets 30, vault gets 70
        let fee_coin1 = coin::mint_for_testing<SUI>(100, ctx);
        fee_rebate::receive_fee(fee_coin1, &config, &mut vault, &mut pb, true, ctx);

        // Second fee: 200 with 30% ratio -> partner gets 60, vault gets 140
        let fee_coin2 = coin::mint_for_testing<SUI>(200, ctx);
        fee_rebate::receive_fee(fee_coin2, &config, &mut vault, &mut pb, true, ctx);

        // Total: partner should have 90, vault should have 210
        assert!(fee_rebate::get_partner_balance(&pb) == 90, 0);
        assert!(fee_rebate::get_vault_balance(&vault) == 210, 1);

        // Clean up
        ts::return_shared(config);
        ts::return_shared(vault);
        ts::return_shared(pb);
    };

    ts::end(scenario);
}

// ============================================================================
// TESTS USING DIRECT INIT() CALL
// ============================================================================

#[test]
fun test_direct_init_call() {
    let mut scenario = ts::begin(ADMIN);
    ts::next_tx(&mut scenario, ADMIN);
    {
        let ctx = ts::ctx(&mut scenario);
        // Directly call the test_init function which calls init()
        fee_rebate::test_init(ctx);
    };

    ts::next_tx(&mut scenario, ADMIN);
    {
        let admin_cap = ts::take_from_sender<AdminCap>(&scenario);
        let config = ts::take_shared<Config>(&scenario);

        // Verify default configuration
        let (partner, fee_ratio, fee_amount) = fee_rebate::get_config_info(&config);
        assert!(partner == @0x0, 0);
        assert!(fee_ratio == 0, 1);
        assert!(fee_amount == 0, 2);

        // Clean up
        ts::return_to_sender(&scenario, admin_cap);
        ts::return_shared(config);
    };
    ts::end(scenario);
}

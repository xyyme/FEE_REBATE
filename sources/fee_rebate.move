module fee_rebate::fee_rebate;

use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin};
use sui::event;
use sui::sui::SUI;

const EInvalidRatio: u64 = 0;
const ENoPartnerSet: u64 = 1;
const EInsufficientBalance: u64 = 2;

public struct Config has key, store {
    id: UID,
    partner: address,
    fee_ratio: u64, // 0 ~ 100
    fee_amount: u64, // Fixed amount
}

public struct Vault has key, store {
    id: UID,
    balance: Balance<SUI>,
}

public struct PartnerBalance has key, store {
    id: UID,
    balance: Balance<SUI>,
}

public struct AdminCap has key {
    id: UID,
}

// Events

public struct FeeReceived has copy, drop {
    amount: u64,
    is_by_ratio: bool,
}

public struct PartnerClaimed has copy, drop {
    amount: u64,
    partner: address,
}

public struct VaultClaimed has copy, drop {
    amount: u64,
    admin: address,
}

public struct PartnerSet has copy, drop {
    partner: address,
}

public struct ConfigUpdated has copy, drop {
    fee_ratio: u64,
    fee_amount: u64,
}

fun init(ctx: &mut TxContext) {
    let admin_addr = tx_context::sender(ctx);

    let admin_cap = AdminCap { id: object::new(ctx) };
    transfer::transfer(admin_cap, admin_addr);

    // Create config object
    let config = Config {
        id: object::new(ctx),
        partner: @0x0,
        fee_ratio: 0,
        fee_amount: 0,
    };
    transfer::share_object(config);

    // Create Vault object
    let vault = Vault { id: object::new(ctx), balance: balance::zero<SUI>() };
    transfer::share_object(vault);

    // Create PartnerBalance object
    let pb = PartnerBalance { id: object::new(ctx), balance: balance::zero<SUI>() };
    transfer::share_object(pb);
}

/// Set partner
public fun set_partner(_: &AdminCap, config: &mut Config, partner: address) {
    config.partner = partner;
    event::emit(PartnerSet { partner });
}

/// Set fee ratio
public fun set_fee_ratio(_: &AdminCap, config: &mut Config, ratio: u64) {
    assert!(ratio <= 100, EInvalidRatio);
    config.fee_ratio = ratio;
    event::emit(ConfigUpdated {
        fee_ratio: ratio,
        fee_amount: config.fee_amount,
    });
}

/// Set fee amount
public fun set_fee_amount(_: &AdminCap, config: &mut Config, amount: u64) {
    config.fee_amount = amount;
    event::emit(ConfigUpdated {
        fee_ratio: config.fee_ratio,
        fee_amount: amount,
    });
}

/// Initialize all config at once
public fun initialize_config(
    _: &AdminCap,
    config: &mut Config,
    partner: address,
    fee_ratio: u64,
    fee_amount: u64,
) {
    assert!(fee_ratio <= 100, EInvalidRatio);

    config.partner = partner;
    config.fee_ratio = fee_ratio;
    config.fee_amount = fee_amount;

    event::emit(PartnerSet { partner });
    event::emit(ConfigUpdated {
        fee_ratio,
        fee_amount,
    });
}

public fun receive_fee(
    mut fee_coin: Coin<SUI>,
    config: &Config,
    vault: &mut Vault,
    pb: &mut PartnerBalance,
    is_by_ratio: bool,
    ctx: &mut TxContext,
) {
    assert!(config.partner != @0x0, ENoPartnerSet);
    let fee_amount = coin::value(&fee_coin);
    assert!(fee_amount > 0, EInsufficientBalance);

    let partner_share: u64;

    if (is_by_ratio) {
        partner_share = (fee_amount * config.fee_ratio) / 100;
    } else {
        partner_share = if (fee_amount < config.fee_amount) fee_amount else config.fee_amount;
    };

    // Add to partner's balance
    if (partner_share > 0) {
        let partner_coin = coin::split(&mut fee_coin, partner_share, ctx);
        balance::join(&mut pb.balance, coin::into_balance(partner_coin));
    };

    // Remaining to vault
    balance::join(&mut vault.balance, coin::into_balance(fee_coin));

    event::emit(FeeReceived {
        amount: fee_amount,
        is_by_ratio,
    });
}

/// Partner claim fee
#[allow(lint(self_transfer))]
public fun claim_partner_fee(config: &Config, pb: &mut PartnerBalance, ctx: &mut TxContext) {
    let partner = tx_context::sender(ctx);

    // Verify that the caller is the registered partner
    assert!(config.partner == partner, ENoPartnerSet);

    let total_value = balance::value(&pb.balance);
    assert!(total_value > 0, EInsufficientBalance);

    // Create coin from balance and transfer to partner
    let claim_coin = coin::from_balance(balance::split(&mut pb.balance, total_value), ctx);
    transfer::public_transfer(claim_coin, partner);

    event::emit(PartnerClaimed { amount: total_value, partner });
}

/// Admin claim vault fee
#[allow(lint(self_transfer))]
public fun claim_vault_fee(_: &AdminCap, vault: &mut Vault, ctx: &mut TxContext) {
    let total_value = balance::value(&vault.balance);
    assert!(total_value > 0, EInsufficientBalance);

    // Create coin from balance and transfer to admin
    let claim_coin = coin::from_balance(balance::split(&mut vault.balance, total_value), ctx);
    transfer::public_transfer(claim_coin, tx_context::sender(ctx));

    event::emit(VaultClaimed { amount: total_value, admin: tx_context::sender(ctx) });
}

/// Get partner balance
public fun get_partner_balance(pb: &PartnerBalance): u64 {
    balance::value(&pb.balance)
}

/// Get vault balance
public fun get_vault_balance(vault: &Vault): u64 {
    balance::value(&vault.balance)
}

/// Get config info
public fun get_config_info(config: &Config): (address, u64, u64) {
    (config.partner, config.fee_ratio, config.fee_amount)
}

// ============================================================================
// TEST HELPERS
// ============================================================================
// These functions are only available during testing and help create test objects
/// Test initialization - directly calls the real init() function
#[test_only]
public fun test_init(ctx: &mut TxContext) {
    init(ctx);
}

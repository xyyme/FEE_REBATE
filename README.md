# Fee Rebate Smart Contract

A Sui Move smart contract for fee rebating with partners. This contract allows receiving tokens and distributing them to a single partner, who can then claim their fee. The fee distribution can be a ratio or a fixed amount, with the remaining fee sent to a revenue vault.

## 📋 Contract Information

### Contract Address
- **Package ID**: `0x7f723e12f1d5c0508245daada28afc90947e4a84d738aecf07d90b1f5106cc8d`
- **Explorer**: [View on Sui Scan](https://suiscan.xyz/testnet/object/0x7f723e12f1d5c0508245daada28afc90947e4a84d738aecf07d90b1f5106cc8d/tx-blocks)

### Object IDs
| Object | ID | Type | Description |
|--------|----|----|-------------|
| **Package** | `0x7f723e12f1d5c0508245daada28afc90947e4a84d738aecf07d90b1f5106cc8d` | Immutable | Contract package |
| **AdminCap** | `0xc8d55f5b060095e7246ec7db919a2c6fa8a5b103d8815dd296c5830164ba1260` | Owned | Admin capability |
| **Config** | `0x8f838fbe977c3eeecd0f5dfd8743edf2f6c0d7655a249183a292fb538896c585` | Shared | Configuration object |
| **Vault** | `0xd758331d2f2ad92e15708d9eaaf10d52f843779a13d116fedeba6f000f95f67f` | Shared | Revenue vault |
| **PartnerBalance** | `0x82de8f1363b78b623f6ac55e99c3af482f131135005a3fc08421bf776d4618f4` | Shared | Partner balance tracker |
| **Partner Address** | `0x7342d6dcf26db9093a59e56071214d62a9a1440578f9a63f082b5ebc45d5bd66` | Address | Partner wallet address |

## 🔗 Transaction History

### Setup Transactions
- **Set Partner**: [View Transaction](https://suiscan.xyz/testnet/tx/C8vo4gwvAs13i9UEnQ18Z8kiSSTsSWubQoWKPYmgt5Gt)
- **Set Fee Ratio**: [View Transaction](https://suiscan.xyz/testnet/tx/24FJP3BzxMPdNHnPgWHzz6aia847pWKW6SiEWuAGDX8o)
- **Set Fee Amount**: [View Transaction](https://suiscan.xyz/testnet/tx/5Mmi4AFFcbZ988WZuKoXEbHMoizU4Q8WF26AP2rveMaS)

### Test Case 1: Ratio-based Distribution (50%)
- **Receive Fee**: 0.5 SUI → Partner: 0.25 SUI, Vault: 0.25 SUI [View Transaction](https://suiscan.xyz/testnet/tx/CuZe9reWxmCqreUnKHkkAyYpHVbdgvLfZ8tJzE58eagp)
- **Partner Claim**: Partner received 0.25 SUI [View Transaction](https://suiscan.xyz/testnet/tx/3W1taccKSgZgARKRrLbSWTp3CyADaCzXqxNzBipAtpHp)
- **Vault Claim**: Admin received 0.25 SUI [View Transaction](https://suiscan.xyz/testnet/tx/9LP51k9ugSRHqxgQ6x3B6jv9PS5GXe5c5DxK1sy8frGM)

### Test Case 2: Fixed Amount Distribution
- **Receive Fee**: 0.6 SUI → Partner: 0.5 SUI, Vault: 0.1 SUI [View Transaction](https://suiscan.xyz/testnet/tx/8Wp4P6QPFzRzJpybyTajPPGMTDcfh3ytxJnpJTjQfiFi)
- **Partner Claim**: Partner received 0.5 SUI [View Transaction](https://suiscan.xyz/testnet/tx/ELb3htpCXHauW8PHA8doMN77bRBA3HR7CX6HpoJJbRKB)
- **Vault Claim**: Admin received 0.1 SUI [View Transaction](https://suiscan.xyz/testnet/tx/4Qv2FVrY5JDYvA1uNCDhH6B3VVsHHFhz8PsNmx1iRDyV)


## 🚀 Features

### Fee Distribution Modes
1. **Ratio-based**: Distribute fees by percentage (e.g., 50% to partner, 50% to vault)
2. **Fixed Amount**: Distribute a fixed amount to partner, remainder to vault

### Core Functions
- **Admin Functions**:
  - `set_partner`: Set partner address
  - `set_fee_ratio`: Set fee distribution ratio (0-100%)
  - `set_fee_amount`: Set fixed fee amount
  - `claim_vault_fee`: Claim vault revenue

- **Partner Functions**:
  - `claim_partner_fee`: Partner claims their fees

- **Public Functions**:
  - `receive_fee`: Receive and distribute fees

- **View Functions**:
  - `get_partner_balance`: Get partner's pending balance
  - `get_vault_balance`: Get vault's pending balance
  - `get_config_info`: Get configuration details

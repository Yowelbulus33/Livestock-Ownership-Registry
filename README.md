# 🐄 Livestock Ownership Registry
A transparent blockchain-based system for registering and managing livestock ownership to prevent theft disputes and ensure clear ownership records.

## 📋 Overview

The Livestock Ownership Registry is a Stacks smart contract that provides a decentralized solution for tracking livestock ownership, transfers, and verification. This system helps farmers, ranchers, and livestock owners maintain transparent ownership records and prevent disputes.

## ✨ Key Features

- 🔒 **Secure Registration**: Register livestock with comprehensive details
- 🔄 **Ownership Transfers**: Initiate and accept ownership transfers safely
- ✅ **Verification System**: Authorized verifiers can validate livestock records
- 📊 **History Tracking**: Complete ownership history for each animal
- ⏸️ **Emergency Controls**: Contract pause/unpause functionality
- 🔍 **Ownership Verification**: Instant ownership validation

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Stacks CLI](https://docs.stacks.co/docs/command-line-interface) installed

### Installation

```bash
git clone <repository-url>
cd livestock-ownership-registry
clarinet check
```

### Testing

```bash
npm install
npm test
```

## 📖 Contract Functions

### 🐮 Public Functions

#### Registration
- `register-livestock()` - Register a new livestock with details
- `update-livestock-info()` - Update livestock information
- `deactivate-livestock()` - Deactivate livestock record

#### Ownership Transfer
- `initiate-transfer()` - Start ownership transfer process
- `accept-transfer()` - Accept pending transfer
- `cancel-transfer()` - Cancel pending transfer

#### Verification
- `verify-livestock()` - Verify livestock by authorized verifier
- `add-verifier()` - Add authorized verifier (owner only)
- `remove-verifier()` - Remove authorized verifier (owner only)

#### Administrative
- `pause-contract()` - Pause contract operations (owner only)
- `unpause-contract()` - Resume contract operations (owner only)

### 📚 Read-Only Functions

- `get-livestock-info()` - Get livestock details
- `get-pending-transfer()` - Get pending transfer info
- `get-owner-livestock()` - Get all livestock owned by address
- `get-livestock-history()` - Get ownership history
- `verify-ownership()` - Verify current owner
- `is-authorized-verifier()` - Check verifier status
- `is-contract-paused()` - Check contract status

## 🔧 Usage Examples

### Register New Livestock

```clarity
(contract-call? .livestock-ownership-registry register-livestock
  "Cattle"           ;; species
  "Angus"            ;; breed
  u24                ;; age (months)
  "Male"             ;; gender
  "Black"            ;; color
  u450               ;; weight (kg)
  "Healthy"          ;; health-status
  "Farm A, Sector 1" ;; location
)
```

### Transfer Ownership

```clarity
;; 1. Initiate transfer
(contract-call? .livestock-ownership-registry initiate-transfer
  u1                    ;; livestock-id
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 ;; new-owner
  "Sale transaction"    ;; reason
)

;; 2. Accept transfer (by new owner)
(contract-call? .livestock-ownership-registry accept-transfer u1)
```

### Verify Ownership

```clarity
(contract-call? .livestock-ownership-registry verify-ownership
  u1                    ;; livestock-id
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 ;; claimed-owner
)
```

## 🛡️ Security Features

- **Access Control**: Only owners can transfer their livestock
- **Verification System**: Authorized verifiers for livestock validation
- **Transfer Safety**: Two-step transfer process with approval
- **Emergency Controls**: Contract pause functionality
- **History Tracking**: Immutable ownership history

## 📊 Data Structure

Each livestock record contains:
- Owner address
- Species and breed information
- Physical characteristics (age, gender, color, weight)
- Health status and location
- Registration and last update timestamps
- Verification status
- Activity status

## 🔐 Error Codes

- `u100`: Unauthorized access
- `u101`: Livestock not found
- `u102`: Already registered
- `u103`: Invalid transfer
- `u104`: Invalid species
- `u105`: Invalid breed
- `u106`: Invalid owner
- `u107`: Transfer to self
- `u108`: Pending transfer exists
- `u109`: No pending transfer
- `u110`: Invalid verifier

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

# DAOGovern

A comprehensive decentralized autonomous organization (DAO) governance smart contract built on the Stacks blockchain using Clarity.

## Overview

DAOGovern is a voting system smart contract that enables decentralized governance through proposal creation, voting mechanisms, and execution. It provides a robust framework for community-driven decision making with built-in security measures and transparent voting processes.

## Features

- **Proposal Management**: Create, vote on, and execute governance proposals
- **Weighted Voting**: Voting power based on STX balance with configurable minimum thresholds
- **Time-bound Voting**: Proposals have defined voting periods (default: ~1 week)
- **Transparent Results**: All voting results are publicly accessible
- **Proposal Cancellation**: Proposers and contract owners can cancel active proposals
- **Event Logging**: Complete audit trail of all governance activities
- **Access Controls**: Owner-only functions for critical operations

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity 2.5
- **Contract Version**: 1.0.0
- **Minimum Voting Power**: 1 STX (1,000,000 microSTX)
- **Default Proposal Duration**: 1,008 blocks (~1 week)

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity runtime packaged as a command line tool
- [Node.js](https://nodejs.org/) (v16 or higher)
- [Git](https://git-scm.com/)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd DAOGovern
```

2. Navigate to the contract directory:
```bash
cd DAOGovern_contract
```

3. Install dependencies:
```bash
npm install
```

4. Run tests:
```bash
npm test
```

## Usage Examples

### Creating a Proposal

```clarity
;; Create a new governance proposal
(contract-call? .DAOGovern create-proposal 
  "Increase community fund allocation" 
  "Proposal to increase the community development fund from 10% to 15% of treasury")
```

### Voting on a Proposal

```clarity
;; Vote "yes" on proposal ID 1
(contract-call? .DAOGovern vote-on-proposal u1 true)

;; Vote "no" on proposal ID 1
(contract-call? .DAOGovern vote-on-proposal u1 false)
```

### Executing a Proposal

```clarity
;; Execute proposal after voting period ends
(contract-call? .DAOGovern execute-proposal u1)
```

### Reading Proposal Data

```clarity
;; Get proposal details
(contract-call? .DAOGovern get-proposal u1)

;; Check proposal status
(contract-call? .DAOGovern get-proposal-status u1)

;; Check if proposal passed
(contract-call? .DAOGovern has-proposal-passed u1)
```

## Contract Functions

### Public Functions

#### `create-proposal`
- **Purpose**: Creates a new governance proposal
- **Parameters**: 
  - `title` (string-ascii 100): Proposal title
  - `description` (string-ascii 500): Proposal description
- **Requirements**: Minimum voting power of 1 STX
- **Returns**: Proposal ID

#### `vote-on-proposal`
- **Purpose**: Cast a vote on an active proposal
- **Parameters**:
  - `proposal-id` (uint): ID of the proposal
  - `vote` (bool): true for "yes", false for "no"
- **Requirements**: 
  - Minimum voting power of 1 STX
  - Proposal must be active
  - Voting period must not have ended
  - User must not have already voted
- **Returns**: Success confirmation

#### `execute-proposal`
- **Purpose**: Execute a proposal after voting period ends
- **Parameters**: `proposal-id` (uint): ID of the proposal to execute
- **Requirements**: 
  - Voting period must have ended
  - Proposal must not be already executed
- **Returns**: Whether the proposal passed

#### `set-voting-power` (Owner Only)
- **Purpose**: Set voting power for a specific user
- **Parameters**:
  - `user` (principal): User's principal address
  - `power` (uint): Voting power amount
- **Requirements**: Only contract owner can call
- **Returns**: Success confirmation

#### `cancel-proposal`
- **Purpose**: Cancel an active proposal
- **Parameters**: `proposal-id` (uint): ID of the proposal to cancel
- **Requirements**: Only proposer or contract owner can call
- **Returns**: Success confirmation

### Read-Only Functions

#### `get-proposal`
Returns complete proposal details including votes and metadata.

#### `get-vote`
Returns voting details for a specific user and proposal.

#### `get-voting-power`
Returns the voting power of a specific user.

#### `get-current-proposal-id`
Returns the latest proposal ID.

#### `has-proposal-passed`
Checks if a proposal has more "yes" votes than "no" votes.

#### `get-proposal-status`
Returns comprehensive status information about a proposal.

## Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy the contract:
```clarity
::deploy_contracts
```

3. Test contract functions:
```clarity
::get_contracts
(contract-call? .DAOGovern get-current-proposal-id)
```

### Testnet Deployment

1. Configure your testnet settings in `settings/Testnet.toml`

2. Deploy to testnet:
```bash
clarinet deployments generate --testnet
clarinet deployments apply --testnet
```

### Mainnet Deployment

1. Configure your mainnet settings in `settings/Mainnet.toml`

2. Deploy to mainnet:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## Security Notes

### Access Controls
- Contract owner has privileged access to set voting power and cancel any proposal
- Only proposal creators and contract owner can cancel proposals
- Voting power requirements prevent spam proposals and votes

### Voting Integrity
- Users cannot vote multiple times on the same proposal
- Voting power is locked at the time of voting
- Time-bound voting prevents indefinite proposal states

### Error Handling
The contract implements comprehensive error handling with specific error codes:
- `u100`: Owner-only operation
- `u101`: Proposal not found
- `u102`: User already voted
- `u103`: Voting period ended
- `u104`: Voting period not ended
- `u105`: Insufficient balance/voting power
- `u106`: Proposal not active
- `u107`: Proposal already executed

### Best Practices
1. **Voting Power**: Consider implementing token-based voting power for more sophisticated governance
2. **Proposal Validation**: Add content validation and proposal formatting requirements
3. **Execution Logic**: Implement actual execution logic for passed proposals
4. **Multi-signature**: Consider multi-signature requirements for critical proposals
5. **Governance Evolution**: Plan for contract upgrades through governance proposals

## Testing

Run the test suite:
```bash
npm test
```

Run tests with coverage:
```bash
npm run test:report
```

Watch mode for development:
```bash
npm run test:watch
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the ISC License.

## Contract Address

- **Testnet**: `<To be deployed>`
- **Mainnet**: `<To be deployed>`

## Support

For support and questions, please open an issue in the repository or contact the development team.
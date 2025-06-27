 TrustNet Smart Contract

A decentralized trust and reputation management protocol built on the Stacks blockchain using Clarity. TrustNet allows anyone to list service providers, challenge untrustworthy listings, and resolve disputes through community voting.

---

 Overview

The TrustNet smart contract facilitates an on-chain reputation registry where service providers stake tokens to be listed. Anyone can challenge a listing by posting a counter-stake, and the community votes on the outcome. This ensures a trustless, transparent system for maintaining reliable providers in any decentralized marketplace or network.

---

 Features

-  **Provider Registration**  
  Providers can list themselves by submitting a profile and staking STX.

-  **Challenge Listings**  
  Anyone can challenge a provider’s trustworthiness by staking an equal or greater amount.

-  **Community Voting**  
  Token holders vote for or against the provider during a challenge period.

-  **Dispute Resolution**  
  The challenge is resolved based on the majority vote. Stakes are distributed accordingly.

-  **Read-Only Queries**  
  Retrieve provider details and approval status through view functions.

---

 Smart Contract Structure

 Storage Maps

- `providers`: Stores provider metadata and status (approved/challenged).
- `challenges`: Holds details about active disputes.
- `votes`: Tracks voter decisions and stake amounts.

 Key Functions

 Submit Provider
```clarity
(define-public (submit-provider (name ...) (contact ...) (description ...) (stake uint)))
(define-public (challenge-provider (id uint) (stake uint)))
(define-public (vote (id uint) (vote-for bool) (amount uint)))
(define-public (resolve (id uint)))
(define-read-only (get-provider (id uint)))
(define-read-only (is-approved (id uint)))

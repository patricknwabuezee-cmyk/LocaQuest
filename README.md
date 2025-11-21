
# LocaQuest -  Geotagged NFT Rewards Contract

A Clarity smart contract for creating **location-based activity rewards**, tracking user completions, issuing points, and minting **non-fungible tokens (NFTs)** once users meet a required threshold. This contract enables applications where users unlock achievements by physically visiting or interacting with specific geotagged locations.

---

## 🚀 Overview

This project implements a **geolocation-driven rewards system** on the Stacks blockchain.
Admins can register real-world locations with metadata such as:

* Name
* Latitude & longitude
* Activity description
* Reward point values

Users can then complete activities at these locations by submitting valid coordinates. When enough points are earned, they may mint a **geotagged NFT reward**.

The contract includes robust **error handling**, **data validation**, geospatial distance logic, NFT minting management, and an optional **point-transfer system** for peer-to-peer point sharing.

---

## ✨ Features

### 🗺️ Location Management (Admin Only)

* Add new locations with:

  * Coordinates
  * Activity details
  * Reward point values
* Enable/disable locations
* Enforced data validity (coordinates, names, point caps, etc.)

### 📍 Activity Completion (User)

* Users complete activities by sending their coordinates
* Contract validates proximity using a squared distance calculation
* Prevents duplicate activity completion
* Awards points to the user upon success

### 🪙 Points System

* Each location defines a reward value
* Points stored per user
* Points can be transferred between users
* Points deducted when minting NFTs

### 🎖️ NFT Minting

* Users can mint a **geotagged NFT** after reaching the required point threshold
* Token ID validation
* Prevents duplicate minting
* Uses the `nft-mint?` standard

### 🔒 Data Validation & Error Handling

* Invalid coordinates
* Invalid names or activity text
* Exceeded location limit
* Repeated completion attempts
* Insufficient point balance
* Disabled locations
* Invalid token IDs
* Zero-transfer amounts and self-transfer protection

### 👀 Read-Only Queries

* Get location data
* Check user point balance
* Query NFT mint status
* Check activity completion status
* Retrieve user statistics

---

## 📚 Contract Structure

* **Non-Fungible Token:** `geotagged-nft`
* **Maps:**

  * `locations`
  * `user-completions`
  * `user-points`
  * `location-status`
  * `minted-nfts`
* **Constants:** limits, thresholds, error codes, owner, geospatial rules
* **Private validation helpers:** coordinates, token ID, name/activity, user validation, distance calculation
* **Public functions:**

  * `add-location`
  * `set-location-status`
  * `complete-activity`
  * `mint-nft`
  * `transfer-points`
* **Read-only functions:** `get-user-points`, `get-location`, `get-user-stats` etc.

---

## 📦 Installation & Usage

### 1. Add to Your Stacks Project

Place the Clarity file into your `contracts/` directory.

### 2. Deploy with Clarinet

```sh
clarinet deploy
```

### 3. Interact with Functions

Using Clarinet console or Stacks Explorer, call:

* `add-location` (admin)
* `complete-activity` (user)
* `mint-nft` (user)
* `transfer-points` (user)

### 4. Query State

* `get-user-points`
* `get-location`
* `is-nft-minted`
* `get-user-stats`

---

## 🔐 Security Considerations

* Only the contract owner can add or modify location status
* User cannot complete the same activity twice
* Overflow-safe reward accumulation
* Prevents zero-amount transfers
* Prevents self-transfers
* Enforces token ID bounds
* Prevents minting NFTs without sufficient points
* Coordinates must be in valid ranges

---

## 🧭 Example Flow

1. **Admin** registers a new geotagged activity
2. **User** visits the location and submits coordinates
3. Contract validates:

   * Coordinates
   * Proximity
   * Not previously completed
4. User receives points
5. When points ≥ threshold, user **mints a geotagged NFT**
6. User may **transfer points** to others

---


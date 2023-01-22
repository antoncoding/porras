// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./enums.sol";

/**
 * @dev struct representing the current balance for a given collateral
 * @param collateralId grappa asset id
 * @param amount amount the asset
 */
struct Balance {
    uint8 collateralId;
    uint80 amount;
}

/**
 * @dev struct containing assets detail for an product
 * @param underlying    underlying address
 * @param strike        strike address
 * @param collateral    collateral address
 * @param collateralDecimals collateral asset decimals
 */
struct ProductDetails {
    address oracle;
    uint8 oracleId;
    address engine;
    uint8 engineId;
    address underlying;
    uint8 underlyingId;
    uint8 underlyingDecimals;
    address strike;
    uint8 strikeId;
    uint8 strikeDecimals;
    address collateral;
    uint8 collateralId;
    uint8 collateralDecimals;
}

// todo: update doc
struct ActionArgs {
    ActionType action;
    bytes data;
}

struct BatchExecute {
    address subAccount;
    ActionArgs[] actions;
}

/**
 * @dev asset detail stored per asset id
 * @param addr address of the asset
 * @param decimals token decimals
 */
struct AssetDetail {
    address addr;
    uint8 decimals;
}

/**
 * @dev struct to calculate settlement
 *      only used for physically settled tokens
 * @param engine
 * @param debtId asset id to pay debt with
 * @param debtPerToken amount owed per token
 * @param debt amount owed total
 * @param payoutId asset id to receive payout with
 * @param payoutPerToken amount paid per token
 * @param payout amount paid total
 */
struct Settlement {
    address engine;
    uint8 debtId;
    // uint256 debtPerToken;
    uint256 debt;
    uint8 payoutId;
    // uint256 payoutPerToken;
    uint256 payout;
}

/**
 * @dev struct to track issued and exercised tokens
 *      used for physically settled tokens to socialize debts and payouts
 * @param issued number of tokens mints
 * @param exercised amount exercised within settlement window
 */
struct PhysicalSettlementTracker {
    uint64 issued;
    uint64 exercised;
    // address debtAsset;
    // address collateralAsset;
    uint256 totalDebt;
    uint256 totalCollateralPaid;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import {IOracle} from "src/interfaces/IOracle.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";

import "src/config/errors.sol";

/**
 * @title Oracle
 * @author antoncoding
 * @dev return underlying / strike price, with 6 decimals
 */
contract Oracle is IOracle {
    struct ExpiryPrice {
        bool reported;
        uint128 price;
    }

    uint256 internal constant UNIT = 10**6;

    address public immutable primaryPricer;
    address public immutable secondaryPricer;

    // underlying => strike => expiry => price.
    mapping(address => mapping(address => mapping(uint256 => ExpiryPrice))) public expiryPrices;

    constructor(address _primaryPricer, address _secondaryPricer) {
        primaryPricer = _primaryPricer;
        secondaryPricer = _secondaryPricer;
    }

    /**
     * @dev get spot price of underlying, denominated in strike asset.
     */
    function getSpotPrice(
        address, /*_base*/
        address /*_quote*/
    ) external pure override returns (uint256 price) {
        return 3000 * 1e6;
    }

    /**
     * @dev get expiry price of underlying, denominated in strike asset.
            can revert if expiry is in the future, or the price is not reported by authorized party.
     */
    function getPriceAtExpiry(
        address _base,
        address _quote,
        uint256 _expiry
    ) external view returns (uint256 price) {
        ExpiryPrice memory data = expiryPrices[_base][_quote][_expiry];
        if (!data.reported) revert OC_PriceNotReported();

        return data.price;
    }

    function reportExpiryPrice(
        address _base,
        address _quote,
        uint256 _expiry,
        uint256 _price
    ) external {
        if (msg.sender != primaryPricer && msg.sender != secondaryPricer) revert OC_OnlyPricerCanWrite();
        //todo: safeCast to be extra safe
        expiryPrices[_base][_quote][_expiry] = ExpiryPrice(true, uint128(_price));
    }

    /**
     * @dev get volatility index
     */
    function getVolIndex() external pure returns (uint256) {
        return 1 * 1e6;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import {IVolOracle} from "../../../interfaces/IVolOracle.sol";
import {IAggregatorV3} from "../../../interfaces/IAggregatorV3.sol";

import {Ownable} from "openzeppelin/access/Ownable.sol";

// constants and types
import "../../../config/errors.sol";

/**
 * @title VolOracle
 * @author @antoncoding
 * @dev return vol for advanced margin calculation
 *      the vol is calculated by reading Chainlink oracle
 */
contract VolOracle is IVolOracle, Ownable {
    /// @dev asset address to chainlink aggregator
    mapping(address => address) public aggregators;

    event AggregatorUpdated(address _asset, address _aggregator);

    /**
     * @dev return base implied vol for an asset
     */
    function getImpliedVol(address _asset) external view returns (uint256 vol) {
        address aggregator = aggregators[_asset];
        if (aggregator == address(0)) revert VO_AggregatorNotSet();
        vol = 1e6;

        (, int256 answer, , , ) = IAggregatorV3(address(aggregator)).latestRoundData();
        // todo: convert decimals
        return uint256(answer);
    }

    /**
     * @dev update aggregator asset for an asset
     */
    function setAssetAggregator(address _asset, address _aggregator) external onlyOwner {
        if (aggregators[_asset] != address(0)) revert VO_AggregatorAlreadySet();
        aggregators[_asset] = _aggregator;

        emit AggregatorUpdated(_asset, _aggregator);
    }
}
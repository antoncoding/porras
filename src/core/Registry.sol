// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import {IERC20Metadata} from "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";

import {ProductIdUtil} from "../libraries/ProductIdUtil.sol";
import {AssetDetail} from "../config/types.sol";

contract Registry is Ownable {
    error AssetAlreadyRegistered();
    error MarginEngineAlreadyRegistered();

    /// @dev next id used to represent an address
    /// invariant:  any id in tokenId not greater than this number
    uint8 public nextAssetId;

    /// @dev next id used to represent an address
    /// invariant:  any id in tokenId not greater than this number
    uint8 public nextamEngineId;

    /// @dev assetId => asset address
    mapping(uint8 => AssetDetail) public assets;

    /// @dev assetId => margin engine address
    mapping(uint8 => address) public engines;

    /// @dev address => assetId
    mapping(address => uint8) public assetIds;
    /// @dev address => amEngineId
    mapping(address => uint8) public amEngineIds;

    /// Events

    event AssetRegistered(address asset, uint8 id);
    event MarginEngineRegistered(address engine, uint8 id);

    // solhint-disable-next-line no-empty-blocks
    constructor() Ownable() {}

    /**
     * @dev parse product id into composing asset and engine addresses
     * @param _productId product id
     */
    function getDetailFromProductId(uint32 _productId)
        public
        view
        returns (
            address engine,
            address underlying,
            address strike,
            address collateral,
            uint8 collateralDecimals
        )
    {
        (uint8 amEngineId, uint8 underlyingId, uint8 strikeId, uint8 collateralId) = ProductIdUtil.parseProductId(
            _productId
        );
        AssetDetail memory collateralDetail = assets[collateralId];
        return (
            engines[amEngineId],
            assets[underlyingId].addr,
            assets[strikeId].addr,
            collateralDetail.addr,
            collateralDetail.decimals
        );
    }

    /**
     * @dev parse only the engine address from productId
     * @param _productId product id
     */
    function getEngineFromProductId(uint32 _productId) public view returns (address engine) {
        (uint8 amEngineId, , , ) = ProductIdUtil.parseProductId(_productId);
        engine = engines[amEngineId];
    }

    /**
     * @notice    get product id from underlying, strike and collateral address
     * @dev       function will still return even if some of the assets are not registered
     * @param underlying  underlying address
     * @param strike      strike address
     * @param collateral  collateral address
     */
    function getProductId(
        uint8 amEngineId,
        address underlying,
        address strike,
        address collateral
    ) external view returns (uint32 id) {
        id = ProductIdUtil.getProductId(amEngineId, assetIds[underlying], assetIds[strike], assetIds[collateral]);
    }

    /**
     * @dev register an asset to be used as strike/underlying
     * @param _asset address to add
     **/
    function registerAsset(address _asset) external onlyOwner returns (uint8 id) {
        if (assetIds[_asset] != 0) revert AssetAlreadyRegistered();

        uint8 decimals = IERC20Metadata(_asset).decimals();

        id = ++nextAssetId;
        assets[id] = AssetDetail({addr: _asset, decimals: decimals});
        assetIds[_asset] = id;

        emit AssetRegistered(_asset, id);
    }

    /**
     * @dev register an engine to create / settle options
     * @param _engine address of the new margin engine
     **/
    function registerEngine(address _engine) external onlyOwner returns (uint8 id) {
        if (amEngineIds[_engine] != 0) revert MarginEngineAlreadyRegistered();

        id = ++nextamEngineId;
        engines[id] = _engine;

        amEngineIds[_engine] = id;

        emit MarginEngineRegistered(_engine, id);
    }
}

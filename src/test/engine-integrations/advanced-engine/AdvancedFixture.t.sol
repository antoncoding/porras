// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../../mocks/MockERC20.sol";
import "../../mocks/MockOracle.sol";
import "../../mocks/MockChainlinkAggregator.sol";

import "../../../core/engines/advanced-margin/AdvancedMarginEngine.sol";
import "../../../core/engines/advanced-margin/VolOracle.sol";
import "../../../core/Grappa.sol";
import "../../../core/OptionToken.sol";

import "../../../config/enums.sol";
import "../../../config/types.sol";

import "../../utils/Utilities.sol";

import {ActionHelper} from "../../shared/ActionHelper.sol";

// solhint-disable max-states-count

abstract contract AdvancedFixture is Test, ActionHelper, Utilities {
    AdvancedMarginEngine internal engine;
    Grappa internal grappa;
    OptionToken internal option;

    MockERC20 internal usdc;
    MockERC20 internal weth;

    MockOracle internal oracle;

    VolOracle public volOracle;
    MockChainlinkAggregator public ethVolAggregator;
    MockChainlinkAggregator public wbtcVolAggregator;

    address internal alice;
    address internal charlie;
    address internal bob;

    // usdc collateralized call / put
    uint32 internal productId;

    // eth collateralized call / put
    uint32 internal productIdEthCollat;

    uint8 internal usdcId;
    uint8 internal wethId;

    uint8 internal engineId;

    constructor() {
        usdc = new MockERC20("USDC", "USDC", 6); // nonce: 1

        weth = new MockERC20("WETH", "WETH", 18); // nonce: 2

        oracle = new MockOracle(); // nonce: 3

        // predit address of margin account and use it here
        address grappaAddr = predictAddress(address(this), 5);

        option = new OptionToken(grappaAddr); // nonce: 4

        grappa = new Grappa(address(option), address(oracle)); // nonce: 5

        volOracle = new VolOracle();

        engine = new AdvancedMarginEngine(address(grappa), address(oracle), address(volOracle), address(option)); // nonce 6

        // mock vol oracles
        ethVolAggregator = new MockChainlinkAggregator(6);
        // wbtcVolAggregator = new MockChainlinkAggregator(6);
        volOracle.setAssetAggregator(address(weth), address(ethVolAggregator));
        ethVolAggregator.setMockState(0, 1e6, block.timestamp);

        // register products
        usdcId = grappa.registerAsset(address(usdc));
        wethId = grappa.registerAsset(address(weth));

        engineId = grappa.registerEngine(address(engine));

        // engineId = grappa.registerEngine(address(engine));

        productId = grappa.getProductId(engineId, address(weth), address(usdc), address(usdc));
        productIdEthCollat = grappa.getProductId(engineId, address(weth), address(usdc), address(weth));

        engine.setProductMarginConfig(productId, 180 days, 1 days, 6400, 800, 10000);
        engine.setProductMarginConfig(productIdEthCollat, 180 days, 1 days, 6400, 800, 10000);

        charlie = address(0xcccc);
        vm.label(charlie, "Charlie");

        bob = address(0xb00b);
        vm.label(bob, "Bob");

        alice = address(0xaaaa);
        vm.label(alice, "Alice");

        // make sure timestamp is not 0
        vm.warp(0xffff);

        usdc.mint(alice, 1000_000_000 * 1e6);
        usdc.mint(bob, 1000_000_000 * 1e6);
        usdc.mint(charlie, 1000_000_000 * 1e6);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function mintOptionFor(
        address _recipient,
        uint256 _tokenId,
        uint32 _productId,
        uint256 _amount
    ) internal {
        address anon = address(0x42424242);

        vm.startPrank(anon);

        uint256 lotOfCollateral = 1_000 * 1e18;

        usdc.mint(anon, lotOfCollateral);
        weth.mint(anon, lotOfCollateral);
        usdc.approve(address(engine), type(uint256).max);
        weth.approve(address(engine), type(uint256).max);

        ActionArgs[] memory actions = new ActionArgs[](2);

        // the last 8 bits is collateral id
        uint8 collateralId = uint8(_productId);

        actions[0] = createAddCollateralAction(collateralId, address(anon), lotOfCollateral);
        actions[1] = createMintAction(_tokenId, address(_recipient), _amount);
        engine.execute(address(anon), actions);

        vm.stopPrank();
    }
}

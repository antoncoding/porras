// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import test base and helpers.
import {FullMarginFixtureV2} from "./FullMarginFixtureV2.t.sol";

import "../../../config/enums.sol";
import "../../../config/types.sol";
import "../../../config/constants.sol";
import "../../../config/errors.sol";

import "../../utils/Console.sol";

// solhint-disable-next-line contract-name-camelcase
contract TestBatchExecute_FMV2 is FullMarginFixtureV2 {
    uint256 public expiry;
    uint256 public tokenId;
    uint256 public depositAmount = 1 * 1e18;
    uint256 public strikePrice = 4000 * UNIT;
    uint256 public amount = 1 * UNIT;

    function setUp() public {
        usdc.mint(address(this), 1000_000 * 1e6);
        usdc.approve(address(engine), type(uint256).max);

        weth.mint(address(this), 100 * 1e18);
        weth.approve(address(engine), type(uint256).max);

        weth.mint(alice, 100 * 1e18);

        vm.startPrank(alice);
        weth.approve(address(engine), type(uint256).max);
        engine.setAccountAccess(address(this), type(uint256).max);
        vm.stopPrank();

        expiry = block.timestamp + 1 days;

        tokenId = getTokenId(TokenType.CALL, pidEthCollat, expiry, strikePrice, 0);

        oracle.setSpotPrice(address(weth), 2000 * UNIT);
    }

    function testMintTwoSidedStructure() public {
        ActionArgs[] memory aliceActions = new ActionArgs[](2);
        aliceActions[0] = createAddCollateralAction(wethId, alice, depositAmount);
        aliceActions[1] = createMintIntoAccountAction(tokenId, address(this), amount);

        ActionArgs[] memory selfActions = new ActionArgs[](2);
        selfActions[0] = createAddCollateralAction(wethId, address(this), depositAmount);
        selfActions[1] = createMintIntoAccountAction(tokenId, alice, amount);

        BatchExecute[] memory batch = new BatchExecute[](2);
        batch[0] = BatchExecute(alice, aliceActions);
        batch[1] = BatchExecute(address(this), selfActions);

        engine.batchExecute(batch);

        (Position[] memory aliceShorts, Position[] memory aliceLongs, Balance[] memory aliceCollaters) = engine
            .marginAccounts(alice);

        assertEq(aliceShorts.length, 1);
        assertEq(aliceShorts[0].tokenId, tokenId);
        assertEq(aliceShorts[0].amount, amount);

        assertEq(aliceLongs.length, 1);
        assertEq(aliceLongs[0].tokenId, tokenId);
        assertEq(aliceLongs[0].amount, amount);

        assertEq(aliceCollaters.length, 1);
        assertEq(aliceCollaters[0].collateralId, wethId);
        assertEq(aliceCollaters[0].amount, depositAmount);

        (Position[] memory selfShorts, Position[] memory selfLongs, Balance[] memory selfCollaters) = engine
            .marginAccounts(address(this));

        assertEq(selfShorts.length, 1);
        assertEq(selfShorts[0].tokenId, tokenId);
        assertEq(selfShorts[0].amount, amount);

        assertEq(selfLongs.length, 1);
        assertEq(selfLongs[0].tokenId, tokenId);
        assertEq(selfLongs[0].amount, amount);

        assertEq(selfCollaters.length, 1);
        assertEq(selfCollaters[0].collateralId, wethId);
        assertEq(selfCollaters[0].amount, depositAmount);
    }

    function testMintSpreadChecksCollateralAfterBatch() public {
        uint256 k1 = 2100 * UNIT;
        uint256 k2 = 2101 * UNIT;
        uint256 tokenId1 = getTokenId(TokenType.CALL, pidEthCollat, expiry, k1, 0);
        uint256 tokenId2 = getTokenId(TokenType.CALL, pidEthCollat, expiry, k2, 0);
        // we are making a $1 wide call spread, so you should only need $1 of collateral for this

        ActionArgs[] memory aliceActions = new ActionArgs[](2);
        // alice will be long the call spread, so needs no collateral
        // we'll deposit 0 just for fun, see if it breaks anything
        aliceActions[0] = createAddCollateralAction(wethId, alice, 0);
        // alice is minting, and thus long, the lower k1 strike and givnig the short to address(this)
        aliceActions[1] = createMintIntoAccountAction(tokenId1, address(this), amount);

        ActionArgs[] memory selfActions = new ActionArgs[](2);
        uint256 requiredCollateral = ((k2 - k1) * 1e18) / k2; // should this be using sUNIT? we use 1e18 above
        // TODO: probably need to add this to the math library tests and also do a usdc one
        selfActions[0] = createAddCollateralAction(wethId, address(this), requiredCollateral);
        // self is minting and giving the short to alice of the higher k2 strike
        selfActions[1] = createMintIntoAccountAction(tokenId2, alice, amount);

        BatchExecute[] memory batch = new BatchExecute[](2);
        batch[0] = BatchExecute(alice, aliceActions);
        batch[1] = BatchExecute(address(this), selfActions);

        engine.batchExecute(batch);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// import test base and helpers.
import {Fixture} from "../../shared/Fixture.t.sol";
import {stdError} from "forge-std/Test.sol";

import "../../../config/enums.sol";
import "../../../config/types.sol";
import "../../../config/constants.sol";
import "../../../config/errors.sol";

contract TestLiquidateCall is Fixture {
    uint256 public expiry;

    uint64 private amount = uint64(1 * UNIT);
    uint256 private tokenId;
    uint64 private strike;
    uint256 private initialCollateral;

    address private accountId;

    function setUp() public {
        // setup account for alice
        usdc.mint(alice, 1000_000 * 1e6);

        vm.startPrank(alice);
        usdc.approve(address(grappa), type(uint256).max);

        expiry = block.timestamp + 7 days;

        oracle.setSpotPrice(address(weth), 3500 * UNIT);

        // mint option
        initialCollateral = 500 * 1e6;

        strike = uint64(4000 * UNIT);

        accountId = alice;

        tokenId = getTokenId(TokenType.CALL, productId, expiry, strike, 0);
        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(usdcId, alice, initialCollateral);
        // give optoin to this address, so it can liquidate alice
        actions[1] = createMintAction(tokenId, address(this), amount);

        // mint option
        grappa.execute(engineId, accountId, actions);

        vm.stopPrank();
    }

    function testGetMinCollateralShouldReturnProperValue() public {
        uint256 minCollateral = marginEngine.getMinCollateral(accountId);
        assertTrue(minCollateral < initialCollateral);
    }

    function testCannotLiquidateHealthyVault() public {
        vm.expectRevert(MA_AccountIsHealthy.selector);
        liquidateWithIdAndAmounts(accountId, tokenId, 0, amount, 0);
    }

    function testCannotLiquidateVaultWithPut() public {
        oracle.setSpotPrice(address(weth), 3600 * UNIT);

        uint256 putId = getTokenId(TokenType.PUT, productId, expiry, strike, 0);

        vm.expectRevert(MA_WrongIdToLiquidate.selector);
        liquidateWithIdAndAmounts(accountId, 0, putId, 0, amount);
    }

    function testCannotLiquidateVaultWithPutAmount() public {
        oracle.setSpotPrice(address(weth), 3800 * UNIT);

        vm.expectRevert(MA_WrongRepayAmounts.selector);
        liquidateWithIdAndAmounts(accountId, tokenId, 0, 0, amount);
    }

    function testPartiallyLiquidateTheVault() public {
        oracle.setSpotPrice(address(weth), 3800 * UNIT);

        uint256 usdcBalanceBefore = usdc.balanceOf(address(this));
        uint256 optionBalanceBefore = option.balanceOf(address(this), tokenId);

        uint64 liquidateAmount = amount / 2;
        liquidateWithIdAndAmounts(accountId, tokenId, 0, liquidateAmount, 0);

        uint256 expectCollateralToGet = initialCollateral / 2;
        uint256 usdcBalanceAfter = usdc.balanceOf(address(this));
        uint256 optionBalanceAfter = option.balanceOf(address(this), tokenId);

        assertEq(usdcBalanceAfter - usdcBalanceBefore, expectCollateralToGet);
        assertEq(optionBalanceBefore - optionBalanceAfter, liquidateAmount);
    }

    function testFullyLiquidateTheVault() public {
        oracle.setSpotPrice(address(weth), 3800 * UNIT);

        uint256 usdcBalanceBefore = usdc.balanceOf(address(this));
        uint256 optionBalanceBefore = option.balanceOf(address(this), tokenId);

        liquidateWithIdAndAmounts(accountId, tokenId, 0, amount, 0);

        uint256 usdcBalanceAfter = usdc.balanceOf(address(this));
        uint256 optionBalanceAfter = option.balanceOf(address(this), tokenId);

        assertEq(usdcBalanceAfter - usdcBalanceBefore, initialCollateral);
        assertEq(optionBalanceBefore - optionBalanceAfter, amount);

        //margin account should be reset
        (uint256 shortCallId, , uint64 shortCallAmount, , uint80 collateralAmount, uint8 collateralId) = marginEngine
            .marginAccounts(accountId);

        assertEq(shortCallId, 0);
        assertEq(shortCallAmount, 0);
        assertEq(collateralAmount, 0);
        assertEq(collateralId, 0);
    }

    function testCannotLiquidateMoreThanDebt() public {
        oracle.setSpotPrice(address(weth), 3800 * UNIT);

        vm.expectRevert(stdError.arithmeticError);
        liquidateWithIdAndAmounts(accountId, tokenId, 0, amount + 1, 0);
    }

    function liquidateWithIdAndAmounts(
        address _accountId,
        uint256 _callId,
        uint256 _putId,
        uint256 _callAmount,
        uint256 _putAmount
    ) private {
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = _callId;
        ids[1] = _putId;
        amounts[0] = _callAmount;
        amounts[1] = _putAmount;
        grappa.liquidate(address(marginEngine), _accountId, ids, amounts);
    }
}

contract TestLiquidatePut is Fixture {
    uint256 public expiry;

    uint64 private amount = uint64(1 * UNIT);
    uint256 private tokenId;
    uint64 private strike;
    uint256 private initialCollateral;

    address private accountId;

    function setUp() public {
        // setup account for alice
        usdc.mint(alice, 1000_000 * 1e6);

        vm.startPrank(alice);
        usdc.approve(address(grappa), type(uint256).max);

        expiry = block.timestamp + 7 days;

        oracle.setSpotPrice(address(weth), 4000 * UNIT);

        // mint option
        initialCollateral = 500 * 1e6;

        strike = uint64(3500 * UNIT);

        accountId = alice;

        tokenId = getTokenId(TokenType.PUT, productId, expiry, strike, 0);
        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(usdcId, alice, initialCollateral);
        // give optoin to this address, so it can liquidate alice
        actions[1] = createMintAction(tokenId, address(this), amount);

        // mint option
        grappa.execute(engineId, accountId, actions);

        vm.stopPrank();
    }

    function liquidateWithIdAndAmounts(
        address _accountId,
        uint256 _callId,
        uint256 _putId,
        uint256 _callAmount,
        uint256 _putAmount
    ) private {
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = _callId;
        ids[1] = _putId;
        amounts[0] = _callAmount;
        amounts[1] = _putAmount;
        grappa.liquidate(address(marginEngine), _accountId, ids, amounts);
    }

    function testCannotLiquidateHealthyVault() public {
        vm.expectRevert(MA_AccountIsHealthy.selector);
        liquidateWithIdAndAmounts(accountId, 0, tokenId, 0, amount);
    }

    function testCannotLiquidateVaultWithCall() public {
        oracle.setSpotPrice(address(weth), 3600 * UNIT);

        uint256 callId = getTokenId(TokenType.CALL, productId, expiry, strike, 0);

        vm.expectRevert(MA_WrongIdToLiquidate.selector);
        liquidateWithIdAndAmounts(accountId, 0, callId, 0, amount);
    }

    function testCannotLiquidateVaultWithCallAmount() public {
        oracle.setSpotPrice(address(weth), 3600 * UNIT);

        vm.expectRevert(MA_WrongRepayAmounts.selector);
        liquidateWithIdAndAmounts(accountId, 0, tokenId, amount, 0);
    }

    function testPartiallyLiquidateTheVault() public {
        oracle.setSpotPrice(address(weth), 3600 * UNIT);

        uint256 usdcBalanceBefore = usdc.balanceOf(address(this));
        uint256 optionBalanceBefore = option.balanceOf(address(this), tokenId);

        uint64 liquidateAmount = amount / 2;
        liquidateWithIdAndAmounts(accountId, 0, tokenId, 0, liquidateAmount);

        uint256 expectCollateralToGet = initialCollateral / 2;
        uint256 usdcBalanceAfter = usdc.balanceOf(address(this));
        uint256 optionBalanceAfter = option.balanceOf(address(this), tokenId);

        assertEq(usdcBalanceAfter - usdcBalanceBefore, expectCollateralToGet);
        assertEq(optionBalanceBefore - optionBalanceAfter, liquidateAmount);
    }

    function testFullyLiquidateTheVault() public {
        oracle.setSpotPrice(address(weth), 3600 * UNIT);

        uint256 usdcBalanceBefore = usdc.balanceOf(address(this));
        uint256 optionBalanceBefore = option.balanceOf(address(this), tokenId);

        liquidateWithIdAndAmounts(accountId, 0, tokenId, 0, amount);

        uint256 usdcBalanceAfter = usdc.balanceOf(address(this));
        uint256 optionBalanceAfter = option.balanceOf(address(this), tokenId);

        assertEq(usdcBalanceAfter - usdcBalanceBefore, initialCollateral);
        assertEq(optionBalanceBefore - optionBalanceAfter, amount);

        //margin account should be reset
        (uint256 shortCallId, , uint64 shortCallAmount, , uint80 collateralAmount, uint8 collateralId) = marginEngine
            .marginAccounts(accountId);

        assertEq(shortCallId, 0);
        assertEq(shortCallAmount, 0);
        assertEq(collateralAmount, 0);
        assertEq(collateralId, 0);
    }
}

contract TestLiquidateCallAndPut is Fixture {
    uint256 public expiry;

    uint64 private amount = uint64(1 * UNIT);
    uint256 private callId;
    uint256 private putId;

    uint64 private callStrike;
    uint64 private putStrike;

    uint256 private initialCollateral;

    address private accountId;

    function setUp() public {
        // setup account for alice
        usdc.mint(alice, 1000_000 * 1e6);

        vm.startPrank(alice);
        usdc.approve(address(grappa), type(uint256).max);

        expiry = block.timestamp + 7 days;

        oracle.setSpotPrice(address(weth), 4000 * UNIT);

        // mint option
        initialCollateral = 600 * 1e6;

        callStrike = uint64(4500 * UNIT);
        putStrike = uint64(3500 * UNIT);

        accountId = alice;

        callId = getTokenId(TokenType.CALL, productId, expiry, callStrike, 0);
        putId = getTokenId(TokenType.PUT, productId, expiry, putStrike, 0);
        ActionArgs[] memory actions = new ActionArgs[](3);
        actions[0] = createAddCollateralAction(usdcId, alice, initialCollateral);
        // give optoins to this address, so it can liquidate alice
        actions[1] = createMintAction(callId, address(this), amount);
        actions[2] = createMintAction(putId, address(this), amount);

        // mint option
        grappa.execute(engineId, accountId, actions);

        vm.stopPrank();
    }

    function liquidateWithIdAndAmounts(
        address _accountId,
        uint256 _callId,
        uint256 _putId,
        uint256 _callAmount,
        uint256 _putAmount
    ) private {
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = _callId;
        ids[1] = _putId;
        amounts[0] = _callAmount;
        amounts[1] = _putAmount;
        grappa.liquidate(address(marginEngine), _accountId, ids, amounts);
    }

    function testCannotLiquidateHealthyVault() public {
        vm.expectRevert(MA_AccountIsHealthy.selector);
        liquidateWithIdAndAmounts(accountId, callId, putId, amount, amount);
    }

    function testCannotLiquidateWithOnlySpecifyCallAmount() public {
        oracle.setSpotPrice(address(weth), 3300 * UNIT);

        vm.expectRevert(MA_WrongRepayAmounts.selector);
        liquidateWithIdAndAmounts(accountId, callId, putId, amount, 0);
    }

    function testCannotLiquidateWithImbalancedAmount() public {
        oracle.setSpotPrice(address(weth), 3300 * UNIT);

        vm.expectRevert(MA_WrongRepayAmounts.selector);
        liquidateWithIdAndAmounts(accountId, callId, putId, amount, amount - 1);

        vm.expectRevert(MA_WrongRepayAmounts.selector);
        liquidateWithIdAndAmounts(accountId, callId, putId, amount - 1, amount);
    }

    function testCannotLiquidateWithOnlySpecifyPutAmount() public {
        oracle.setSpotPrice(address(weth), 3300 * UNIT);

        vm.expectRevert(MA_WrongRepayAmounts.selector);
        liquidateWithIdAndAmounts(accountId, callId, putId, 0, amount);
    }

    function testPartiallyLiquidateTheVault() public {
        oracle.setSpotPrice(address(weth), 3300 * UNIT);

        uint256 usdcBalanceBefore = usdc.balanceOf(address(this));
        uint256 callBefore = option.balanceOf(address(this), callId);
        uint256 putBefore = option.balanceOf(address(this), putId);

        uint64 liquidateAmount = amount / 2;
        liquidateWithIdAndAmounts(accountId, callId, putId, liquidateAmount, liquidateAmount);

        uint256 expectCollateralToGet = initialCollateral / 2;
        uint256 usdcBalanceAfter = usdc.balanceOf(address(this));
        uint256 callAfter = option.balanceOf(address(this), callId);
        uint256 putAfter = option.balanceOf(address(this), putId);

        assertEq(usdcBalanceAfter - usdcBalanceBefore, expectCollateralToGet);
        assertEq(callBefore - callAfter, liquidateAmount);
        assertEq(putBefore - putAfter, liquidateAmount);
    }

    function testFullyLiquidateTheVault() public {
        oracle.setSpotPrice(address(weth), 3300 * UNIT);

        uint256 usdcBalanceBefore = usdc.balanceOf(address(this));
        uint256 callBefore = option.balanceOf(address(this), callId);
        uint256 putBefore = option.balanceOf(address(this), putId);

        liquidateWithIdAndAmounts(accountId, callId, putId, amount, amount);

        uint256 usdcBalanceAfter = usdc.balanceOf(address(this));
        uint256 callAfter = option.balanceOf(address(this), callId);
        uint256 putAfter = option.balanceOf(address(this), putId);

        assertEq(usdcBalanceAfter - usdcBalanceBefore, initialCollateral);
        assertEq(callBefore - callAfter, amount);
        assertEq(putBefore - putAfter, amount);

        //margin account should be reset
        (
            uint256 shortCallId,
            uint256 shortPutId,
            uint64 shortCallAmount,
            uint64 shortPutAmount,
            uint80 collateralAmount,
            uint8 collateralId
        ) = marginEngine.marginAccounts(accountId);

        assertEq(shortCallId, 0);
        assertEq(shortPutId, 0);
        assertEq(shortCallAmount, 0);
        assertEq(shortPutAmount, 0);
        assertEq(collateralAmount, 0);
        assertEq(collateralId, 0);
    }
}

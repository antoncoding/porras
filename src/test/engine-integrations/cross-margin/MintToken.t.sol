// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import test base and helpers.
import {CrossMarginFixture} from "./CrossMarginFixture.t.sol";

import "../../../config/enums.sol";
import "../../../config/types.sol";
import "../../../config/constants.sol";
import "../../../config/errors.sol";

import "../../../core/engines/cross-margin/types.sol";

import "../../../test/mocks/MockERC20.sol";

// solhint-disable-next-line contract-name-camelcase
contract TestMint_CM is CrossMarginFixture {
    uint256 public expiry;

    function setUp() public {
        usdc.mint(address(this), 1000_000 * 1e6);
        usdc.approve(address(engine), type(uint256).max);

        weth.mint(address(this), 100 * 1e18);
        weth.approve(address(engine), type(uint256).max);

        expiry = block.timestamp + 14 days;

        oracle.setSpotPrice(address(weth), 3000 * UNIT);
    }

    function testMintCall() public {
        uint256 depositAmount = 1 * 1e18;

        uint256 strikePrice = 4000 * UNIT;
        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.CALL, SettlementType.CASH, pidEthCollat, expiry, strikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(wethId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);
        engine.execute(address(this), actions);

        (Position[] memory shorts,,) = engine.marginAccounts(address(this));

        assertEq(shorts.length, 1);
        assertEq(shorts[0].tokenId, tokenId);
        assertEq(shorts[0].amount, amount);

        assertEq(option.balanceOf(address(this), tokenId), amount);
    }

    function testMintCallPhysicallySettled() public {
        uint256 depositAmount = 1 * 1e18;

        uint256 strikePrice = 4000 * UNIT;
        uint256 amount = 1 * UNIT;

        uint16 issuerId = engine.registerIssuer(address(this));

        uint256 tokenId = getTokenId(TokenType.CALL, SettlementType.PHYSICAL, pidEthCollat, expiry, strikePrice, issuerId);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(wethId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);
        engine.execute(address(this), actions);

        (Position[] memory shorts,,) = engine.marginAccounts(address(this));

        assertEq(shorts.length, 1);
        assertEq(shorts[0].tokenId, tokenId);
        assertEq(shorts[0].amount, amount);

        assertEq(option.balanceOf(address(this), tokenId), amount);
    }

    function testCannotMintCallPhysicallySettledWithIncorrectIssuerSet() public {
        uint256 depositAmount = 1 * 1e18;

        uint256 strikePrice = 4000 * UNIT;
        uint256 amount = 1 * UNIT;

        uint16 issuerId = engine.registerIssuer(address(this));

        uint256 tokenId = getTokenId(TokenType.CALL, SettlementType.PHYSICAL, pidEthCollat, expiry, strikePrice, issuerId + 1);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(wethId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);

        vm.expectRevert(PS_InvalidIssuerAddress.selector);
        engine.execute(address(this), actions);
    }

    function testCannotMintCallWithUsdcCollateral() public {
        uint256 depositAmount = 1000 * UNIT;

        uint256 strikePrice = 4000 * UNIT;
        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.CALL, SettlementType.CASH, pidUsdcCollat, expiry, strikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(wethId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);

        vm.expectRevert(CM_CannotMintOptionWithThisCollateral.selector);
        engine.execute(address(this), actions);
    }

    function testMintPut() public {
        uint256 depositAmount = 2000 * 1e6;

        uint256 strikePrice = 2000 * UNIT;
        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.PUT, SettlementType.CASH, pidUsdcCollat, expiry, strikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(usdcId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);
        engine.execute(address(this), actions);

        (Position[] memory shorts,,) = engine.marginAccounts(address(this));

        assertEq(shorts.length, 1);
        assertEq(shorts[0].tokenId, tokenId);
        assertEq(shorts[0].amount, amount);

        assertEq(option.balanceOf(address(this), tokenId), amount);
    }

    function testMintCallAndPutInSameAccount() public {
        uint256 callDepositAmount = 1 * 1e18;

        uint256 callStrikePrice = 4000 * UNIT;
        uint256 callAmount = 1 * UNIT;

        uint256 callTokenId = getTokenId(TokenType.CALL, SettlementType.CASH, pidEthCollat, expiry, callStrikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](4);
        actions[0] = createAddCollateralAction(wethId, address(this), callDepositAmount);
        actions[1] = createMintAction(callTokenId, address(this), callAmount);

        uint256 putDepositAmount = 2000 * 1e6;

        uint256 putStrikePrice = 2000 * UNIT;
        uint256 putAmount = 1 * UNIT;

        uint256 putTokenId = getTokenId(TokenType.PUT, SettlementType.CASH, pidUsdcCollat, expiry, putStrikePrice, 0);

        actions[2] = createAddCollateralAction(usdcId, address(this), putDepositAmount);
        actions[3] = createMintAction(putTokenId, address(this), putAmount);

        engine.execute(address(this), actions);

        (Position[] memory shorts,, Balance[] memory collaterals) = engine.marginAccounts(address(this));

        assertEq(shorts.length, 2);
        assertEq(shorts[0].tokenId, callTokenId);
        assertEq(shorts[1].tokenId, putTokenId);
        assertEq(shorts[0].amount, callAmount);
        assertEq(shorts[1].amount, putAmount);

        assertEq(collaterals.length, 2);
        assertEq(collaterals[0].collateralId, wethId);
        assertEq(collaterals[1].collateralId, usdcId);
        assertEq(collaterals[0].amount, callDepositAmount);
        assertEq(collaterals[1].amount, putDepositAmount);

        assertEq(option.balanceOf(address(this), callTokenId), callAmount);
        assertEq(option.balanceOf(address(this), putTokenId), putAmount);
    }

    function testCannotMintExpiredOption() public {
        uint256 strikePrice = 2000 * UNIT;
        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.PUT, SettlementType.CASH, pidUsdcCollat, block.timestamp, strikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](1);
        actions[0] = createMintAction(tokenId, address(this), amount);

        vm.expectRevert(GP_InvalidExpiry.selector);
        engine.execute(address(this), actions);
    }

    function testCannotMintPutWithETHCollateral() public {
        uint256 depositAmount = 1 * 1e18;

        uint256 strikePrice = 4000 * UNIT;
        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.PUT, SettlementType.CASH, pidEthCollat, expiry, strikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(wethId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);

        vm.expectRevert(CM_CannotMintOptionWithThisCollateral.selector);
        engine.execute(address(this), actions);
    }

    function testCannotMintCallWithLittleCollateral() public {
        uint256 depositAmount = 100 * 1e6;

        uint256 strikePrice = 4000 * UNIT;
        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.CALL, SettlementType.CASH, pidEthCollat, expiry, strikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(usdcId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);

        vm.expectRevert(BM_AccountUnderwater.selector);
        engine.execute(address(this), actions);
    }

    function testCannotMintPutWithLittleCollateral() public {
        uint256 depositAmount = 100 * 1e6;

        uint256 strikePrice = 2000 * UNIT;
        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.PUT, SettlementType.CASH, pidUsdcCollat, expiry, strikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(usdcId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);

        vm.expectRevert(BM_AccountUnderwater.selector);
        engine.execute(address(this), actions);
    }

    function testCannotMintWithoutCollateral() public {
        uint256 strikePrice = 3000 * UNIT;
        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.CALL, SettlementType.CASH, pidEthCollat, expiry, strikePrice, 0);

        ActionArgs[] memory actions = new ActionArgs[](1);
        actions[0] = createMintAction(tokenId, address(this), amount);

        vm.expectRevert(BM_AccountUnderwater.selector);
        engine.execute(address(this), actions);
    }

    function testCannotMintCallSpread() public {
        uint256 longStrike = 2800 * UNIT;
        uint256 shortStrike = 2600 * UNIT;

        uint256 depositAmount = longStrike - shortStrike;

        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.CALL_SPREAD, SettlementType.CASH, pidUsdcCollat, expiry, longStrike, shortStrike);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(usdcId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);

        vm.expectRevert(CM_UnsupportedOptionType.selector);
        engine.execute(address(this), actions);
    }

    function testCannotMintPutSpread() public {
        uint256 longStrike = 2800 * UNIT;
        uint256 shortStrike = 2600 * UNIT;

        uint256 depositAmount = longStrike - shortStrike;

        uint256 amount = 1 * UNIT;

        uint256 tokenId = getTokenId(TokenType.PUT_SPREAD, SettlementType.CASH, pidUsdcCollat, expiry, longStrike, shortStrike);

        ActionArgs[] memory actions = new ActionArgs[](2);
        actions[0] = createAddCollateralAction(usdcId, address(this), depositAmount);
        actions[1] = createMintAction(tokenId, address(this), amount);

        vm.expectRevert(CM_UnsupportedOptionType.selector);
        engine.execute(address(this), actions);
    }
}

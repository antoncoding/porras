// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import {Test} from "forge-std/Test.sol";

import {FullMarginMath} from "../../../core/engines/full-margin/FullMarginMath.sol";
import "../../../config/constants.sol";
import "../../../config/errors.sol";
import "../../../config/types.sol";

/**
 * test full margin calculation for simple call
 */
contract FullMarginMathTestCall is Test {
    using FullMarginMath for FullMarginDetail;

    function testMarginRequireCall() public {
        FullMarginDetail memory detail = FullMarginDetail({
            shortAmount: UNIT,
            longStrike: 0,
            shortStrike: 3000 * UNIT,
            collateralAmount: 0,
            collateralId: 0,
            collateralDecimals: 6,
            tokenType: TokenType.CALL
        });

        uint256 collat = detail.getMinCollateral();
        uint256 expectedRequirement = UNIT;
        assertEq(collat, expectedRequirement);
    }

    function testMarginRequireMultipleCall() public {
        uint256 shortAmount = 5 * UNIT;
        FullMarginDetail memory detail = FullMarginDetail({
            shortAmount: shortAmount,
            longStrike: 0,
            shortStrike: 3000 * UNIT,
            collateralAmount: 0,
            collateralId: 0,
            collateralDecimals: 6,
            tokenType: TokenType.CALL
        });

        uint256 collat = detail.getMinCollateral();
        uint256 expectedRequirement = shortAmount;

        assertEq(collat, expectedRequirement);
    }

    function testMarginRequireMultipleCallDiffDecimals() public {
        uint256 shortAmount = 5 * UNIT;
        FullMarginDetail memory detail = FullMarginDetail({
            shortAmount: shortAmount,
            longStrike: 0,
            shortStrike: 3000 * UNIT,
            collateralAmount: 0,
            collateralId: 0,
            collateralDecimals: 18,
            tokenType: TokenType.CALL
        });

        uint256 collat = detail.getMinCollateral();
        uint256 expectedRequirement = 5 * 1e18;

        assertEq(collat, expectedRequirement);
    }
}

/**
 * test full margin calculation for call spread
 */
contract FullMarginMathTestCallSpread is Test {
    using FullMarginMath for FullMarginDetail;

    function testMarginRequireCallCreditSpread() public {
        FullMarginDetail memory detail = FullMarginDetail({
            shortAmount: UNIT,
            longStrike: 4000 * UNIT,
            shortStrike: 2000 * UNIT,
            collateralAmount: 0,
            collateralId: 0,
            collateralDecimals: 6,
            tokenType: TokenType.CALL_SPREAD
        });

        uint256 collat = detail.getMinCollateral();
        uint256 expectedRequirement = UNIT / 2;
        assertEq(collat, expectedRequirement);
    }

    function testMarginRequireMultipleCallCreditSpread() public {
        uint256 shortAmount = 5 * UNIT;
        FullMarginDetail memory detail = FullMarginDetail({
            shortAmount: shortAmount,
            longStrike: 4000 * UNIT,
            shortStrike: 2000 * UNIT,
            collateralAmount: 0,
            collateralId: 0,
            collateralDecimals: 6,
            tokenType: TokenType.CALL_SPREAD
        });

        uint256 collat = detail.getMinCollateral();
        uint256 expectedRequirement = shortAmount / 2;

        assertEq(collat, expectedRequirement);
    }

    function testMarginRequireMultipleCallCreditSpreadDiffDecimals() public {
        uint256 shortAmount = 5 * UNIT;
        FullMarginDetail memory detail = FullMarginDetail({
            shortAmount: shortAmount,
            longStrike: 6000 * UNIT,
            shortStrike: 3000 * UNIT,
            collateralAmount: 0,
            collateralId: 0,
            collateralDecimals: 18,
            tokenType: TokenType.CALL_SPREAD
        });

        uint256 collat = detail.getMinCollateral();
        uint256 expectedRequirement = (5 * 1e18) / 2;

        assertEq(collat, expectedRequirement);
    }

    function testMarginRequireCallDebitSpread() public {
        FullMarginDetail memory detail = FullMarginDetail({
            shortAmount: UNIT,
            longStrike: 2000 * UNIT,
            shortStrike: 4000 * UNIT,
            collateralAmount: 0,
            collateralId: 0,
            collateralDecimals: 6,
            tokenType: TokenType.CALL_SPREAD
        });

        uint256 collat = detail.getMinCollateral();
        uint256 expectedRequirement = 0;
        assertEq(collat, expectedRequirement);
    }
}

/**
 * test full margin calculation for simple put
 */
contract FullMarginMathTestPut is Test {
    using FullMarginMath for FullMarginDetail;

    function testMarginRequirePut() public {
        FullMarginDetail memory detail = FullMarginDetail({
            shortAmount: UNIT,
            longStrike: 0,
            shortStrike: 3000 * UNIT,
            collateralAmount: 0,
            collateralId: 0,
            collateralDecimals: 6,
            tokenType: TokenType.PUT
        });

        uint256 collat = detail.getMinCollateral();
        uint256 expectedRequirement = 3000 * UNIT;
        assertEq(collat, expectedRequirement);
    }

    function testMarginRequireMultiplePut() public {
        uint256 shortAmount = 5 * UNIT;
        FullMarginDetail memory detail = FullMarginDetail({
            shortAmount: shortAmount,
            longStrike: 0,
            shortStrike: 3000 * UNIT,
            collateralAmount: 0,
            collateralId: 0,
            collateralDecimals: 6,
            tokenType: TokenType.PUT
        });

        uint256 collat = detail.getMinCollateral();
        uint256 expectedRequirement = shortAmount * 3000;

        assertEq(collat, expectedRequirement);
    }

    function testMarginRequireMultiplePutDiffDecimals() public {
        uint256 shortAmount = 5 * UNIT;
        FullMarginDetail memory detail = FullMarginDetail({
            shortAmount: shortAmount,
            longStrike: 0,
            shortStrike: 3000 * UNIT,
            collateralAmount: 0,
            collateralId: 0,
            collateralDecimals: 18,
            tokenType: TokenType.PUT
        });

        uint256 collat = detail.getMinCollateral();
        uint256 expectedRequirement = 5 * 3000 * 1e18;

        assertEq(collat, expectedRequirement);
    }
}

/**
 * test full margin calculation for put spread
 */
contract FullMarginMathTestPutpread is Test {
    using FullMarginMath for FullMarginDetail;

    function testMarginRequirePutCreditSpread() public {
        FullMarginDetail memory detail = FullMarginDetail({
            shortAmount: UNIT,
            longStrike: 2000 * UNIT,
            shortStrike: 3000 * UNIT,
            collateralAmount: 0,
            collateralId: 0,
            collateralDecimals: 6,
            tokenType: TokenType.PUT_SPREAD
        });

        uint256 collat = detail.getMinCollateral();
        uint256 expectedRequirement = 1000 * UNIT;
        assertEq(collat, expectedRequirement);
    }

    function testMarginRequireMultipleCallCreditSpread() public {
        uint256 shortAmount = 5 * UNIT;
        FullMarginDetail memory detail = FullMarginDetail({
            shortAmount: shortAmount,
            longStrike: 3000 * UNIT,
            shortStrike: 4000 * UNIT,
            collateralAmount: 0,
            collateralId: 0,
            collateralDecimals: 6,
            tokenType: TokenType.PUT_SPREAD
        });

        uint256 collat = detail.getMinCollateral();
        uint256 expectedRequirement = shortAmount * 1000;

        assertEq(collat, expectedRequirement);
    }

    function testMarginRequireMultipleCallCreditSpreadDiffDecimals() public {
        uint256 shortAmount = 5 * UNIT;
        FullMarginDetail memory detail = FullMarginDetail({
            shortAmount: shortAmount,
            longStrike: 3000 * UNIT,
            shortStrike: 4000 * UNIT,
            collateralAmount: 0,
            collateralId: 0,
            collateralDecimals: 18,
            tokenType: TokenType.PUT_SPREAD
        });

        uint256 collat = detail.getMinCollateral();
        uint256 expectedRequirement = (5 * 1e18) * 1000;

        assertEq(collat, expectedRequirement);
    }

    function testMarginRequireCallDebitSpread() public {
        FullMarginDetail memory detail = FullMarginDetail({
            shortAmount: UNIT,
            longStrike: 4000 * UNIT,
            shortStrike: 3000 * UNIT,
            collateralAmount: 0,
            collateralId: 0,
            collateralDecimals: 6,
            tokenType: TokenType.PUT_SPREAD
        });

        uint256 collat = detail.getMinCollateral();
        uint256 expectedRequirement = 0;
        assertEq(collat, expectedRequirement);
    }
}

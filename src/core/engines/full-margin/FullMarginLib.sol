// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import "../../../libraries/TokenIdUtil.sol";
import "../../../libraries/ProductIdUtil.sol";

import "../../../config/types.sol";
import "../../../config/constants.sol";
import "../../../config/errors.sol";

/**
 * @title FullMarginLib
 * @dev   This library is in charge of updating the simple account memory struct and do validations
 */
library FullMarginLib {
    using TokenIdUtil for uint256;
    using ProductIdUtil for uint32;

    /**
     * @dev return true if the account has no short positions nor collateral
     */
    function isEmpty(FullMarginAccount memory account) internal pure returns (bool) {
        return account.collateralAmount == 0 && account.shortAmount == 0;
    }

    ///@dev Increase the collateral in the account
    ///@param account FullMarginAccount memory that will be updated
    function addCollateral(
        FullMarginAccount memory account,
        uint80 amount,
        uint8 collateralId
    ) internal pure {
        if (account.collateralId == 0) {
            account.collateralId = collateralId;
        } else {
            if (account.collateralId != collateralId) revert FM_WrongCollateralId();
        }
        account.collateralAmount += amount;
    }

    ///@dev Reduce the collateral in the account
    ///@param account FullMarginAccount memory that will be updated
    function removeCollateral(
        FullMarginAccount memory account,
        uint80 amount,
        uint8 collateralId
    ) internal pure {
        if (account.collateralId != collateralId) revert FM_WrongCollateralId();
        uint80 newAmount = account.collateralAmount - amount;
        account.collateralAmount = newAmount;
        if (newAmount == 0) {
            account.collateralId = 0;
        }
    }

    ///@dev Increase the amount of short call or put (debt) of the account
    ///@param account FullMarginAccount memory that will be updated
    function mintOption(
        FullMarginAccount memory account,
        uint256 tokenId,
        uint64 amount
    ) internal pure {
        (TokenType optionType, uint32 productId, , , ) = tokenId.parseTokenId();

        // assign collateralId or check collateral id is the same
        (, uint8 underlyingId, uint8 strikeId, uint8 collateralId) = productId.parseProductId();

        // call can only collateralized by underlying
        if ((optionType == TokenType.CALL) && underlyingId != collateralId)
            revert FM_CannotMintOptionWithThisCollateral();

        // call spread can be collateralized by underlying or strike
        if (optionType == TokenType.CALL_SPREAD && collateralId != underlyingId && collateralId != strikeId)
            revert FM_CannotMintOptionWithThisCollateral();

        // put or put spread can only be collateralized by strike
        if ((optionType == TokenType.PUT_SPREAD || optionType == TokenType.PUT) && strikeId != collateralId)
            revert FM_CannotMintOptionWithThisCollateral();

        if (account.collateralId == 0) {
            account.collateralId = collateralId;
        } else {
            if (account.collateralId != collateralId) revert FM_CollateraliMisMatch();
        }

        if (account.tokenId == 0) account.tokenId = tokenId;
        else if (account.tokenId != tokenId) revert FM_InvalidToken();

        account.shortAmount += amount;
    }

    ///@dev Remove the amount of short call or put (debt) of the account
    ///@param account FullMarginAccount memory that will be updated in-place
    function burnOption(
        FullMarginAccount memory account,
        uint256 tokenId,
        uint64 amount
    ) internal pure {
        if (account.tokenId != tokenId) revert FM_InvalidToken();

        account.shortAmount -= amount;
        if (account.shortAmount == 0) account.tokenId = 0;
    }

    ///@dev merge an OptionToken into the accunt, changing existing short to spread
    ///@dev shortId and longId already have the same optionType, productId, expiry
    ///@param account FullMarginAccount memory that will be updated in-place
    ///@param shortId existing short position to be converted into spread
    ///@param longId token to be "added" into the account. This is expected to have the same time of the exisiting short type.
    ///               e.g: if the account currenly have short call, we can added another "call token" into the account
    ///               and convert the short position to a spread.
    function merge(
        FullMarginAccount memory account,
        uint256 shortId,
        uint256 longId,
        uint64 amount
    ) internal pure {
        // get token attribute for incoming token
        (, , , uint64 mergingStrike, ) = longId.parseTokenId();

        if (account.tokenId != shortId) revert FM_ShortDoesnotExist();
        if (account.shortAmount != amount) revert FM_MergeAmountMisMatch();

        // this can make the vault in either credit spread of debit spread position
        account.tokenId = TokenIdUtil.convertToSpreadId(shortId, mergingStrike);
    }

    ///@dev split an accunt's spread position into short + 1 token
    ///@param account FullMarginAccount memory that will be updated in-place
    ///@param spreadId id of spread to be parsed
    function split(
        FullMarginAccount memory account,
        uint256 spreadId,
        uint64 amount
    ) internal pure {
        // passed in spreadId should match the one in account memory (shortCallId or shortPutId)
        if (spreadId != account.tokenId) revert FM_InvalidToken();
        if (amount != account.shortAmount) revert FM_SplitAmountMisMatch();

        // convert to call: remove the "short strike" and update "tokenType" field
        account.tokenId = TokenIdUtil.convertToVanillaId(spreadId);
    }

    function settleAtExpiry(FullMarginAccount memory account, uint80 _payout) internal pure {
        // clear all debt
        account.tokenId = 0;
        account.shortAmount = 0;

        // this line should not underflow because collateral should always be enough
        // but keeping the underflow check to make sure
        account.collateralAmount = account.collateralAmount - _payout;
    }
}

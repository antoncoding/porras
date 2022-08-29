// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "../config/enums.sol";
import "../config/errors.sol";

library TokenIdUtil {
    /**
     * @notice calculate ERC1155 token id for given option parameters
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   tokenId = | tokenType (32 bits) | productId (32 bits) | expiry (64 bits) | longStrike (64 bits) | shortStrike (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @param tokenType TokenType enum
     * @param productId if of the product
     * @param expiry timestamp of option expiry
     * @param longStrike strike price of the long option, with 6 decimals
     * @param shortStrike strike price of the short (upper bond for call and lower bond for put) if this is a spread. 6 decimals
     * @return tokenId token id
     */
    function formatTokenId(
        TokenType tokenType,
        uint32 productId,
        uint64 expiry,
        uint64 longStrike,
        uint64 shortStrike
    ) internal pure returns (uint256 tokenId) {
        unchecked {
            tokenId =
                (uint256(tokenType) << 224) +
                (uint256(productId) << 192) +
                (uint256(expiry) << 128) +
                (uint256(longStrike) << 64) +
                uint256(shortStrike);
        }
    }

    /**
     * @notice derive option expiry and strike price from ERC1155 token id
     *                  * ------------------- | ------------------- | ----------------- | -------------------- | --------------------- *
     * @dev   tokenId = | tokenType (32 bits) | productId (32 bits) | expiry (64 bits)  | longStrike (64 bits) | shortStrike (64 bits) |
     *                  * ------------------- | ------------------- | ----------------- | -------------------- | --------------------- *
     * @param tokenId token id
     * @return tokenType TokenType enum
     * @return productId if of the product
     * @return expiry timestamp of option expiry
     * @return longStrike strike price of the long option, with 6 decimals
     * @return shortStrike strike price of the short (upper bond for call and lower bond for put) if this is a spread. 6 decimals
     */
    function parseTokenId(uint256 tokenId)
        internal
        pure
        returns (
            TokenType tokenType,
            uint32 productId,
            uint64 expiry,
            uint64 longStrike,
            uint64 shortStrike
        )
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tokenType := shr(224, tokenId)
            productId := shr(192, tokenId)
            expiry := shr(128, tokenId)
            longStrike := shr(64, tokenId)
            shortStrike := tokenId
        }
    }

    /**
     * @notice derive option type from ERC1155 token id
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   tokenId = | tokenType (32 bits) | productId (32 bits) | expiry (64 bits) | longStrike (64 bits) | shortStrike (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @param tokenId token id
     * @return tokenType TokenType enum
     */
    function parseTokenType(uint256 tokenId) internal pure returns (TokenType tokenType) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tokenType := shr(224, tokenId)
        }
    }

    /**
     * @notice convert an spread tokenId back to put or call.
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   oldId =   | spread type (32 b)  | productId (32 bits) | expiry (64 bits) | longStrike (64 bits) | shortStrike (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   newId =   | call or put type    | productId (32 bits) | expiry (64 bits) | longStrike (64 bits) | 0           (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   this function will: override tokenType, remove shortStrike.
     * @param _tokenId token id to change
     */
    function convertToVanillaId(uint256 _tokenId) internal pure returns (uint256 newId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newId := shr(64, _tokenId) // step 1: >> 64 to wipe out shortStrike
            newId := shl(64, newId) // step 2: << 64 go back

            newId := sub(newId, shl(224, 1)) // step 3: new tokenType = spread type - 1
        }
    }

    /**
     * @notice convert an spread tokenId back to put or call.
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   oldId =   | call or put type    | productId (32 bits) | expiry (64 bits) | longStrike (64 bits) | 0           (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     * @dev   newId =   | spread type         | productId (32 bits) | expiry (64 bits) | longStrike (64 bits) | shortStrike (64 bits) |
     *                  * ------------------- | ------------------- | ---------------- | -------------------- | --------------------- *
     *
     * this function convert put or call type to spread type, add shortStrike.
     * @param _tokenId token id to change
     * @param _shortStrike strike to add
     */
    function convertToSpreadId(uint256 _tokenId, uint256 _shortStrike) internal pure returns (uint256 newId) {
        // solhint-disable-next-line no-inline-assembly
        unchecked {
            newId = _tokenId + _shortStrike;
            return newId + (1 << 224);
        }
    }
}

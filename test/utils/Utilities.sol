// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {TokenType} from "../../src/config/enums.sol";
import {TokenIdUtil} from "../../src/libraries/TokenIdUtil.sol";

//common utilities for forge tests
abstract contract Utilities {
    function getTokenId(TokenType tokenType, uint40 productId, uint256 expiry, uint256 longStrike, uint256 shortStrike)
        internal
        pure
        returns (uint256 tokenId)
    {
        tokenId = TokenIdUtil.getTokenId(tokenType, productId, uint64(expiry), uint64(longStrike), uint64(shortStrike));
    }

    function parseTokenId(uint256 tokenId)
        internal
        pure
        returns (TokenType tokenType, uint40 productId, uint64 expiry, uint64 longStrike, uint64 shortStrike)
    {
        return TokenIdUtil.parseTokenId(tokenId);
    }

    // solhint-disable max-line-length
    function predictAddress(address _origin, uint256 _nonce) public pure returns (address) {
        if (_nonce == 0x00) {
            return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, bytes1(0x80))))));
        }
        if (_nonce <= 0x7f) {
            return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, uint8(_nonce))))));
        }
        if (_nonce <= 0xff) {
            return address(
                uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd7), bytes1(0x94), _origin, bytes1(0x81), uint8(_nonce)))))
            );
        }
        if (_nonce <= 0xffff) {
            return address(
                uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd8), bytes1(0x94), _origin, bytes1(0x82), uint16(_nonce)))))
            );
        }
        if (_nonce <= 0xffffff) {
            return address(
                uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd9), bytes1(0x94), _origin, bytes1(0x83), uint24(_nonce)))))
            );
        }
        return address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xda), bytes1(0x94), _origin, bytes1(0x84), uint32(_nonce)))))
        );
    }
}

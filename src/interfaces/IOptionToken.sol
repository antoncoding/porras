// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

interface IOptionToken {
    /**
     * @dev mint option token to an address. Can only be called by marginAccount
     * @param _recipient    where to mint token to
     * @param _tokenId      tokenId to mint
     * @param _amount       amount to mint
     **/
    function mint(
        address _recipient,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    /**
     * @dev burn option token from an address. Can only be called by marginAccount
     * @param _from         account to burn from
     * @param _tokenId      tokenId to burn
     * @param _amount       amount to burn
     **/
    function burn(
        address _from,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    function burnGrappaOnly(
        address _from,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    /**
     * @dev burn batch of option token from an address. Can only be called by marginAccount
     * @param _from         account to burn from
     * @param _ids          tokenId to burn
     * @param _amounts      amount to burn
     **/
    function batchBurn(
        address _from,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external;
}

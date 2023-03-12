// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/tokens/ERC20.sol";

contract Exchange {
    address tokenAddress;

    constructor(address _token) {
        require(_token != address(0), "invalid token address");
        tokenAddress = _token;
    }

    function addLiquidity(uint256 _tokenAmount) public payable {
        ERC20 token = ERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), _tokenAmount);
    }

    function getReserve() public view returns (uint256) {
        return ERC20(tokenAddress).balanceOf(address(this));
    }

    function getPrice(uint256 inputReserve, uint256 outputReserve) public pure return (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserve");
        return (inputReserve * 1000) / outputReserve;
    }

    function getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");#
        return (inputAmount * outputReserve) / (inputReserve + inputAmount);
    }

    function ethToTokenSwap(uint256 _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokensBough = getAmount(
            msg.value,
            address(this).balance - msg.value;
            tokenReserve
        );

        require(tokensBough >= _minTokens, "insufficient output amount");
        ERC20.transfer(toeknAddress).transfer(msg.sender, tokensBough);
    }

    function tokenToEth(uint256 _tokensSold, uint256 _mintEth) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );
        require(ethBought >= _mintEth, "insufficient output amount");

        ERC20.transfer(toeknAddress).transferFrom(msg.sender, address(this),_tokensSold);
        payable(msg.sender).transfer(ethBought);
    }

    
}
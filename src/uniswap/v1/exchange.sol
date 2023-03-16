// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/tokens/ERC20.sol";
import "./Factory.sol";

contract Exchange is ERC20{
    address tokenAddress;
    address factoryAddress;

    constructor(address _token) ERC20("MyUniswap-V1", "MUniv1", 0){
        require(_token != address(0), "invalid token address");
        tokenAddress = _token;
        factoryAddress = msg.sender;
    }

    function addLiquidity(uint256 _tokenAmount) public payable returns(uint256) {
        if (getReserve() == 0) {
            ERC20 token = ERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), _tokenAmount);

            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);
            return liquidity;
        } else {
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserve();
            uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve;
            require(_tokenAmount >= tokenAmount, "insufficient token amount");
        
            ERC20 token = ERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), tokenAmount);

            uint256 liquidity = (totalSupply * msg.value) / ethReserve;
            _mint(msg.sender,liquidity);
            return liquidity;
        }
    }

    function removeLiquidity(uint256 _amount) public returns (uint256, uint256) {
        require(_amount > 0, "invalid amount");

        uint256 ethAmount = (address(this).balance * _amount) / totalSupply;
        uint256 tokenAmount =(getReserve() * _amount) / totalSupply;

        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        ERC20(tokenAddress).transfer(msg.sender, tokenAmount);

        return(ethAmount, tokenAmount);
    }

    function getReserve() public view returns (uint256) {
        return ERC20(tokenAddress).balanceOf(address(this));
    }

    function getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");

        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee + outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;
    }

    function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
        require(_ethSold > 0, "ethSold is too small");
      
        uint256 tokenReserve = getReserve();
      
        return getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
        require(_tokenSold > 0, "tokenSold is too small");
        
        uint256 tokenReserve = getReserve();
        
        return getAmount(_tokenSold, tokenReserve, address(this).balance);
    }

    function ethToToken(uint256 _minTokens, address recipient) private {
        uint256 tokenReserve = getReserve();
        uint256 tokensBough = getAmount(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokensBough >= _minTokens, "insufficient output amount");
        ERC20(tokenAddress).transfer(recipient, tokensBough);
    }

    function ethToTokenTransfer(uint256 _minTokens, address _recipient) public payable {
        ethToToken(_minTokens, _recipient);
    }

    function ethToTokenSwap(uint256 _minTokens) public payable {
        ethToToken(_minTokens, msg.sender);
    }

    function tokenToEth(uint256 _tokensSold, uint256 _mintEth) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );
        require(ethBought >= _mintEth, "insufficient output amount");

        ERC20(tokenAddress).transferFrom(msg.sender, address(this),_tokensSold);
        payable(msg.sender).transfer(ethBought);
    }

    function tokenTotokenSwap(
        uint256 _tokensSold,
        uint256 _mintTokensBought,
        address _tokenAddress
    ) public {
        address exchangeAddress = Factory(factoryAddress).getExchange(_tokenAddress);
        require(
            exchangeAddress != address(this) && exchangeAddress != address(0),
            "invalid exchange address"
        );

        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );

        ERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensSold
        );
        
        Exchange(exchangeAddress).ethToTokenTransfer{value: ethBought}(
            _mintTokensBought, 
            msg.sender
        );
        
    }
    
}
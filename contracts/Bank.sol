//SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./interfaces/IBank.sol";
import "./interfaces/IPriceOracle.sol";
import "./SafeMath.sol";

contract Bank is IBank, SafeMath {
string public name;
    address public oracle;
    address public hack_coin;
    string public unsupportedToken = "token not supported";

    mapping (address => Account) public account;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor (address _priceOracle, address _hack_coin) {
        oracle = _priceOracle;
        hack_coin = _hack_coin;
    }


    function deposit(address token, uint256 amount)payable external override returns (bool) {
        require(amount > 0);
        
        if(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            account[msg.sender].deposit += amount;
        } else if (token == hack_coin) {
            account[msg.sender].deposit += amount;
        } else{
            revert(unsupportedToken);
        }
        return true;
    }

    function withdraw(address token, uint256 amount) external override returns (uint256) {}

    function borrow(address token, uint256 amount) external override returns (uint256) {}

    function repay(address token, uint256 amount) payable external override returns (uint256) {

    }

    function liquidate(address token, address account)
        payable
        external
        override
        returns (bool) {}

    function getCollateralRatio(address token, address account)
        view
        public
        override
        returns (uint256) {}

    function getBalance(address token)
        view
        public
        override
        returns (uint256) {
            return account[msg.sender].deposit;
        }
}

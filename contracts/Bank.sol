//SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./interfaces/IBank.sol";
import "./interfaces/IPriceOracle.sol";
import "./SafeMath.sol";

contract Bank is IBank, SafeMath {
    IPriceOracle public oracle;
    address public hack_coin;
    string public unsupportedToken = "token not supported";

    mapping (address => Account) public account;
    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor (address _priceOracle, address _hack_coin) {
        oracle = IPriceOracle(_priceOracle);
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
        account[msg.sender].lastInterestBlock = block.number;
        emit Deposit(msg.sender, token, amount);
        return true;
    }

    function withdraw(address token, uint256 amount) external override returns (uint256) {
        if (token != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE && token != hack_coin) {
            revert("token not supported");
        }
        if (token != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            //do the convert to ether stuff here
        }
        if (account[msg.sender].deposit == 0) revert("no balance");
        if (amount == 0) amount = account[msg.sender].deposit;
        if (amount > account[msg.sender].deposit) revert("amount exceeds balance");
        if (amount < 0) revert("negativ not supported");
        account[msg.sender].deposit -= amount;
        msg.sender.transfer(safeMul(amount, amount + calculateInterest(account[msg.sender])));
        return uint256(amount);
    }

    function calculateInterest(Account memory account) internal view returns(uint256) {
        uint256 newInterest = account.deposit * block.number - account.lastInterestBlock;
        account.interest += newInterest;
        account.lastInterestBlock = block.number;
        return newInterest;
    }

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

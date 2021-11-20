//SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./interfaces/IBank.sol";
import "./interfaces/IPriceOracle.sol";
import "./SafeMath.sol";

contract Bank is IBank, SafeMath {
string public name;
    address public oracle;
    address public hack_coin;

    mapping (address => Account) public account;
    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor (address _priceOracle, address _hack_coin) {
        oracle = _priceOracle;
        hack_coin = _hack_coin;
    }


    function deposit(address token, uint256 amount)payable external override returns (bool) {
        require(amount > 0);
        account[msg.sender].deposit += amount;
        
        // require(msg.value >= safeMul(oracle.getVirtualPrice(token), amount)); //afaik i understand it, it returns it scaled
        // uint256 scaledAmount = safeMul(oracle.getVirtualPrice(token), amount);
        // return require(this.transfer(msg.sender, scaledAmount));
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
        emit Withdraw(msg.sender, token, amount);
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
            uint256 ratio = 1;
            if (token != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE && token != hack_coin)
            revert("token not supported");
            if (token == hack_coin) {
                //get the correct ratio here via oracle
            }
            return safeMul(account[msg.sender].deposit, ratio);
        }
}

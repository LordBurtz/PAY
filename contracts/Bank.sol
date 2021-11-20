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
        account[msg.sender].lastInterestBlock = block.number;
        
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
        if (amount > account[msg.sender].deposit) revert("amount exceeds balance");
        if (amount < 0) revert("negativ not supported");

        uint256 interest = calculateInterest(account[msg.sender].deposit, account[msg.sender].lastInterestBlock, block.number);
        account[msg.sender].interest += interest;
        account[msg.sender].lastInterestBlock = block.number;
        
        uint256 absolut;
        if (amount == 0) {
            absolut = account[msg.sender].deposit + account[msg.sender].interest;
            account[msg.sender].deposit = 0;
            account[msg.sender].interest = 0;
        } else {
            absolut = amount;
            account[msg.sender].deposit -= amount;
            account[msg.sender].interest -= interest;
            absolut += interest;
        }

        msg.sender.transfer(absolut);
        emit Withdraw(msg.sender, token, absolut);
        return absolut;

        /*
        account[msg.sender].deposit -= amount;
        msg.sender.transfer(safeMul(amount, amount + calculateInterest(account[msg.sender])));
        emit Withdraw(msg.sender, token, amount);
        return uint256(amount);
        */
    }

    function calculateInterest(uint256 deposit, uint256 blockInterest, uint256 currentBlock) internal view returns(uint256) {
        return safeDiv(safeMul(safeMul((currentBlock - blockInterest), 3), deposit), 10000);
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
                    uint256 interest = calculateInterest(account[msg.sender].deposit, account[msg.sender].lastInterestBlock, block.number);
        account[msg.sender].interest += interest;
        account[msg.sender].lastInterestBlock = block.number;
            return safeMul(account[msg.sender].deposit, ratio);
        }
}

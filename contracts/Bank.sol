//SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./interfaces/IBank.sol";
import "./interfaces/IPriceOracle.sol";
import "./SafeMath.sol";

contract Bank is IBank, SafeMath {
    IPriceOracle public oracle;
    address public hack_coin;
    string public unsupportedToken = "token not supported";
    
    struct Loan {
        uint256 amount;
        uint256 interest;
        uint256 lastInterestBlock;
        uint256 collateral;
    }
    
    mapping (address => Loan) public loans;

    mapping (address => Account) public account;

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

    function withdraw(address token, uint256 amount) external override returns (uint256) {}

    function borrow(address token, uint256 amount) external override returns (uint256) {}

    function repay(address token, uint256 amount) payable external override returns (uint256) {
        if (token != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            revert("token not supported");
        }
        
        if (loans[msg.sender].amount == 0) {
            revert("nothing to repay");
        }
        
        if (msg.value < amount) {
            revert("msg.value < amount to repay");
        }
        
        uint256 interest = calculateInterestLoan(loans[msg.sender].amount, loans[msg.sender].lastInterestBlock, block.number);
        loans[msg.sender].interest += interest;
        loans[msg.sender].lastInterestBlock = block.number;
        if (loans[msg.sender].amount + loans[msg.sender].interest <= amount) {
            loans[msg.sender].amount = 0;
            loans[msg.sender].interest = 0;
            account[msg.sender].deposit += loans[msg.sender].collateral;
        } else {
            uint256 left = amount;
            if (amount > loans[msg.sender].interest) {
                left -= loans[msg.sender].interest;
                loans[msg.sender].interest = 0;
                loans[msg.sender].amount -= left;
                return loans[msg.sender].amount;
            } else {
                loans[msg.sender].interest -= amount;
                return loans[msg.sender].amount;
            }
        }
        
        return loans[msg.sender].amount;
    }
    
    function calculateInterestLoan(uint256 amount, uint256 blockInterest, uint256 currentBlock) internal pure returns(uint256) {
        return safeDiv(safeMul(safeMul((currentBlock - blockInterest), 5), amount), 10000);
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

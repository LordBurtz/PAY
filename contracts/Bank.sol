//SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./interfaces/IBank.sol";
import "./interfaces/IPriceOracle.sol";
import "./SafeMath.sol";
import "./interfaces/HackCoin.sol";

contract Bank is IBank, SafeMath {
    IPriceOracle public oracle;
    IERC20 public HACK;
    address public hack_coin;
    string public unsupportedToken = "token not supported";

    mapping (address => Account) public account;
    mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor (address _priceOracle, address _hack_coin) {
        oracle = IPriceOracle(_priceOracle);
        hack_coin = _hack_coin;
        HACK = IERC20(_hack_coin);
    }


    function deposit(address token, uint256 amount)payable external override returns (bool) {
        require(amount > 0);
        
        uint256 ratio = 1;
        
        if(token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            if (msg.value != safeMul(ratio, amount)) revert ("wrong value");

            uint256 interest = calculateInterest(account[msg.sender].deposit, account[msg.sender].lastInterestBlock, block.number);
            account[msg.sender].interest += interest;
            account[msg.sender].lastInterestBlock = block.number;

            account[msg.sender].deposit += amount;
        } else if (token == hack_coin) {
            //ratio = oracle.getVirtualPrice(token) * amount * 1e18;
            //if (msg.value != safeMul(ratio, amount)) revert ("wrong value");

            uint256 interest = calculateInterest(account[msg.sender].deposit, account[msg.sender].lastInterestBlock, block.number);
            account[msg.sender].interest += interest;
            account[msg.sender].lastInterestBlock = block.number;

            account[msg.sender].deposit += amount;
            require(HACK.transferFrom(msg.sender, address(this), amount));
        } else{
            revert(unsupportedToken);
        }
        account[msg.sender].lastInterestBlock = block.number;
        emit Deposit(msg.sender, token, amount);
        return true;

        

        account[msg.sender].deposit += amount;
        account[msg.sender].lastInterestBlock = block.number;
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

    function calculateInterest(uint256 deposit, uint256 blockInterest, uint256 currentBlock) internal pure returns(uint256) {
        return safeDiv(safeMul(safeMul((currentBlock - blockInterest), 3), deposit), 10000);
    }

/**
     * The purpose of this function is to allow users to borrow funds by using their 
     * deposited funds as collateral. The minimum ratio of deposited funds over 
     * borrowed funds must not be less than 150%.
     * @param token - the address of the token to borrow. This address must be
     *                set to 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, otherwise  
     *                the transaction must revert.
     * @param amount - the amount to borrow. If this amount is set to zero (0),
     *                 then the amount borrowed should be the maximum allowed, 
     *                 while respecting the collateral ratio of 150%.
     * @return - the current collateral ratio.
     */
    function borrow(address token, uint256 amount) external override returns (uint256) {
        if (token != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            revert("token not supported");
        }
        
        uint256 collateral = safeDiv(safeMul(amount, 150), 100);
        
        if (collateral > account[msg.sender].deposit) {
            revert("no collateral deposited");
        }
        
        loans[msg.sender].amount = amount;
        loans[msg.sender].lastInterestBlock = block.number;
        loans[msg.sender].interest = 0;
        loans[msg.sender].collateral = collateral;
        account[msg.sender].deposit -= loans[msg.sender].collateral;
        
        return getCollateralRatio(token, msg.sender);
    }

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
            uint256 ratio = 1;
            if (token != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE && token != hack_coin)
            revert("token not supported");
            if (token == hack_coin) {
                
            }
            return safeAdd(safeMul(account[msg.sender].deposit, ratio), calculateInterest(account[msg.sender].deposit, account[msg.sender].lastInterestBlock, block.number));
        }
}

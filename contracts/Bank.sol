//SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./interfaces/IBank.sol";
import "./interfaces/IPriceOracle.sol";
import "./SafeMath.sol";

contract Bank is IBank {

    string public name;
    string public symbol;
    uint256 public decimals;
	address public owner;
	Loan public loan;
	Loan[] public loans;
    PriceOracleTest public oracle;

mapping (address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address _priceOracle, address _hakToken) {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens                      // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
		owner = msg.sender;
    }
    function deposit(address token, uint256 amount)
        payable
        external
        override
        returns (bool) {
            require(msg.value == safeMul(oracle.getVirtualPrice(token), amount)); //afaik i understand it, it returns it scaled
        uint256 scaledAmount = safeMul(oracle.getVirtualPrice(token), amount);
        require(this.transfer(msg.sender, scaledAmount));
        }

    function withdraw(address token, uint256 amount)
        external
        override
        returns (uint256) {}

    function borrow(address token, uint256 amount)
        external
        override
        returns (uint256) {}

    function repay(address token, uint256 amount)
        payable
        external
        override
        returns (uint256) {
            require(msg.value == safeMul(oracle.getVirtualPrice(token), amount)); //afaik i understand it, it returns it scaled
        uint256 scaledAmount = safeMul(oracle.getVirtualPrice(token), amount);
        require(this.transfer(msg.sender, scaledAmount));
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
        returns (uint256) {}
}

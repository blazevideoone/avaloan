pragma solidity ^0.6.1;

// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/ownership/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol";
import "github.com/OpenZeppelin/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "github.com/OpenZeppelin/zeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "github.com/OpenZeppelin/zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

import "./IAvaloan.sol";

contract AvaloanERC20 is Ownable, IAvaloanERC20 {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public override interestRateMulBy100000;
    
    constructor(uint256 newInterestRateMulBy100000) public {
        interestRateMulBy100000 = newInterestRateMulBy100000;
    }

    function setInterestRate(uint256 newInterestRateMulBy100000) onlyOwner external {
        interestRateMulBy100000 = newInterestRateMulBy100000;
    }

    function flashLoan(IERC20 token, address lender, uint256 amount, ILoanRunner runner) external override {
        uint256 initialBalance = token.balanceOf(lender);
        token.safeTransferFrom(lender, address(runner), amount);
        runner.loanRunner(token, lender, amount);
        uint256 interest = amount.mul(interestRateMulBy100000).div(100000);
        uint256 finalBalance = token.balanceOf(lender);
        require(finalBalance >= initialBalance.add(interest), "Failed to return loan and interest");
    }
}

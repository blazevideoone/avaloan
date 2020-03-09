pragma solidity ^0.6.1;

// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol";
import "github.com/OpenZeppelin/zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "github.com/OpenZeppelin/zeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "github.com/OpenZeppelin/zeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "github.com/OpenZeppelin/zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

import "../AvaloanERC20.sol";

contract AvaloanTestToken is ERC20, ERC20Detailed {
    constructor() ERC20Detailed("AvaloanTestToken", "ATT", 18) public {
        _mint(msg.sender, 21000000000000000000000000);
    }
}

contract AvaloanERC20Test {

    function testNoInterst() external {
        IERC20 token = new AvaloanTestToken();
        AvaloanERC20 avaloan = new AvaloanERC20(0);
        AvaloanERC20TestRunnerWithPayback runner = new AvaloanERC20TestRunnerWithPayback(100);
        token.approve(address(avaloan), 50000);
        avaloan.flashLoan(token, address(this), 100, runner);
    }

    function testNoInterstFailedNoPayback() external {
        IERC20 token = new AvaloanTestToken();
        AvaloanERC20 avaloan = new AvaloanERC20(0);
        AvaloanERC20TestRunnerWithPayback runner = new AvaloanERC20TestRunnerWithPayback(0);
        token.approve(address(avaloan), 50000);
        avaloan.flashLoan(token, address(this), 100, runner);
    }

    function testNoInterstFailedLessPayback() external {
        IERC20 token = new AvaloanTestToken();
        AvaloanERC20 avaloan = new AvaloanERC20(0);
        AvaloanERC20TestRunnerWithPayback runner = new AvaloanERC20TestRunnerWithPayback(99);
        token.approve(address(avaloan), 50000);
        avaloan.flashLoan(token, address(this), 100, runner);
    }

    function testWithInterest() external {
        IERC20 token = new AvaloanTestToken();
        // 10% interest rate
        AvaloanERC20 avaloan = new AvaloanERC20(10000);
        // borrow 10000, pay back with 11000, at interest rate of 10%
        AvaloanERC20TestRunnerWithPayback runner = new AvaloanERC20TestRunnerWithPayback(11000);
        // direct transfer interest of 1000 to runner
        token.transfer(address(runner), 1000);
        token.approve(address(avaloan), 50000);
        avaloan.flashLoan(token, address(this), 10000, runner);
    }

    function testWithInterestFailedNoInterestPayback() external {
        IERC20 token = new AvaloanTestToken();
        AvaloanERC20 avaloan = new AvaloanERC20(10000);
        // No interest payback
        AvaloanERC20TestRunnerWithPayback runner = new AvaloanERC20TestRunnerWithPayback(10000);
        token.approve(address(avaloan), 50000);
        avaloan.flashLoan(token, address(this), 10000, runner);
    }

}

contract AvaloanERC20TestRunnerWithPayback is ILoanRunner {

    event DoSomething(uint256 totalBalance);

    using SafeMath for uint256;

    uint256 public payback;

    constructor(uint256 newPayback) public {
        payback = newPayback;
    }

    function loanRunner(IERC20 token, address lender, uint256 /* amount */) external override {
        emit DoSomething(token.balanceOf(address(this)));
        // Pay back
        token.transfer(lender, payback);
    }
}

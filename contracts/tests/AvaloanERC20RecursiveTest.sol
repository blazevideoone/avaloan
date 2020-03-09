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

contract AvaloanERC20RecursiveTest {

    function testInOneContract() external {
        IERC20 token = new AvaloanTestToken();
        // Interest rate 10%
        AvaloanERC20 avaloan = new AvaloanERC20(10000);

        // Token and account setup
        token.approve(address(avaloan), 50000);

        AvaloanERC20TestAccount account1 = new AvaloanERC20TestAccount();
        token.transfer(address(account1), 10000);
        account1.approve(token, address(avaloan), 10000);

        AvaloanERC20TestAccount account2 = new AvaloanERC20TestAccount();
        token.transfer(address(account2), 500);
        account2.approve(token, address(avaloan), 500);

        // Lender map setup
        AvaloanERC20TestLenderMap lenderMap = new AvaloanERC20TestLenderMap();
        lenderMap.addLender(address(this), 50000, 55000, avaloan, address(account1));
        lenderMap.addLender(address(account1), 10000, 11000, avaloan, address(account2));
        lenderMap.addLender(address(account2), 500, 550, IAvaloanERC20(0x00), address(0x00));

        AvaloanERC20TestRunnerRecursive runner = new AvaloanERC20TestRunnerRecursive(lenderMap);
        // Send token for interests 5000 + 1000 + 50 to runner
        token.transfer(address(runner), 6050);

        avaloan.flashLoan(token, address(this), 50000, runner);
    }

    function testInMultipleContracts() external {
        IERC20 token = new AvaloanTestToken();
        // Interest rate 10%
        AvaloanERC20 avaloan = new AvaloanERC20(10000);
        // No interest
        AvaloanERC20 avaloan1 = new AvaloanERC20(0);
        // Interest rate 50%
        AvaloanERC20 avaloan2 = new AvaloanERC20(50000);

        // Token and account setup
        token.approve(address(avaloan), 50000);

        AvaloanERC20TestAccount account1 = new AvaloanERC20TestAccount();
        token.transfer(address(account1), 10000);
        account1.approve(token, address(avaloan1), 10000);

        AvaloanERC20TestAccount account2 = new AvaloanERC20TestAccount();
        token.transfer(address(account2), 500);
        account2.approve(token, address(avaloan2), 500);

        // Lender map setup
        AvaloanERC20TestLenderMap lenderMap = new AvaloanERC20TestLenderMap();
        // Interest rate 10%
        lenderMap.addLender(address(this), 50000, 55000, avaloan1, address(account1));
        // No interest
        lenderMap.addLender(address(account1), 10000, 10000, avaloan2, address(account2));
        // Interest rate 50%
        lenderMap.addLender(address(account2), 500, 750, IAvaloanERC20(0x00), address(0x00));

        AvaloanERC20TestRunnerRecursive runner = new AvaloanERC20TestRunnerRecursive(lenderMap);
        // Send token for interests 5000 + 0 + 250 to runner
        token.transfer(address(runner), 5250);

        avaloan.flashLoan(token, address(this), 50000, runner);
    }
}

contract AvaloanERC20TestLenderMap {

    struct LenderInfo {
        uint256 amount;
        uint256 payback;
        IAvaloanERC20 nextAvaloan;
        address nextLender;
    }

    mapping (address => LenderInfo) public lenders;

    function addLender(address lender, uint256 amount, uint256 payback, IAvaloanERC20 nextAvaloan, address nextLender) external {
        lenders[lender] = LenderInfo(amount, payback, nextAvaloan, nextLender);
    }
}

contract AvaloanERC20TestAccount {

    using SafeERC20 for IERC20;

    function approve(IERC20 token, address spender, uint256 amount) external {
        token.safeApprove(spender, amount);
    }
}

contract AvaloanERC20TestRunnerRecursive is ILoanRunner {

    event DoSomething(uint256 totalBalance);

    using SafeMath for uint256;

    AvaloanERC20TestLenderMap public lenderMap;

    constructor(AvaloanERC20TestLenderMap newLenderMap) public {
        lenderMap = newLenderMap;
    }

    function loanRunner(IERC20 token, address lender, uint256 /* amount */) external override {
        (uint256 amount, uint256 payback, IAvaloanERC20 nextAvaloan, address nextLender) = lenderMap.lenders(lender);
        if (amount == 0) {
            // entry not found
            return;
        }
        if (nextLender == address(0x0)) {
            // No next lender, do something
            emit DoSomething(token.balanceOf(address(this)));
        } else {
            // Has next lender, recursively loan
            (uint256 nextAmount,,,) = lenderMap.lenders(nextLender);
            nextAvaloan.flashLoan(token, nextLender, nextAmount, this);
        }
        // Pay back
        token.transfer(lender, payback);
    }
}

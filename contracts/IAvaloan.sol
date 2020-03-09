pragma solidity ^0.6.1;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "github.com/OpenZeppelin/zeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface ILoanRunner {
    function loanRunner(IERC20 token, address lender, uint256 amount) external;
}

interface IAvaloanERC20 {
    function interestRateMulBy100000() external view returns (uint256);
    function flashLoan(IERC20 token, address lender, uint256 amount, ILoanRunner runner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import { Test, console } from "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/Vm.sol";
import {StdInvariant} from "lib/forge-std/src/StdInvariant.sol";
import { StatefulFuzzHandler } from "src/StatefulFuzzHandler.sol";
import {YieldERC20} from "test/mocks/YieldERC20.sol";
import {MockUSDC} from "test/mocks/MockUSDC.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";


/// @dev without using handler, our statefull test will fail
/// @dev Fuzz test will assumes random user, token address which will definetly fails
/// @dev So to control the randomness, we will use handler to specify our fuzz test to test within this bounded space
contract InvariantTestFail is StdInvariant, Test {
    StatefulFuzzHandler statefulFuzzHandler;
    YieldERC20 yeildERC20;
    MockUSDC mockUSDC;
    IERC20[] public supportedTokens;
    uint256 public startingAmount;

    address user = makeAddr("user");

    function setUp() public {
        vm.startPrank(user);
        // Give our user 1M tokens each
        yeildERC20 = new YieldERC20();
        startingAmount = yeildERC20.INITIAL_SUPPLY();
        mockUSDC = new MockUSDC();
        mockUSDC.mint(user, startingAmount);

        supportedTokens.push(mockUSDC);
        supportedTokens.push(yeildERC20);
        statefulFuzzHandler = new StatefulFuzzHandler(supportedTokens);
        vm.stopPrank();

        targetContract(address(statefulFuzzHandler));
    }


    function testInvariantBreakHard(uint256 randomAmount) public {
        vm.assume(randomAmount < startingAmount);
        vm.startPrank(user);
        // Deposit some yeildERC20
        yeildERC20.approve(address(statefulFuzzHandler), randomAmount);
        statefulFuzzHandler.depositToken(yeildERC20, randomAmount);
        // Withdraw some yeildERC20
        statefulFuzzHandler.withdrawToken(yeildERC20);
        // Deposit some mockUSDC
        mockUSDC.approve(address(statefulFuzzHandler), randomAmount);
        statefulFuzzHandler.depositToken(mockUSDC, randomAmount);
        // Withdraw some mockUSDC
        statefulFuzzHandler.withdrawToken(mockUSDC);
        vm.stopPrank();

        assert(mockUSDC.balanceOf(address(statefulFuzzHandler)) == 0);
        assert(yeildERC20.balanceOf(address(statefulFuzzHandler)) == 0);
        assert(mockUSDC.balanceOf(user) == startingAmount);
        assert(yeildERC20.balanceOf(user) == startingAmount);
    }

    // Our fuzz test try to provide random token addresses to function to try out with random user
    // To bound params inour test, we will use handler
    function statefulFuzz_testInvariantBreakFail() public {
        vm.startPrank(user);
        statefulFuzzHandler.withdrawToken(mockUSDC);
        statefulFuzzHandler.withdrawToken(yeildERC20); 
        vm.stopPrank();

        assert(mockUSDC.balanceOf(address(statefulFuzzHandler)) == 0);
        assert(yeildERC20.balanceOf(address(statefulFuzzHandler)) == 0);
        assert(mockUSDC.balanceOf(user) == startingAmount);
        assert(yeildERC20.balanceOf(user) == startingAmount);
    }
}
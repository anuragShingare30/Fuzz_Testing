// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console } from "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/Vm.sol";
import {StdInvariant} from "lib/forge-std/src/StdInvariant.sol";
import { StatefulFuzzHandler } from "src/StatefulFuzzHandler.sol";
import {YieldERC20} from "test/mocks/YieldERC20.sol";
import {MockUSDC} from "test/mocks/MockUSDC.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantBreakHardTest is StdInvariant, Test {
    StatefulFuzzHandler statefulFuzzHandler;
    YieldERC20 yeildERC20;
    MockUSDC mockUSDC;
    IERC20[] public supportedTokens;
    uint256 public startingAmount;

    address user = makeAddr("user");

    Handler handler;

    function setUp() public {
        vm.startPrank(user);
        // Give our user 1Mock tokens each
        yeildERC20 = new YieldERC20();
        startingAmount = yeildERC20.INITIAL_SUPPLY();
        mockUSDC = new MockUSDC();
        mockUSDC.mint(user, startingAmount);

        supportedTokens.push(mockUSDC);
        supportedTokens.push(yeildERC20);
        statefulFuzzHandler = new StatefulFuzzHandler(supportedTokens);
        vm.stopPrank();

        handler = new Handler(statefulFuzzHandler, yeildERC20, mockUSDC);

        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = handler.depositYieldERC20.selector;
        selectors[1] = handler.withdrawYieldERC20.selector;
        selectors[2] = handler.withdrawMockUSDC.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
        targetContract(address(handler));
    }

    // THIS however, catches our bug!!!
    function statefulFuzz_testInvariantBreakHandler() public {
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
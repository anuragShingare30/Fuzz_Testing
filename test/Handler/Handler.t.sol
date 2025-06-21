// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console } from "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/Vm.sol";
import { StatefulFuzzHandler } from "src/StatefulFuzzHandler.sol";
import {YieldERC20} from "test/mocks/YieldERC20.sol";
import {MockUSDC} from "test/mocks/MockUSDC.sol";
import {StdInvariant} from "lib/forge-std/src/StdInvariant.sol";

contract Handler is Test {
    StatefulFuzzHandler statefulFuzzHandler;
    YieldERC20 yieldERC20;
    MockUSDC mockUSDC;
    address user;

    constructor(StatefulFuzzHandler _statefulFuzzHandler, YieldERC20 _yieldERC20, MockUSDC _mockUSDC) {
        statefulFuzzHandler = _statefulFuzzHandler;
        yieldERC20 = _yieldERC20;
        mockUSDC = _mockUSDC;
        user = yieldERC20.user();
    }

    function depositYieldERC20(uint256 _amount) public {
        uint256 amount = bound(_amount, 0, yieldERC20.balanceOf(user));
        vm.startPrank(user);
        yieldERC20.approve(address(statefulFuzzHandler), amount);
        statefulFuzzHandler.depositToken(yieldERC20, amount);
        vm.stopPrank();
    }

    function depositMockUSDC(uint256 _amount) public {
        uint256 amount = bound(_amount, 0, mockUSDC.balanceOf(user));
        vm.startPrank(user);
        mockUSDC.approve(address(statefulFuzzHandler), amount);
        statefulFuzzHandler.depositToken(mockUSDC, amount);
        vm.stopPrank();
    }

    function withdrawYieldERC20() public {
        vm.startPrank(user);
        statefulFuzzHandler.withdrawToken(yieldERC20);
        vm.stopPrank();
    }

    function withdrawMockUSDC() public {
        vm.startPrank(user);
        statefulFuzzHandler.withdrawToken(mockUSDC);
        vm.stopPrank();
    }
}
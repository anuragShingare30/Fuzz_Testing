// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test, console } from "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/Vm.sol";
import { StatelessFuzz } from "src/StatelessFuzz.sol";
import {StdInvariant} from "lib/forge-std/src/StdInvariant.sol";


contract StatelessFuzzTest is StdInvariant,Test {
    StatelessFuzz public statelessFuzz;

    function setUp() public {
        statelessFuzz = new StatelessFuzz();
    }

    function test_statelessFuzzInvarient(uint128 myNumber) public view {
        assert(statelessFuzz.doMath(myNumber) != 0);
    }
}
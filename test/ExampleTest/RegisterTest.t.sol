// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "lib/forge-std/src/Test.sol";
import {StdInvariant} from "lib/forge-std/src/StdInvariant.sol";
import "lib/forge-std/src/Vm.sol";
import "lib/forge-std/src/console.sol";
import {Register} from "src/Example/Register.sol";

contract RegisterTest is StdInvariant,Test {
    Register public register;
    address public user = makeAddr("user");
    uint256 public constant PRICE = 1 ether;

    function setUp() public {
        register = new Register();
        
        targetContract(address(register));
    }

    function test_fuzz_register(uint256 price) public {
        vm.assume(price >= 1 ether);

        vm.deal(user,price);
        vm.startPrank(user);
        uint256 beforeBalance = address(user).balance; // 1 ether
        console.log("Before balance", beforeBalance);

        register.register{value:price}();

        uint256 afterBalance = address(user).balance; // 0 ether
        console.log("After balance", afterBalance);
        vm.stopPrank();

        assert(beforeBalance - afterBalance == price);
    }

    function test_register() public {
        console.log("Before balance", address(user).balance);
        vm.startPrank(user);
        register.register{value:PRICE}();
        vm.stopPrank();
        console.log("After balance", address(user).balance);
    }
}
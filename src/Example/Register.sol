// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @dev Contract register user with a payment of 1 ether.
/// @dev If less eth is send it will revert
/// @dev If more ETH is sent, the contract should return the remaining
/// @notice We will try fuzz testing to break this invaraint.

contract Register {
    error PaymentNotEnough(uint256 expected, uint256 actual);

    uint256 public constant PRICE = 1 ether;

    mapping(address account => bool registered) private registry;

    function register() external payable {
        // @audit Critical exploit: if(msg.value < PRICE), the ETH will be locked in contract
        if(msg.value < PRICE) {
            revert PaymentNotEnough(PRICE, msg.value);
        }
        registry[msg.sender] = true;
    }

    function isRegistered(address account) external view returns (bool) {
        return registry[account];
    }
}
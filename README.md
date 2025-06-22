## Fuzzing and Invarients testing

- **Invarients** are properties of a program/system that `must always remain true.`
- And, using **FUzzing** we try to break that `invarient`
- All systems usually have at least one kind of invariant


### Update the `foundry.toml` file

```toml
    [fuzz]
    runs = 256
    seed = "0x2"
    fail_on_revert = false

    [invariant]
    runs = 256
    depth = 32
    fail_on_revert = true
```




### Stateless fuzzing - Open

- Stateless fuzzing (often known as just "fuzzing") is when you provide `random data to a function to get some invariant` or property to break.
- It is "stateless" because after every fuzz run, `it resets the state`, or it starts over.


<details>
<summary>Example Code</summary>

```solidity
    // Contract Example
    /// @dev Invarient: Should never return 0
    function doMath(uint128 myNumber) public pure returns (uint256) {
        if (myNumber == 2) {
            return 0;
        }
        return 1;
    }

    // Fuzzing Test Example
    contract StatelessFuzzTest is StdInvariant,Test {
        StatelessFuzz public statelessFuzz;

        function setUp() public {
            statelessFuzz = new StatelessFuzz();
        }
        function test_statelessFuzzInvarient(uint128 myNumber) public view {
            assert(statelessFuzz.doMath(myNumber) != 0);
        }
    }
```
</details>


**Cons**
- It's stateless, so if a property is broken by calling different functions, it won't find the issue
- You can never be 100% sure it works, as it's random input



### Stateful FUzzing - Open

- Stateful fuzzing is when you `provide random data to your system`, and for 1 fuzz run your system starts from the `resulting state of the previous input data.`
- Or, you keep doing random stuff to the same contract.


```solidity
    // Contract Code
    uint256 public myValue = 1;
    uint256 public storedValue = 100;
    // Invariant: This function should never return 0
    function doMoreMathAgain(uint128 myNumber) public returns (uint256) {
        uint256 response = (uint256(myNumber) / 1) + myValue;
        storedValue = response;
        return response;
    }
    function changeValue(uint256 newValue) public {
        myValue = newValue;
    }


    // Test code
    function setUp() public {
        sfc = new StatefulFuzzCatches();
        targetContract(address(sfc)); // important for fuzzing
    }
    // Stateful fuzz that will (likely) catch the invariant break
    function statefulFuzz_testMathDoesntReturnZero() public view {
        assert(sfc.storedValue() != 0);
    }
```

**Cons:**
- You can run into `path explosion` where there are too many possible paths, and the fuzzer finds nothing
- You can never be 100% sure it works, as it's random input



<details>
<summary>Example Code:</summary>

- for our balloon example,
1. `Fuzz run 1:`
    - Get a new balloon
        - Do 1 thing to try to pop it (ie: punch it, kick it, drop it)
        - Record whether or not it is popped
    - If not popped
        - Try a different thing to pop it (ie: punch it, kick it, drop it)
        - Record whether or not it is popped
    - If not popped... repeat for a certain number of times
2. `Fuzz run 2:`
    - Get a new balloon
        - Do 1 thing to try to pop it (ie: punch it, kick it, drop it)
        - Record whether or not it is popped
    - If not popped
        - Try a different thing to pop it (ie: punch it, kick it, drop it)
        - Record whether or not it is popped
    If not popped... repeat for a certain number of times
3. `Repeat`

</details>




### Stateful Fuzzing - Handler

- Handler based stateful fuzzing is the same as Open stateful fuzzing, except `we restrict the number of "random" things we can do.`
- If we have too many options, `we may never randomly come across something that will actually break our invariant. `
- So we restrict our random inputs to a set of specfic random actions that can be called.


1. `HandlerStatefulFuzzCatches.sol`
    - It is an simple contract that deposit and withdraws token
    - `Invarient:` Users must always be able to withdraw the exact balance amount out.

2. `InvariantTestFail.t.sol`
    - Upon fuzz testing with random data, the fuzzer will test the function with `random token addresses` and `random user`
    - Which will definetly break the invarient as `token` is not verified and enough balance is not provided to user

3. `Handler.t.sol`
    - To handle the randomness, we will instruct the fuzzer to only call the `deposit` and `withdraw` functions with a `specific token address and user`

    ```solidity
    contract Handler is Test {
        MainContract public mainContract;
        constructor(MainContract _mainContract){
            mainContract = _mainContract;
        }
        function firstFunction() public {
            // ..logic
        }
        function secondFunction() public {
            // ..logic
        }
    }
    ```

4. `InvariantTest.t.sol`
    - We will provide `targetContract(address(handler))` and `targetSelector(FuzzSelector({addr: address(handler), selector:selector}))` to the fuzzer
    - This will instruct the fuzzer to only call `deposit and withdraw` functions with `specific token address and users`

    ```solidity
    contract InvariantTest is StdInvariant,Test{
        Handler public handler;
        MainContract public mainContract;
        address user;

        function setUp() public {
            vm.startPrank(user);
            mainContract = new MainContract();
            vm.stopPrank();

            handler = new Handler(mainContract);
            bytes4[] memory selectors = new bytes4[](2);
            selectors[0] = handler.firstFunction.selector;
            selectors[1] = handler.secondFunction.selector;

            targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
            targetContract(address(handler));
        }

        function statefulFuzz_testInvariant() public {
            // test logic
        }
    }
    ```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ds-test/test.sol";
import "forge-std/console.sol";
import "forge-std/Vm.sol";

import "../ERC20.sol";

contract ERC20Test is DSTest {
	Vm vm = Vm(HEVM_ADDRESS);
	ERC20 erc20;

	bytes32 TEST_SYMBOL_BYTES32 = "TEST_SYMBOL___________________32";
	bytes32 TEST_NAME_BYTES32 = "TEST_NAME_____________________32";

	function setUp() public {
		erc20 = new ERC20(18, TEST_SYMBOL_BYTES32, TEST_NAME_BYTES32);
	}

	function testSymbol() public {
		string memory lowerLengthSymbol = "TEST_SYMBOL";
		ERC20 lowerLengthErc20 = new ERC20(18, bytes32("TEST_SYMBOL"), "");
		assertEq(lowerLengthErc20.symbol(), lowerLengthSymbol);

		string memory maxLengthSymbol = "TEST_SYMBOL___________________32";
		ERC20 maxLengthErc20 = new ERC20(18, bytes32("TEST_SYMBOL___________________32"), "");
		assertEq(maxLengthErc20.symbol(), maxLengthSymbol);
	}

	function testName() public {
		string memory lowerLengthName = "TEST_NAME";
		ERC20 lowerLengthErc20 = new ERC20(18, "", bytes32("TEST_NAME"));
		assertEq(lowerLengthErc20.name(), lowerLengthName);

		string memory maxLengthName = "TEST_NAME_____________________32";
		ERC20 maxLengthErc20 = new ERC20(18, "", bytes32("TEST_NAME_____________________32"));
		assertEq(maxLengthErc20.name(), maxLengthName);
	}

	function testTransfer_Static() public {
		erc20.mint(1);
		address to = address(uint160(address(this)) + 1);

		erc20.transfer(to, 1);

		assertEq(erc20.balanceOf(msg.sender), 0, "oooh");
		assertEq(erc20.balanceOf(to), 1, "aaaah");
	}

	function testTransfer(uint mintAmount, uint transferAmount, address to) public {
		vm.assume(mintAmount > transferAmount);
		erc20.mint(mintAmount);

		uint prev_balanceOfSender = erc20.balanceOf(address(this));
		uint prev_balanceOfReceiver = erc20.balanceOf(to);

		erc20.transfer(to, transferAmount);

		uint senderBalanceDelta = prev_balanceOfSender - erc20.balanceOf(address(this));
		uint receiverBalanceDelta = erc20.balanceOf(to) - prev_balanceOfReceiver;

		assertEq(senderBalanceDelta, transferAmount);
		assertEq(receiverBalanceDelta, transferAmount);

	}
                                // 1                               2		
// 0 1 2 3 4 5 6 7 8 9 a b c d e f 0 1 2 3 4 5 6 7 8 9 a b c d e f 0
// 			            deadbeefdeadbeefdeadbeefdeadbeefdeadbeef87a211a2
// 000000000000000000000000000000000000000000000000000000000000000000000000
	// function testPowerAssembly() public {
	// 	uint256 base = 2;
	// 	uint8 exponent = 8;

	// 	uint256 result = base**exponent;
	// 	assertEq(result, base.powerAssembly(exponent));
	// }

	// function testPowerSolidity() public {
	// 	uint256 base = 2;
	// 	uint8 exponent = 8;

	// 	uint256 result = base**exponent;
	// 	assertEq(result, base.powerSolidity(exponent));
	// }

	// function testPowerAssemblyFuzzy(uint256 base, uint8 exponent) public {
	// 	vm.assume(base < 256 && exponent < 32);
	// 	uint256 result = base**exponent;

	// 	assertEq(result, base.powerAssembly(exponent));
	// }

	// function testPowerSolidityFuzzy(uint256 base, uint8 exponent) public {
	// 	vm.assume(base < 256 && exponent < 32);
	// 	uint256 result = base**exponent;

	// 	assertEq(result, base.powerSolidity(exponent));
	// }
}

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

	function testTransfer_NotEnoughBalance(uint mintAmount, uint transferAmount, address to) public {
		vm.assume(mintAmount < transferAmount);
		erc20.mint(mintAmount);

		vm.expectRevert(ERC20.NotEnoughBalance.selector);
		erc20.transfer(to, transferAmount);
	}

	function testTransfer_Static() public {
		address from = address(0xDEAD);
		address to = address(0xBEEF);

		vm.prank(from);
		erc20.mint(0x277);

		vm.prank(from);
		erc20.transfer(to, 0x277);

		assertEq(erc20.balanceOf(from), 0, "Bad sender balance");
		assertEq(erc20.balanceOf(to), 0x277, "Bad receiver balance");
	}

	function testTransfer(uint mintAmount, uint transferAmount, address from, address to) public {
		vm.assume(mintAmount > transferAmount);
		vm.assume(from != to);

		vm.prank(from);
		erc20.mint(mintAmount);

		uint prev_balanceOfSender = erc20.balanceOf(from);
		uint prev_balanceOfReceiver = erc20.balanceOf(to);

		vm.prank(from);
		erc20.transfer(to, transferAmount);

		uint senderBalanceDelta = prev_balanceOfSender - erc20.balanceOf(from);
		uint receiverBalanceDelta = erc20.balanceOf(to) - prev_balanceOfReceiver;

		assertEq(senderBalanceDelta, transferAmount, "Bad sender delta");
		assertEq(receiverBalanceDelta, transferAmount, "Bad receiver delta");
	}

	function testApprove_Static() public {
		address owner = address(0xDEAD);
		address spender = address(0xBEEF);

		uint value = 1;
		vm.prank(owner);
		erc20.approve(spender,value);

		assertEq(erc20.allowance(owner, spender), value);
	}

	function testApprove(address owner, address spender, uint value) public {
		vm.assume(owner != spender);

		vm.prank(owner);
		erc20.approve(spender,value);

		assertEq(erc20.allowance(owner, spender), value);
	}

	function testTransferFrom_NotEnoughAllowance_Static() public {
		address owner = address(0xDEAD);
		address spender = address(0xBEEF);
		address to = address(0xDEADBEEF);

		uint value = 1;
		vm.prank(owner);
		erc20.approve(spender, value);

		vm.prank(spender);
		vm.expectRevert(ERC20.NotEnoughAllowance.selector);
		erc20.transferFrom(owner, to, value + 1);
	}

	function testTransferFrom_NotEnoughAllowance(address owner, address spender, address to, uint allowance, uint value) public {
		vm.assume(allowance < value);

		vm.prank(owner);
		erc20.approve(spender, allowance);

		vm.prank(spender);
		vm.expectRevert(ERC20.NotEnoughAllowance.selector);
		erc20.transferFrom(owner, to, value);
	}

	function testTransferFrom_NotEnoughBalance_Static() public {
		address owner = address(0xDEAD);
		address spender = address(0xBEEF);
		address to = address(0xDEADBEEF);

		uint value = 1;

		vm.prank(owner);
		erc20.approve(spender, value);

		vm.prank(spender);
		vm.expectRevert(ERC20.NotEnoughBalance.selector);
		erc20.transferFrom(owner, to, value);
	}

	function testTransferFrom_NotEnoughBalance(address owner, address spender, address to, uint balance, uint value) public {
		vm.assume(balance < value);
		
		vm.prank(owner);
		erc20.mint(balance);

		vm.prank(owner);
		erc20.approve(spender, type(uint).max);

		vm.prank(spender);
		vm.expectRevert(ERC20.NotEnoughBalance.selector);
		erc20.transferFrom(owner, to, value);
	}

	function testTransferFrom_Static() public {
		address owner = address(0xDEAD);
		address spender = address(0xBEEF);
		address to = address(0xDEADBEEF);

		uint value = 1;
		uint allowance = type(uint).max;

		vm.prank(owner);
		erc20.mint(value);
		vm.prank(owner);
		erc20.approve(spender, allowance);

		vm.prank(spender);
		erc20.transferFrom(owner, to, value);

		assertEq(erc20.balanceOf(owner), 0, "Bad owner balance");
		assertEq(erc20.balanceOf(to), 1, "Bad receiver balance");
		assertEq(erc20.allowance(owner, spender), allowance - 1, "Bad owner allowance");
	}

	function testTransferFrom(address owner, address spender, address to, uint mintValue, uint transferValue, uint allowance) public {
		vm.assume(owner != to);
		vm.assume(mintValue > transferValue);
		vm.assume(allowance > transferValue);


		vm.prank(owner);
		erc20.mint(mintValue);
		vm.prank(owner);
		erc20.approve(spender, allowance);

		vm.prank(spender);
		erc20.transferFrom(owner, to, transferValue);

		assertEq(erc20.balanceOf(owner), mintValue - transferValue, "Bad owner balance");
		assertEq(erc20.balanceOf(to), transferValue, "Bad receiver balance");
		assertEq(erc20.allowance(owner, spender), allowance - transferValue, "Bad owner allowance");
	}

	function testIncreaseAllowance_Overflow() public {}
}

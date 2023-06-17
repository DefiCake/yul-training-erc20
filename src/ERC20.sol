// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/console.sol";

contract ERC20 {
	event Transfer(address indexed from, address indexed to, uint256 amount);
	event Approval(address indexed);

	error NotEnoughBalance();

	uint256 private immutable _symbol_len;
	uint256 private immutable _name_len;
	uint256 private immutable decimals;

	uint256 private constant SYMBOL_SLOT = 0x0;
	uint256 private constant NAME_SLOT = 0x1;
	uint256 private constant BALANCES_SLOT = 0x2;
	uint256 private constant ALLOWANCES_SLOT = 0x3;
	uint256 private constant TOTAL_SUPPLY_SLOT = 0x4;

	bytes32 private _symbol;
	bytes32 private _name;

	mapping(address => uint256) private balances; // keccak256(address,0x2)
	mapping(address => mapping(address => uint256)) private allowances; // keccak256(address,0x3)

	uint totalSupply; // slot 0x4

	constructor(
		uint256 _decimals,
		bytes32 __symbol,
		bytes32 __name
	) {
		require(__symbol.length > 0);
		require(__name.length > 0);

		decimals = _decimals;
		_symbol = __symbol;
		_name = __name;

		uint i = 0;
		for(;;) {
			unchecked {
				if(uint256(__symbol << i * 8) == 0) {
					break;
				}

				++i;
			}
		}

		_symbol_len = i;

		i = 0;
		for(;;) {
			unchecked {
				if(uint256(__name << i * 8) == 0) {
					break;
				}

				++i;
			}
		}

		_name_len = i;
	}

	function balanceOf(address holder) public view returns (uint _bal) {
		assembly {
			mstore(0x00, holder)
			mstore(0x20, BALANCES_SLOT)
			let slot := keccak256(0x00, 0x40)
			_bal := sload(slot)
		}
	}

	function allowance(address owner, address spender) public view returns (uint _allowance) {
		return allowances[owner][spender];
	}

	function transfer(address, uint256) external returns (bool) {
		assembly {

			mstore(0x80, caller())
			mstore(0xa0, BALANCES_SLOT)
			let slot := keccak256(0x80,0x40)
			let curr_balance := sload(slot)
			let amt := calldataload(0x24)
			let new_balance := sub(curr_balance, amt)

			if gt(new_balance, curr_balance) {
				mstore(0x00, 0xad3a8b9e) // NotEnoughBalance.selector
				revert(0x1c, 0x04)
			}

			sstore(slot, new_balance)

			mstore(0x80, calldataload(0x4))
			slot := keccak256(0x80, 0x40)
			sstore(slot, add(amt, sload(slot)))
		}

		return true;
	}

	function transferFrom(
		address from,
		address to,
		uint256 amount
	) external returns (bool) {
		return true;
	}

	function approve(address,uint256) external returns (bool) {
		/// @solidity memory-safe-assembly
		assembly {
			mstore(0x00, caller())
			mstore(0x20, ALLOWANCES_SLOT)
			mstore(0x20, keccak256(0x00, 0x40))
			mstore(0x00, calldataload(4))
			let slot := keccak256(0x00, 0x40)

			sstore(slot, calldataload(36))
		}

		return true;
	}

	function mint(uint256 amount) public virtual {
		balances[msg.sender] += amount;
		totalSupply += amount;
	}

	function burn(uint256 amount) public virtual {}

	function symbol() external view returns (string memory s) {
		uint len = _symbol_len;
		assembly {
			s := mload(0x80) // 0x80 is the first free slot - assignment of len to immutable does not seem to impact memory
			mstore(s, len) // store "len" at 0x80, which is the first word of s, which stores string length
			mstore(add(s, 0x20), sload(SYMBOL_SLOT)) // in the next word, store the value of the first slot, which is _symbol
		}
	}

	function name() external view returns (string memory s) {
		uint len = _name_len;

		assembly {
			s := mload(0x80) // 0x80 is the first free slot - assignment of len to immutable does not seem to impact memory
			mstore(s, len) // store "len" at 0x80, which is the first word of s, which stores string length
			mstore(add(s, 0x20), sload(NAME_SLOT)) // in the next word, store the value of the first slot, which is _name
		}
	}
}

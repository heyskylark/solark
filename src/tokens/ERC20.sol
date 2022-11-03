// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

// @notice An implementation of ERC-20 according to the EIP-20 standard
// @notice Also an implementation of the EIP-2612 permit extension standard
// @author Solark (https://github.com/heyskylark/solark/blob/main/src/tokens/ERC20.sol)

abstract contract ERC20 {
  /*//////////////////////////////////////////////
                      EVENTS
  //////////////////////////////////////////////*/

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  /*//////////////////////////////////////////////
                  METADATA STORAGE
  //////////////////////////////////////////////*/

  string public name;
  
  string public symbol;

  uint8 public immutable decimals;

  /*//////////////////////////////////////////////
                    ERC20 STORAGE
  //////////////////////////////////////////////*/

  uint256 public totalSupply;

  mapping(address => uint256) public balanceOf;

  mapping(address => mapping(address => uint256)) public allowance;

  /*//////////////////////////////////////////////
                    CONSTRUCTOR
  //////////////////////////////////////////////*/

  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }

  /*//////////////////////////////////////////////
                    ERC-20 LOGIC
  //////////////////////////////////////////////*/

  function transfer(address to, uint256 value) public virtual returns (bool) {
    balanceOf[msg.sender] -= value;

    // Unable to exceed the max value of uint256
    // Since totalSupply cannot exceed uint256
    unchecked {
      balanceOf[to] += value;
    }

    emit Transfer(msg.sender, to, value);

    return true;
  }

  function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
    uint256 allowed = allowance[from][msg.sender];

    if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - value;

    balanceOf[from] -= value;

    unchecked {
      balanceOf[to] += value;
    }

    emit Transfer(from, to, value);

    return true;
  }

  function approve(address spender, uint256 value) public virtual returns (bool) {
    allowance[msg.sender][spender] = value;

    emit Approval(msg.sender, spender, value);

    return true;
  }

  /*//////////////////////////////////////////////
              INTERNAL MING/BURN LOGIC
  //////////////////////////////////////////////*/

  function mint(address to, uint256 value) internal virtual {
    totalSupply += value;

    unchecked {
      balanceOf[to] += value;
    }

    emit Transfer(address(0), to, value);
  }

  function burn(address from, uint256 value) internal virtual {
    balanceOf[from] -= value;

    unchecked {
      totalSupply -= value;
    }

    emit Transfer(from, address(0), value);
  }
}

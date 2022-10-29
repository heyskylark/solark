// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {MockERC721} from "./utils/mocks/MockERC721.sol";

import {ERC721TokenReceiver} from "../tokens/ERC721.sol";

contract ERC721Recipient is ERC721TokenReceiver {
  address public operator;
  address public from;
  uint256 public id;
  bytes public data;

  function onERC721Received(
    address _operator,
    address _from,
    uint256 _id,
    bytes calldata _data
  ) public virtual override returns (bytes4) {
    operator = _operator;
    from = _from;
    id = _id;
    data = _data;

    return ERC721TokenReceiver.onERC721Received.selector;
  }
}

contract RevertingERC721Recipient is ERC721TokenReceiver {
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) public virtual override returns (bytes4) {
    revert(string(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector)));
  }
}

contract WrongReturnDataERC721Recipient is ERC721TokenReceiver {
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) public virtual override returns (bytes4) {
    return 0xCAFEBEEF;
  }
}

contract NonERC721Recipient {}

contract ERC721Test is Test {
  /*//////////////////////////////////////////////
                      ERRORS
  //////////////////////////////////////////////*/
  error ZeroAddress();

  error UnsafeRecipient();

  error AlreadyMinted();

  error NotMinted();

  error NotOwner();

  error Unauthorized();

  MockERC721 token;

  function setUp() public {
    token = new MockERC721("Mock", "MCK");
  }

  function testMetadata() public {
    assertEq(token.name(), "Mock");
    assertEq(token.symbol(), "MCK");
  }

  function testMint() public {
    token.mint(address(0x1337), 1337);

    assertEq(token.balanceOf(address(0x1337)), 1);
    assertEq(token.ownerOf(1337), address(0x1337));
  }

  function testBurn() public {
    token.mint(address(0x1337), 1337);
    token.burn(1337);

    assertEq(token.balanceOf(address(0x1337)), 0);

    vm.expectRevert(NotMinted.selector);
    token.ownerOf(1337);
  }

  function testFailUnimintedBurn() public {
    token.burn(1337);
  }

  // function testApprove() public {

  // }

  // function testApproveAll() public {

  // }

  // function testApprovedBurn() public {

  // }
}

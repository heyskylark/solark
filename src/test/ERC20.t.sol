// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "./utils/TestPlus.sol";

import {MockERC20} from "./utils/mocks/MockERC20.sol";

contract ERC20Test is TestPlus {
  /*//////////////////////////////////////////////
                      ERRORS
  //////////////////////////////////////////////*/

  error ExpiredPermit();

  error InvalidSigner();

  /*//////////////////////////////////////////////
                      EVENTS
  //////////////////////////////////////////////*/

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  /*//////////////////////////////////////////////
                      TEST
  //////////////////////////////////////////////*/

  MockERC20 token;

  bytes32 constant PERMIT_TYPE_HASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  function setUp() public {
    token = new MockERC20("Mock", "MCK", 18);
  }

  function testMetadata() public {
    assertEq(token.name(), "Mock");
    assertEq(token.symbol(), "MCK");
    assertEq(token.decimals(), 18);
  }

  function testMint() public {
    vm.expectEmit(true, true, false, true);
    emit Transfer(address(0), address(0x1337), 1e18);
    token.mint(address(0x1337), 1e18);

    assertEq(token.totalSupply(), 1e18);
    assertEq(token.balanceOf(address(0x1337)), 1e18);
  }

  function testBurn() public {
    token.mint(address(0x1337), 1e18);

    vm.expectEmit(true, true, false, true);
    emit Transfer(address(0x1337), address(0), 0.5e18);
    token.burn(address(0x1337), 0.5e18);

    assertEq(token.balanceOf(address(0x1337)), 1e18 - 0.5e18);
    assertEq(token.totalSupply(), 1e18 - 0.5e18);
  }

  function testApprove() public {
    vm.expectEmit(true, true, false, true);
    emit Approval(address(this), address(0x1337), 1e18);
    assertTrue(token.approve(address(0x1337), 1e18));

    assertEq(token.allowance(address(this), address(0x1337)), 1e18);
  }

  function testTransfer() public {
    token.mint(address(this), 1e18);

    vm.expectEmit(true, true, false, true);
    emit Transfer(address(this), address(0x1337), 1e18);
    assertTrue(token.transfer(address(0x1337), 1e18));

    assertEq(token.balanceOf(address(this)), 0);
    assertEq(token.balanceOf(address(0x1337)), 1e18);
    assertEq(token.totalSupply(), 1e18);
  }

  function testTransferFrom() public {
    address from = address(0x1337);
    address to = address(0xBA11);

    token.mint(from, 1e18);

    vm.prank(from);
    token.approve(address(this), 1e18);

    vm.expectEmit(true, true, false, true);
    emit Transfer(from, to, 1e18);
    token.transferFrom(from, to, 1e18);

    assertEq(token.balanceOf(from), 0);
    assertEq(token.balanceOf(to), 1e18);
    assertEq(token.allowance(from, address(this)), 0);
    assertEq(token.totalSupply(), 1e18);
  }

  function testInfiniteTransferFrom() public {
    address from = address(0x1337);
    address to = address(0xBA11);

    token.mint(from, 1e18);

    vm.prank(from);
    token.approve(address(this), type(uint256).max);

    vm.expectEmit(true, true, false, true);
    emit Transfer(from, to, 1e18);
    token.transferFrom(from, to, 1e18);

    assertEq(token.balanceOf(from), 0);
    assertEq(token.balanceOf(to), 1e18);
    assertEq(token.allowance(from, address(this)), type(uint256).max);
    assertEq(token.totalSupply(), 1e18);
  }

  function testPermit() public {
    uint256 privateKey = 0x1337;
    address signer = vm.addr(privateKey);

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(
      privateKey,
      keccak256(
        abi.encodePacked(
          "\x19\x01",
          token.DOMAIN_SEPARATOR(),
          keccak256(abi.encode(PERMIT_TYPE_HASH, signer, address(0xBA11), 1e18, 0, block.timestamp))
        )
      )
    );

    vm.expectEmit(true, true, false, true);
    emit Approval(signer, address(0xBA11), 1e18);
    token.permit(signer, address(0xBA11), 1e18, block.timestamp, v, r, s);

    assertEq(token.allowance(signer, address(0xBA11)), 1e18);
  }

  function testFailMintOverflow() public {
    token.mint(address(0x1337), type(uint256).max);
    token.mint(address(0x1337), 1);
  }

  function testFailBurnUnderflow() public {
    token.burn(address(0x1337), 1);
  }

  function testFailTransferInsifficientBalance() public {
    token.mint(address(0x1337), 0.9e18);
    token.transfer(address(0xBA11), 1e18);
  }

  function testFailTransferFromInsifficientAllowance() public {
    address from = address(0x1337);

    token.mint(from, 1e18);

    vm.prank(from);
    token.approve(address(this), 0.9e18);

    token.transferFrom(from, address(this), 1e18);
  }

  function testFailTransferFromInsifficientBalance() public {
    address from = address(0x1337);

    token.mint(from, 0.5e18);

    vm.prank(from);
    token.approve(address(this), 1e18);

    token.transferFrom(from, address(this), 1e18);
  }

  function testPermitBadDeadline() public {
    uint256 privateKey = 0x1337;
    address signer = vm.addr(privateKey);

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(
      privateKey,
      keccak256(
        abi.encodePacked(
          "\x19\x01",
          token.DOMAIN_SEPARATOR(),
          keccak256(abi.encode(PERMIT_TYPE_HASH, signer, address(0xBA11), 1e18, 0, block.timestamp))
        )
      )
    );

    vm.expectRevert(InvalidSigner.selector);
    token.permit(signer, address(0xBA11), 1e18, block.timestamp + 1, v, r, s);
  }

  function testPermitExpiredDeadline() public {
    uint256 privateKey = 0x1337;
    address signer = vm.addr(privateKey);
    uint256 oldTimestamp = block.timestamp;

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(
      privateKey,
      keccak256(
        abi.encodePacked(
          "\x19\x01",
          token.DOMAIN_SEPARATOR(),
          keccak256(abi.encode(PERMIT_TYPE_HASH, signer, address(0xBA11), 1e18, 0, oldTimestamp))
        )
      )
    );

    vm.warp(block.timestamp + 1);
    vm.expectRevert(ExpiredPermit.selector);
    token.permit(signer, address(0xBA11), 1e18, oldTimestamp, v, r, s);
  }

  function testPermitBadNonce() public {
    uint256 privateKey = 0x1337;
    address signer = vm.addr(privateKey);

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(
      privateKey,
      keccak256(
        abi.encodePacked(
          "\x19\x01",
          token.DOMAIN_SEPARATOR(),
          keccak256(abi.encode(PERMIT_TYPE_HASH, signer, address(0xBA11), 1e18, 1, block.timestamp))
        )
      )
    );

    vm.expectRevert(InvalidSigner.selector);
    token.permit(signer, address(0xBA11), 1e18, block.timestamp, v, r, s);
  }

  function testPermitReplayAttack() public {
    uint256 privateKey = 0x1337;
    address signer = vm.addr(privateKey);

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(
      privateKey,
      keccak256(
        abi.encodePacked(
          "\x19\x01",
          token.DOMAIN_SEPARATOR(),
          keccak256(abi.encode(PERMIT_TYPE_HASH, signer, address(0xBA11), 1e18, 0, block.timestamp))
        )
      )
    );

    token.permit(signer, address(0xBA11), 1e18, block.timestamp, v, r, s);

    vm.expectRevert(InvalidSigner.selector);
    token.permit(signer, address(0xBA11), 1e18, block.timestamp, v, r, s);
  }
}

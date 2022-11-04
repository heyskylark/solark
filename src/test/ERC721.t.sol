// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "./utils/TestPlus.sol";

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
  function onERC721Received(address, address, uint256, bytes calldata) public virtual override returns (bytes4) {
    revert(string(abi.encodePacked(ERC721TokenReceiver.onERC721Received.selector)));
  }
}

contract WrongReturnDataERC721Recipient is ERC721TokenReceiver {
  function onERC721Received(address, address, uint256, bytes calldata) public virtual override returns (bytes4) {
    return 0xCAFEBEEF;
  }
}

contract NonERC721Recipient {}

contract ERC721Test is TestPlus {
  /*//////////////////////////////////////////////
                      ERRORS
  //////////////////////////////////////////////*/
  error ZeroAddress();

  error UnsafeRecipient();

  error AlreadyMinted();

  error NotMinted();

  error NotOwner();

  error Unauthorized();

  /*//////////////////////////////////////////////
                      EVENTS
  //////////////////////////////////////////////*/

  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  /*//////////////////////////////////////////////
                      TEST
  //////////////////////////////////////////////*/

  MockERC721 token;

  function setUp() public {
    token = new MockERC721("Mock", "MCK");
  }

  function testMetadata() public {
    assertEq(token.name(), "Mock");
    assertEq(token.symbol(), "MCK");
  }

  function testMint() public {
    vm.expectEmit(true, true, true, false);
    emit Transfer(address(0), address(0x1337), 1337);
    token.mint(address(0x1337), 1337);

    assertEq(token.balanceOf(address(0x1337)), 1);
    assertEq(token.ownerOf(1337), address(0x1337));
  }

  function testBurn() public {
    token.mint(address(0x1337), 1337);

    vm.expectEmit(true, true, true, false);
    emit Transfer(address(0x1337), address(0), 1337);
    token.burn(1337);

    assertEq(token.balanceOf(address(0x1337)), 0);

    vm.expectRevert(NotMinted.selector);
    token.ownerOf(1337);
  }

  function testApprove() public {
    token.mint(address(this), 1337);

    vm.expectEmit(true, true, true, false);
    emit Approval(address(this), address(0x1337), 1337);
    token.approve(address(0x1337), 1337);

    assertEq(token.getApproved(1337), address(0x1337));
  }

  function testApproveAndBurn() public {
    token.mint(address(this), 1337);

    token.approve(address(0x1337), 1337);

    token.burn(1337);

    assertEq(token.balanceOf(address(0x1337)), 0);
    assertEq(token.getApproved(1337), address(0));

    vm.expectRevert(NotMinted.selector);
    token.ownerOf(1337);
  }

  function testApproveAll() public {
    vm.expectEmit(true, true, false, false);
    emit ApprovalForAll(address(this), address(0x1337), true);
    token.setApprovalForAll(address(0x1337), true);

    assertTrue(token.isApprovedForAll(address(this), address(0x1337)));
  }

  function testTransferFrom() public {
    address from = address(0xBA11);

    token.mint(from, 1337);

    vm.prank(from);
    token.approve(address(this), 1337);

    vm.expectEmit(true, true, true, false);
    emit Transfer(from, address(0x1337), 1337);
    token.transferFrom(from, address(0x1337), 1337);

    assertEq(token.getApproved(1337), address(0));
    assertEq(token.ownerOf(1337), address(0x1337));
    assertEq(token.balanceOf(address(0x1337)), 1);
    assertEq(token.balanceOf(address(0xBA11)), 0);
  }

  function testTransferFromSelf() public {
    address from = address(0xBA11);

    token.mint(from, 1337);

    vm.prank(from);
    vm.expectEmit(true, true, true, false);
    emit Transfer(from, address(0x1337), 1337);
    token.transferFrom(from, address(0x1337), 1337);

    assertEq(token.getApproved(1337), address(0));
    assertEq(token.ownerOf(1337), address(0x1337));
    assertEq(token.balanceOf(address(0x1337)), 1);
    assertEq(token.balanceOf(address(0xBA11)), 0);
  }

  function testTransferFromApproveAll() public {
    address from = address(0xBA11);

    token.mint(from, 1337);

    vm.prank(from);
    token.setApprovalForAll(address(this), true);

    vm.expectEmit(true, true, true, false);
    emit Transfer(from, address(0x1337), 1337);
    token.transferFrom(from, address(0x1337), 1337);

    assertEq(token.getApproved(1337), address(0));
    assertEq(token.ownerOf(1337), address(0x1337));
    assertEq(token.balanceOf(address(0x1337)), 1);
    assertEq(token.balanceOf(address(0xBA11)), 0);
  }

  function testSafeTransferFromApproveAll() public {
    address from = address(0xBA11);

    token.mint(from, 1337);

    vm.prank(from);
    token.setApprovalForAll(address(this), true);

    vm.expectEmit(true, true, true, false);
    emit Transfer(from, address(0x1337), 1337);
    token.safeTransferFrom(from, address(0x1337), 1337);

    assertEq(token.getApproved(1337), address(0));
    assertEq(token.ownerOf(1337), address(0x1337));
    assertEq(token.balanceOf(address(0x1337)), 1);
    assertEq(token.balanceOf(address(0xBA11)), 0);
  }

  function testSafeTransferFromToERC721Recipient() public {
    address from = address(0x1337);
    ERC721Recipient recipient = new ERC721Recipient();

    token.mint(from, 1337);

    vm.prank(from);
    token.setApprovalForAll(address(this), true);

    vm.expectEmit(true, true, true, false);
    emit Transfer(from, address(recipient), 1337);
    token.safeTransferFrom(from, address(recipient), 1337);

    assertEq(token.getApproved(1337), address(0));
    assertEq(token.ownerOf(1337), address(recipient));
    assertEq(token.balanceOf(address(recipient)), 1);
    assertEq(token.balanceOf(address(from)), 0);

    assertEq(recipient.operator(), address(this));
    assertEq(recipient.from(), from);
    assertEq(recipient.id(), 1337);
    assertBytesEq(recipient.data(), "");
  }

  function testSafeTransferFromToERC721RecipientWithData() public {
    address from = address(0x1337);
    ERC721Recipient recipient = new ERC721Recipient();

    token.mint(from, 1337);

    vm.prank(from);
    token.setApprovalForAll(address(this), true);

    vm.expectEmit(true, true, true, false);
    emit Transfer(from, address(recipient), 1337);
    token.safeTransferFrom(from, address(recipient), 1337, "transfer for deez");

    assertEq(token.getApproved(1337), address(0));
    assertEq(token.ownerOf(1337), address(recipient));
    assertEq(token.balanceOf(address(recipient)), 1);
    assertEq(token.balanceOf(address(from)), 0);

    assertEq(recipient.operator(), address(this));
    assertEq(recipient.from(), from);
    assertEq(recipient.id(), 1337);
    assertBytesEq(recipient.data(), "transfer for deez");
  }

  function testSafeMintToEOA() public {
    vm.expectEmit(true, true, true, false);
    emit Transfer(address(0), address(0x1337), 1337);
    token.safeMint(address(0x1337), 1337);

    assertEq(token.balanceOf(address(0x1337)), 1);
    assertEq(token.ownerOf(1337), address(0x1337));
  }

  function testSafeMintToERC721Recipient() public {
    ERC721Recipient recipient = new ERC721Recipient();

    vm.expectEmit(true, true, true, false);
    emit Transfer(address(0), address(recipient), 1337);
    token.safeMint(address(recipient), 1337);

    assertEq(token.balanceOf(address(recipient)), 1);
    assertEq(token.ownerOf(1337), address(recipient));

    assertEq(recipient.operator(), address(this));
    assertEq(recipient.from(), address(0));
    assertEq(recipient.id(), 1337);
    assertBytesEq(recipient.data(), "");
  }

  function testSafeMintToERC721RecipientWithData() public {
    ERC721Recipient recipient = new ERC721Recipient();

    vm.expectEmit(true, true, true, false);
    emit Transfer(address(0), address(recipient), 1337);
    token.safeMint(address(recipient), 1337, "transfer for deez");

    assertEq(token.balanceOf(address(recipient)), 1);
    assertEq(token.ownerOf(1337), address(recipient));

    assertEq(recipient.operator(), address(this));
    assertEq(recipient.from(), address(0));
    assertEq(recipient.id(), 1337);
    assertBytesEq(recipient.data(), "transfer for deez");
  }

  function testFailMintToZero() public {
    token.mint(address(0), 1337);
  }

  function testFailDoubleMint() public {
    token.mint(address(0x1337), 1337);
    token.mint(address(0x1337), 1337);
  }

  function testFailUnimintedBurn() public {
    token.burn(1337);
  }

  function testFailDoubleBurn() public {
    token.mint(address(0x1337), 1337);

    token.burn(1337);
    token.burn(1337);
  }

  function testFailApproveUnminted() public {
    token.approve(address(0x1337), 1337);
  }

  function testFailUnauthroizedApprove() public {
    token.mint(address(0xBA11), 1337);

    vm.prank(address(0x1337));
    token.approve(address(0x1337), 1337);
  }

  function testFailUnownedTransferFrom() public {
    token.mint(address(0xBA11), 1337);

    vm.prank(address(0x1337));
    token.transferFrom(address(0xBA11), address(0x1337), 1337);
  }

  function testFailTransferFromWrongAddress() public {
    token.mint(address(0x1337), 1337);

    vm.prank(address(0x1337));
    token.transferFrom(address(0xBA11), address(0xCAFE), 1337);
  }

  function testFailTransferFromZero() public {
    token.mint(address(0x1337), 1337);

    vm.prank(address(0x1337));
    token.transferFrom(address(0), address(0xBA11), 1337);
  }

  function testFailTransferFromNotOwner() public {
    token.mint(address(0x1337), 1337);

    vm.prank(address(0xBA11));
    token.transferFrom(address(0x1337), address(0xBA11), 1337);
  }

  function testFailSafeTransferFromNonERC721Recipient() public {
    token.mint(address(this), 1337);

    token.safeTransferFrom(address(this), address(new NonERC721Recipient()), 1337);
  }

  function testFailSafeTransferFromNonERC721RecipientWithData() public {
    token.mint(address(this), 1337);

    token.safeTransferFrom(address(this), address(new NonERC721Recipient()), 1337, "transfer for deez");
  }

  function testFailSafeTransferFromRevertingERC721Recipient() public {
    token.mint(address(this), 1337);

    token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), 1337);
  }

  function testFailSafeTransferFromRevertingERC721RecipientWithData() public {
    token.mint(address(this), 1337);

    token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), 1337, "transfer for deez");
  }

  function testFailSafeTransferFromToERC721RecipientWithWrongReturnData() public {
    token.mint(address(this), 1337);

    token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), 1337);
  }

  function testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData() public {
    token.mint(address(this), 1337);

    token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), 1337, "transfer for deez");
  }

  function testFailSafeMintToNonERC721Recipient() public {
    token.mint(address(this), 1337);

    token.safeTransferFrom(address(this), address(new NonERC721Recipient()), 1337);
  }

  function testFailSafeMintToNonERC721RecipientWithData() public {
    token.mint(address(this), 1337);

    token.safeTransferFrom(address(this), address(new NonERC721Recipient()), 1337, "transfer for deez");
  }

  function testFailSafeMintToRevertingERC721Recipient() public {
    token.mint(address(this), 1337);

    token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), 1337);
  }

  function testFailSafeMintToRevertingERC721RecipientWithData() public {
    token.mint(address(this), 1337);

    token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), 1337, "transfer for deez");
  }

  function testFailSafeMintToERC721RecipientWithWrongReturnData() public {
    token.mint(address(this), 1337);

    token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), 1337);
  }

  function testFailSafeMintToERC721RecipientWithWrongReturnDataWithData() public {
    token.mint(address(this), 1337);

    token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), 1337, "transfer for deez");
  }

  function testFailBalanceOfZeroAddress() public view {
    token.balanceOf(address(0));
  }

  function testFailOwnerOfUnminted() public view {
    token.ownerOf(1337);
  }

  /*//////////////////////////////////////////////
                      FUZZING
  //////////////////////////////////////////////*/
  function testMetadata(string memory name, string memory symbol) public {
    MockERC721 tkn = new MockERC721(name, symbol);

    assertEq(tkn.name(), name);
    assertEq(tkn.symbol(), symbol);
  }

  function testMint(address to, uint256 id) public {
    if (to == address(0)) to = address(0x1337);

    token.mint(to, id);

    assertEq(token.balanceOf(to), 1);
    assertEq(token.ownerOf(id), to);
  }

  function testBurn(address to, uint256 id) public {
    if (to == address(0)) to = address(0x1337);

    token.mint(to, id);

    token.burn(id);

    assertEq(token.balanceOf(to), 0);

    vm.expectRevert(NotMinted.selector);
    token.ownerOf(id);
  }

  function testApprove(address to, uint256 id) public {
    if (to == address(0)) to = address(0x1337);

    token.mint(address(this), id);

    vm.expectEmit(true, true, true, false);
    emit Approval(address(this), address(to), id);
    token.approve(address(to), id);

    assertEq(token.getApproved(id), address(to));
  }

  function testApproveAndBurn(address to, uint256 id) public {
    if (to == address(0)) to = address(0x1337);

    token.mint(address(this), id);

    token.approve(address(to), id);

    token.burn(id);

    assertEq(token.balanceOf(address(this)), 0);
    assertEq(token.getApproved(id), address(0));

    vm.expectRevert(NotMinted.selector);
    token.ownerOf(id);
  }

  function testApproveAll(address to) public {
    if (to == address(0)) to = address(0x1337);

    vm.expectEmit(true, true, false, false);
    emit ApprovalForAll(address(this), address(to), true);
    token.setApprovalForAll(address(to), true);

    assertTrue(token.isApprovedForAll(address(this), address(to)));
  }

  function testTransferFrom(address to, uint256 id) public {
    address from = address(0xBA11);
    if (to == address(0)) to = address(0x1337);

    token.mint(from, id);

    vm.prank(from);
    token.approve(address(this), id);

    vm.expectEmit(true, true, true, false);
    emit Transfer(from, address(to), id);
    token.transferFrom(from, address(to), id);

    assertEq(token.getApproved(id), address(0));
    assertEq(token.ownerOf(id), address(to));
    assertEq(token.balanceOf(address(to)), 1);
    assertEq(token.balanceOf(address(from)), 0);
  }

  function testTransferFromSelf(address to, uint256 id) public {
    address from = address(0xBA11);
    if (to == address(0)) to = address(0x1337);

    token.mint(from, id);

    vm.prank(from);
    vm.expectEmit(true, true, true, false);
    emit Transfer(from, address(to), id);
    token.transferFrom(from, address(to), id);

    assertEq(token.getApproved(id), address(0));
    assertEq(token.ownerOf(id), address(to));
    assertEq(token.balanceOf(address(to)), 1);
    assertEq(token.balanceOf(address(from)), 0);
  }

  function testTransferFromApproveAll(address to, uint256 id) public {
    address from = address(0xBA11);
    if (to == address(0)) to = address(0x1337);

    token.mint(from, id);

    vm.prank(from);
    token.setApprovalForAll(address(this), true);

    vm.expectEmit(true, true, true, false);
    emit Transfer(from, address(to), id);
    token.transferFrom(from, address(to), id);

    assertEq(token.getApproved(id), address(0));
    assertEq(token.ownerOf(id), address(to));
    assertEq(token.balanceOf(address(to)), 1);
    assertEq(token.balanceOf(address(from)), 0);
  }

  function testSafeTransferFromApproveAll(address to, uint256 id) public {
    address from = address(0xBA11);
    if (to == address(0)) to = address(0x1337);

    token.mint(from, id);

    vm.prank(from);
    token.setApprovalForAll(address(this), true);

    vm.expectEmit(true, true, true, false);
    emit Transfer(from, address(to), id);
    token.safeTransferFrom(from, address(to), id);

    assertEq(token.getApproved(id), address(0));
    assertEq(token.ownerOf(id), address(to));
    assertEq(token.balanceOf(address(to)), 1);
    assertEq(token.balanceOf(address(from)), 0);
  }

  function testSafeTransferFromToERC721Recipient(uint256 id) public {
    address from = address(0x1337);
    ERC721Recipient recipient = new ERC721Recipient();

    token.mint(from, id);

    vm.prank(from);
    token.setApprovalForAll(address(this), true);

    vm.expectEmit(true, true, true, false);
    emit Transfer(from, address(recipient), id);
    token.safeTransferFrom(from, address(recipient), id);

    assertEq(token.getApproved(id), address(0));
    assertEq(token.ownerOf(id), address(recipient));
    assertEq(token.balanceOf(address(recipient)), 1);
    assertEq(token.balanceOf(address(from)), 0);

    assertEq(recipient.operator(), address(this));
    assertEq(recipient.from(), from);
    assertEq(recipient.id(), id);
    assertBytesEq(recipient.data(), "");
  }

  function testSafeTransferFromToERC721RecipientWithData(uint256 id, bytes calldata data) public {
    address from = address(0x1337);
    ERC721Recipient recipient = new ERC721Recipient();

    token.mint(from, id);

    vm.prank(from);
    token.setApprovalForAll(address(this), true);

    vm.expectEmit(true, true, true, false);
    emit Transfer(from, address(recipient), id);
    token.safeTransferFrom(from, address(recipient), id, data);

    assertEq(token.getApproved(id), address(0));
    assertEq(token.ownerOf(id), address(recipient));
    assertEq(token.balanceOf(address(recipient)), 1);
    assertEq(token.balanceOf(address(from)), 0);

    assertEq(recipient.operator(), address(this));
    assertEq(recipient.from(), from);
    assertEq(recipient.id(), id);
    assertBytesEq(recipient.data(), data);
  }

  function testSafeMintToEOA(address to, uint256 id) public {
    if (to == address(0)) to = address(0x1337);

    vm.expectEmit(true, true, true, false);
    emit Transfer(address(0), address(to), id);
    token.safeMint(address(to), id);

    assertEq(token.balanceOf(address(to)), 1);
    assertEq(token.ownerOf(id), address(to));
  }

  function testSafeMintToERC721Recipient(uint256 id) public {
    ERC721Recipient recipient = new ERC721Recipient();

    vm.expectEmit(true, true, true, false);
    emit Transfer(address(0), address(recipient), id);
    token.safeMint(address(recipient), id);

    assertEq(token.balanceOf(address(recipient)), 1);
    assertEq(token.ownerOf(id), address(recipient));

    assertEq(recipient.operator(), address(this));
    assertEq(recipient.from(), address(0));
    assertEq(recipient.id(), id);
    assertBytesEq(recipient.data(), "");
  }

  function testSafeMintToERC721RecipientWithData(uint256 id, bytes calldata data) public {
    ERC721Recipient recipient = new ERC721Recipient();

    vm.expectEmit(true, true, true, false);
    emit Transfer(address(0), address(recipient), id);
    token.safeMint(address(recipient), id, data);

    assertEq(token.balanceOf(address(recipient)), 1);
    assertEq(token.ownerOf(id), address(recipient));

    assertEq(recipient.operator(), address(this));
    assertEq(recipient.from(), address(0));
    assertEq(recipient.id(), id);
    assertBytesEq(recipient.data(), data);
  }

  function testFailMintToZero(uint256 id) public {
    token.mint(address(0), id);
  }

  function testFailDoubleMint(address to, uint256 id) public {
    if (to == address(0)) to = address(0x1337);

    token.mint(address(to), id);
    token.mint(address(to), id);
  }

  function testFailUnimintedBurn(uint256 id) public {
    token.burn(id);
  }

  function testFailDoubleBurn(address to, uint256 id) public {
    if (to == address(0)) to = address(0x1337);

    token.mint(address(to), id);

    token.burn(id);
    token.burn(id);
  }

  function testFailApproveUnminted(address to, uint256 id) public {
    if (to == address(0)) to = address(0x1337);

    token.approve(address(to), id);
  }

  function testFailUnauthroizedApprove(address owner, address to, uint256 id) public {
    if (to == address(0)) to = address(0x1337);
    if (owner == address(0)) owner = address(0xBA11);
    if (owner == to) revert();

    token.mint(address(owner), id);

    vm.prank(address(to));
    token.approve(address(to), id);
  }

  function testFailUnownedTransferFrom(address owner, address to, uint256 id) public {
    if (to == address(0)) to = address(0x1337);
    if (owner == address(0)) owner = address(0xBA11);
    if (owner == to) revert();

    token.mint(address(owner), 1337);

    vm.prank(address(to));
    token.transferFrom(address(owner), address(to), id);
  }

  function testFailTransferFromWrongAddress(address owner, address from, address to, uint256 id) public {
    if (to == address(0)) to = address(0x1337);
    if (from == address(0)) from = address(0xCAFE);
    if (owner == address(0)) owner = address(0xBA11);
    if (from == owner) revert();

    token.mint(address(owner), id);

    vm.prank(address(owner));
    token.transferFrom(address(from), address(to), id);
  }

  function testFailTransferFromZero(address owner, address to, uint256 id) public {
    if (to == address(0)) to = address(0x1337);
    if (owner == address(0)) owner = address(0xBA11);
    if (owner == to) revert();

    token.mint(address(owner), id);

    vm.prank(address(owner));
    token.transferFrom(address(0), address(0xBA11), id);
  }

  function testFailTransferFromNotOwner(address owner, address to, uint256 id) public {
    if (to == address(0)) to = address(0x1337);
    if (owner == address(0)) owner = address(0xBA11);
    if (owner == to) revert();

    token.mint(address(owner), id);

    vm.prank(address(to));
    token.transferFrom(address(owner), address(to), id);
  }

  function testFailSafeTransferFromNonERC721Recipient(uint256 id) public {
    token.mint(address(this), id);

    token.safeTransferFrom(address(this), address(new NonERC721Recipient()), id);
  }

  function testFailSafeTransferFromNonERC721RecipientWithData(uint256 id, bytes calldata data) public {
    token.mint(address(this), id);

    token.safeTransferFrom(address(this), address(new NonERC721Recipient()), id, data);
  }

  function testFailSafeTransferFromRevertingERC721Recipient(uint256 id) public {
    token.mint(address(this), id);

    token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), id);
  }

  function testFailSafeTransferFromRevertingERC721RecipientWithData(uint256 id, bytes calldata data) public {
    token.mint(address(this), id);

    token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), id, data);
  }

  function testFailSafeTransferFromToERC721RecipientWithWrongReturnData(uint256 id) public {
    token.mint(address(this), id);

    token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), id);
  }

  function testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData(
    uint256 id,
    bytes calldata data
  ) public {
    token.mint(address(this), id);

    token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), id, data);
  }

  function testFailSafeMintToNonERC721Recipient(uint256 id) public {
    token.mint(address(this), id);

    token.safeTransferFrom(address(this), address(new NonERC721Recipient()), id);
  }

  function testFailSafeMintToNonERC721RecipientWithData(uint256 id, bytes calldata data) public {
    token.mint(address(this), id);

    token.safeTransferFrom(address(this), address(new NonERC721Recipient()), id, data);
  }

  function testFailSafeMintToRevertingERC721Recipient(uint256 id) public {
    token.mint(address(this), id);

    token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), id);
  }

  function testFailSafeMintToRevertingERC721RecipientWithData(uint256 id, bytes calldata data) public {
    token.mint(address(this), id);

    token.safeTransferFrom(address(this), address(new RevertingERC721Recipient()), id, data);
  }

  function testFailSafeMintToERC721RecipientWithWrongReturnData(uint256 id) public {
    token.mint(address(this), id);

    token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), id);
  }

  function testFailSafeMintToERC721RecipientWithWrongReturnDataWithData(uint256 id, bytes calldata data) public {
    token.mint(address(this), id);

    token.safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), id, data);
  }

  function testFailOwnerOfUnminted(uint256 id) public view {
    token.ownerOf(id);
  }
}

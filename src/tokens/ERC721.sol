// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// @notice An implmentation of ERC-721 according to the EIP-721 specifications.
// @author Solark ()
abstract contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}

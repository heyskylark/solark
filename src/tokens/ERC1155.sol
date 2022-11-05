// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice An implementation of ERC-1155 according to the EIP-1155 standard
/// @author Solark (https://github.com/heyskylark/solark/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
  /*//////////////////////////////////////////////
                      ERRORS
  //////////////////////////////////////////////*/

  error Unauthorized();

  error UnsafeRecipient();

  error LengthMismatch();

  /*//////////////////////////////////////////////
                      EVENTS
  //////////////////////////////////////////////*/

  event TransferSingle(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 id,
    uint256 value
  );

  event TransferBatch(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );

  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  event URI(string value, uint256 indexed id);

  /*//////////////////////////////////////////////
                  ERC1155 STORAGE
  //////////////////////////////////////////////*/

  mapping (address => mapping(uint256 => uint256)) public balanceOf;

  mapping (address => mapping(address => bool)) public isApprovedForAll;

  /*//////////////////////////////////////////////
                  METADATA LOGIC
  //////////////////////////////////////////////*/

  function uri(uint256 id) public view virtual returns (string memory);

  /*//////////////////////////////////////////////
                  ERC1155 LOGIC
  //////////////////////////////////////////////*/

  function setApprovalForAll(address operator, bool approved) public virtual {
    isApprovedForAll[msg.sender][operator] = approved;

    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) public virtual {
    if (msg.sender != from && !isApprovedForAll[from][msg.sender]) {
      revert Unauthorized();
    }

    balanceOf[from][id] -= value;
    balanceOf[to][id] += value;

    emit TransferSingle(msg.sender, from, to, id, value);

    if (
      to.code.length != 0 &&
      ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, value, data) !=
      ERC1155TokenReceiver.onERC1155Received.selector
    ) revert UnsafeRecipient();
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) public virtual {
    if (msg.sender != from && !isApprovedForAll[from][msg.sender]) {
      revert Unauthorized();
    }

    if (ids.length != values.length) revert LengthMismatch();

    for(uint i = 0; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 value = values[i];

      balanceOf[from][id] -= value;
      balanceOf[to][id] += value;
    }

    emit TransferBatch(msg.sender, from, to, ids, values);

    if (
      to.code.length != 0 &&
      ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, values, data) !=
      ERC1155TokenReceiver.onERC1155BatchReceived.selector
    ) revert UnsafeRecipient();
  }

  function balanceOfBatch(
    address[] calldata owners,
    uint256[] calldata ids
  ) public view virtual returns (uint256[] memory balances) {
    if (owners.length != ids.length) revert LengthMismatch();

    balances = new uint256[](owners.length);

    unchecked {
      for(uint256 i = 0; i < owners.length; i++) {
        balances[i] = balanceOf[owners[i]][ids[i]];
      }
    }
  }

  /*//////////////////////////////////////////////
              INTERNAL MING/BURN LOGIC
  //////////////////////////////////////////////*/

  function _mint(
    address to,
    uint256 id,
    uint256 value,
    bytes memory data
  ) internal virtual {
    balanceOf[to][id] += value;

    emit TransferSingle(msg.sender, address(0), to, id, value);

    if (
      to.code.length != 0 &&
      ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, value, data) !=
      ERC1155TokenReceiver.onERC1155Received.selector
    ) revert UnsafeRecipient();
  }

  function _batchMint(
    address to,
    uint256[] memory ids,
    uint256[] memory values,
    bytes memory data
  ) internal virtual {
    if (ids.length != values.length) revert LengthMismatch();

    for(uint256 i = 0; i < ids.length; i++) {
      balanceOf[to][ids[i]] +=  values[i];
    }

    emit TransferBatch(msg.sender, address(0), to, ids, values);

    if (
      to.code.length != 0 &&
      ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, values, data) !=
      ERC1155TokenReceiver.onERC1155BatchReceived.selector
    ) revert UnsafeRecipient();
  }

  function _burn(
    address from,
    uint256 id,
    uint256 value
  ) internal virtual {
    balanceOf[from][id] -= value;

    emit TransferSingle(msg.sender, from, address(0), id, value);
  }

  function _batchBurn(
    address from,
    uint256[] memory ids,
    uint256[] memory values
  ) internal virtual {
    if (ids.length != values.length) revert LengthMismatch();

    for(uint256 i = 0; i < ids.length; i++) {
      balanceOf[from][ids[i]] -= values[i];
    }

    emit TransferBatch(msg.sender, from, address(0), ids, values);
  }

  /*//////////////////////////////////////////////
                    ERC-165 LOGIC
  //////////////////////////////////////////////*/

  function supportsInterface(bytes4 interfaceID) public view virtual returns (bool) {
    return
      interfaceID == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
      interfaceID == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
      interfaceID == 0x0e89341c; /// ERC165 Interface ID for ERC1155MetadataURI
  }
}
  
/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solark (https://github.com/heyskylark/solark/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) external virtual returns (bytes4) {
    return ERC1155TokenReceiver.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external virtual returns (bytes4) {
    return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
  }
}  

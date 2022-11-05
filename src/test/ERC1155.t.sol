// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "./utils/TestPlus.sol";

import {MockERC1155} from "./utils/mocks/MockERC1155.sol";

import {ERC1155TokenReceiver} from "../tokens/ERC1155.sol";

contract ERC1155Recipient is ERC1155TokenReceiver {
  address public operator;
  address public from;
  uint256 public id;
  uint256 public value;
  bytes public data;

  function onERC1155Received(
    address _operator,
    address _from,
    uint256 _id,
    uint256 _value,
    bytes calldata _data
  ) public virtual override returns (bytes4) {
    operator = _operator;
    from = _from;
    id = _id;
    value = _value;
    data = _data;

    return ERC1155TokenReceiver.onERC1155Received.selector;
  }

  address public batchOperator;
  address public batchFrom;
  uint256[] public batchIds;
  uint256[] public batchValues;
  bytes public batchData;

  function onERC1155BatchReceived(
    address _operator,
    address _from,
    uint256[] calldata _ids,
    uint256[] calldata _values,
    bytes calldata _data
  ) external virtual override returns (bytes4) {
    batchOperator = _operator;
    batchFrom = _from;
    batchIds = _ids;
    batchValues = _values;
    batchData = _data;

    return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
  }
}

contract RevertingERC1155Recipient is ERC1155TokenReceiver {
function onERC1155Received(
  address,
  address,
  uint256,
  uint256,
  bytes calldata
) public pure override returns (bytes4) {
  revert(string(abi.encodePacked(ERC1155TokenReceiver.onERC1155Received.selector)));
}

function onERC1155BatchReceived(
  address,
  address,
  uint256[] calldata,
  uint256[] calldata,
  bytes calldata
) external pure override returns (bytes4) {
  revert(string(abi.encodePacked(ERC1155TokenReceiver.onERC1155BatchReceived.selector)));
}
}

contract WrongReturnDataERC1155Recipient is ERC1155TokenReceiver {
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) public pure override returns (bytes4) {
    return 0x13371337;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external pure override returns (bytes4) {
    return 0x13371337;
  }
}

contract NonERC1155Recipient {}

contract ERC1155Test is TestPlus {
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

  MockERC1155 token;

  function setUp() public {
    token = new MockERC1155();
  }

  function testMintToEOA() public {
    token.mint(address(0x1337), 1337, 1, "");

    assertEq(token.balanceOf(address(0x1337), 1337), 1);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {ERC1155} from "../../../tokens/ERC1155.sol";

contract MockERC1155 is ERC1155 {
  function uri(uint256) public pure virtual override returns (string memory) {}

  function mint(
    address to,
    uint256 id,
    uint256 value,
    bytes memory data
  ) public virtual {
    _mint(to, id, value, data);
  }

  function batchMint(
    address to,
    uint256[] memory ids,
    uint256[] memory values,
    bytes memory data
  ) public virtual {
    _batchMint(to, ids, values, data);
  }

  function burn(
    address from,
    uint256 id,
    uint256 value
  ) public virtual {
    _burn(from, id, value);
  }

  function batchBurn(
    address from,
    uint256[] memory ids,
    uint256[] memory values
  ) public virtual {
    _batchBurn(from, ids, values);
  }
}

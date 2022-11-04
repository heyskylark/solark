// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract TestPlus is Test {
  function assertBytesEq(bytes memory a, bytes memory b) internal virtual {
    if (keccak256(a) != keccak256(b)) {
      emit log("Error: a == b not satisfied [bytes]");
      emit log_named_bytes("  Expected", b);
      emit log_named_bytes("    Actual", a);
      fail();
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice An implmentation of ERC-721 according to the EIP-721 specifications.
/// @author Solark (https://github.com/heyskylark/solark/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
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
                NFT METADATA STORAGE
  //////////////////////////////////////////////*/

  string public name;

  string public symbol;

  function tokenURI(uint256 _tokenId) public view virtual returns (string memory);

  /*//////////////////////////////////////////////
            BALANCE / OWNERSHIP STORAGE
  //////////////////////////////////////////////*/

  mapping(address => uint256) internal _balanceOf;

  mapping(uint256 => address) internal _ownerOf;

  function balanceOf(address _owner) public view virtual returns (uint256) {
    if (_owner == address(0)) {
      revert ZeroAddress();
    }

    return _balanceOf[_owner];
  }

  function ownerOf(uint256 _tokenId) public view virtual returns (address owner) {
    if ((owner = _ownerOf[_tokenId]) == address(0)) revert NotMinted();
  }

  /*//////////////////////////////////////////////
                OWNERSHIP STORAGE
  //////////////////////////////////////////////*/

  mapping(uint256 => address) public getApproved;

  mapping(address => mapping(address => bool)) public isApprovedForAll;

  /*//////////////////////////////////////////////
                    CONSTRUCTOR
  //////////////////////////////////////////////*/

  constructor(string memory _name, string memory _symbol) {
    name = _name;
    symbol = _symbol;
  }

  /*//////////////////////////////////////////////
                    ERC-721 LOGIC
  //////////////////////////////////////////////*/

  function transferFrom(address _from, address _to, uint256 _tokenId) public virtual {
    if (_from != ownerOf(_tokenId)) revert NotOwner();

    if (_to == address(0)) revert ZeroAddress();

    if (msg.sender != _from && msg.sender != getApproved[_tokenId] && !isApprovedForAll[_from][msg.sender])
      revert Unauthorized();

    unchecked {
      _balanceOf[_from]--;

      _balanceOf[_to]++;
    }

    _ownerOf[_tokenId] = _to;

    delete getApproved[_tokenId];

    emit Transfer(_from, _to, _tokenId);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) public virtual {
    transferFrom(_from, _to, _tokenId);

    if (
      _to.code.length != 0 &&
      ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, data) !=
      ERC721TokenReceiver.onERC721Received.selector
    ) revert UnsafeRecipient();
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public virtual {
    transferFrom(_from, _to, _tokenId);

    if (
      _to.code.length != 0 &&
      ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, "") !=
      ERC721TokenReceiver.onERC721Received.selector
    ) revert UnsafeRecipient();
  }

  function approve(address _approved, uint256 _tokenId) public virtual {
    address owner = ownerOf(_tokenId);

    if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) revert Unauthorized();

    getApproved[_tokenId] = _approved;

    emit Approval(owner, _approved, _tokenId);
  }

  function setApprovalForAll(address _operator, bool _approved) public virtual {
    isApprovedForAll[msg.sender][_operator] = _approved;

    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /*//////////////////////////////////////////////
              INTERNAL MING/BURN LOGIC
  //////////////////////////////////////////////*/

  function _mint(address _to, uint256 _tokenId) internal virtual {
    if (_to == address(0)) revert ZeroAddress();

    if (_ownerOf[_tokenId] != address(0)) revert AlreadyMinted();

    unchecked {
      _balanceOf[_to]++;
    }

    _ownerOf[_tokenId] = _to;

    emit Transfer(address(0), _to, _tokenId);
  }

  function _burn(uint256 _tokenId) internal virtual {
    address owner = ownerOf(_tokenId);

    unchecked {
      _balanceOf[owner]--;
    }

    delete getApproved[_tokenId];

    delete _ownerOf[_tokenId];

    emit Transfer(owner, address(0), _tokenId);
  }

  /*//////////////////////////////////////////////
              INTERNAL SAFE MINT LOGIC
  //////////////////////////////////////////////*/

  function _safeMint(address _to, uint256 _tokenId) internal virtual {
    _mint(_to, _tokenId);

    if (
      _to.code.length != 0 &&
      ERC721TokenReceiver(_to).onERC721Received(msg.sender, address(0), _tokenId, "") !=
      ERC721TokenReceiver.onERC721Received.selector
    ) revert UnsafeRecipient();
  }

  function _safeMint(address _to, uint256 _tokenId, bytes memory data) internal virtual {
    _mint(_to, _tokenId);

    if (
      _to.code.length != 0 &&
      ERC721TokenReceiver(_to).onERC721Received(msg.sender, address(0), _tokenId, data) !=
      ERC721TokenReceiver.onERC721Received.selector
    ) revert UnsafeRecipient();
  }

  /*//////////////////////////////////////////////
                    ERC-165 LOGIC
  //////////////////////////////////////////////*/

  function supportsInterface(bytes4 interfaceID) public view virtual returns (bool) {
    return
      interfaceID == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
      interfaceID == 0x80ac58cd || // ERC165 Interface ID for ERC721
      interfaceID == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
  }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solark (https://github.com/heyskylark/solark/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
  function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
    return ERC721TokenReceiver.onERC721Received.selector;
  }
}

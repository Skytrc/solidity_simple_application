// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./MyIERC721.sol";
import "./MyIERC165.sol";
import "./MyERC721TokenReceiver.sol";

contract MyERC721 is MyIERC721{

    string private _name;

    string private _symbol;
    
    mapping(uint256 => address) private _ownerOf;

    mapping(address => uint256) private _balanceOf;

    mapping(uint256 => address) private _approvals;

    mapping(address => mapping(address => bool)) public _operatorApprovals;

    constructor(string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
    }

    function supportInterface(bytes4 interfaceId) external pure returns (bool) {
        return 
            interfaceId == type(MyIERC721).interfaceId ||
            interfaceId == type(MyIERC165).interfaceId;
    }

    function ownerOf(uint256 tokenId)external view returns (address) {
        return _ownerOf[tokenId];
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balanceOf[owner];
    }

    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function approve(address approved, uint256 tokenId) external {
        address owner = _ownerOf[tokenId];
        require(owner == msg.sender || isApprovedForAll(owner, msg.sender), 
                "not token owner or approve for all"
        );
        _approvals[tokenId] = approved;  

        emit Approval(approved, msg.sender, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_ownerOf[tokenId] != address(0), "token doesn't exist");
        return _approvals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not a token owenr");

        _transfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) private {
        require(_ownerOf[tokenId] == from, "transfer from incorrent owner");
        require(to != address(0), "transfer to the zero address");

        _balanceOf[from] -= 1;
        _balanceOf[to] += 1;
        _ownerOf[tokenId] = to;

        delete _approvals[tokenId];
        emit Transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address operator, uint256 tokenId) internal view virtual returns (bool) {
        address owner = _ownerOf[tokenId];
        return operator == owner || isApprovedForAll(owner, operator) || getApproved(tokenId) == operator;
    } 

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        
        require(
            to.code.length == 0 ||
                MyERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) ==
                MyERC721TokenReceiver.onERC721Received.selector
        );
    }

    function mint(address to, uint256 tokenId) external virtual {
        _mint(to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "mint to the zero address");
        require(_ownerOf[tokenId] == address(0), "token already minted");

        _balanceOf[to] += 1;
        _ownerOf[tokenId] = to;
        
        emit Transfer(address(0), to, tokenId);
    }

    function burn(address from, uint256 tokenId) external virtual {
        _burn(from, tokenId);
    } 

    function _burn(address from, uint256 tokenId) internal virtual {
        address owner = _ownerOf[tokenId];
        require(from == owner, "transfer from incorrect owner");

        delete _approvals[tokenId];
        _balanceOf[owner] -= 1;
        delete _ownerOf[tokenId];

        emit Transfer(from, address(0), tokenId);
    }
}
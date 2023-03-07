// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./MyIERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./MyERC1155TokenReceiver.sol";

contract MyERC1155 is ERC165, MyIERC1155 {

    mapping(uint256 => mapping(address => uint256))private _balance;

    mapping(address => mapping(address => bool))private _operatorApprovals;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(MyIERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function safeTransferFrom(
        address from, 
        address to, 
        uint256 id, 
        uint256 amount, 
        bytes calldata data) public virtual override {
        require(from == msg.sender || isApprovedForAll(from, msg.sender), "caller is not token owner or approved");
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from, 
        address to, 
        uint256[] calldata ids, 
        uint256[] calldata amounts, 
        bytes calldata data
        ) public virtual override {
            require(msg.sender == from || isApprovedForAll(from, msg.sender), "caller is not token owner or approved");
            _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function balanceOf(address owner, uint256 id) public view virtual override returns (uint256) {
        require(owner != address(0), "address zero is not a valid owner");
        return _balance[id][owner];
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) public view virtual override returns (uint256[] memory) {
        require(owners.length == ids.length, "accounts and ids length mismatch");
        uint256[] memory batchBalances = new uint256[](owners.length);
        for(uint256 i = 0; i < owners.length; i++) {
            batchBalances[i] = balanceOf(owners[i], ids[i]);
        }

        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender, "setting approval for self");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return(_operatorApprovals[owner][operator]);
    }

    function _safeTransferFrom(
        address from, 
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "transfer to the zero address");
        uint256 fromBalance = _balance[id][from];
        require(fromBalance >= amount, "insufficient balance for transfer");

        _balance[id][from] = fromBalance - amount;
        _balance[id][to] += amount;

        require(to.code.length == 0 
            || MyERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) 
            == MyERC1155TokenReceiver.onERC1155Received.selector);

        emit TransferSingle(msg.sender, from, to, id, amount);
    }

    function _safeBatchTransferFrom(
        address from, 
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ids and amounts length mismatch");
        require(to != address(0), "transfer to the zero address");
        for(uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balance[id][from];
            require(fromBalance >= amount, "insufficient balance for transfer");
            _balance[id][from] = fromBalance - amount;
            _balance[id][to] += amount;
        }

        require(to.code.length == 0 
            || MyERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) 
            == MyERC1155TokenReceiver.onERC1155BatchReceived.selector);

        emit TransferBatch(msg.sender, from, to, ids, amounts);
    }

    function mint(address to, uint256 id, uint256 amount, bytes memory data) public virtual {
        _mint(to, id, amount, data);
    }

    function batchMint(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual {
        _batchMint(to, ids, amounts, data);
    }

    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(to != address(0), "mint to the zero address");
        _balance[id][to] += amount;

        require(to.code.length == 0 
            || MyERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) 
            == MyERC1155TokenReceiver.onERC1155Received.selector);

        emit TransferSingle(msg.sender, address(0), to, id, amount);
    }

    function _batchMint(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "mint to the zero address");
        require(ids.length == amounts.length, "ids and amounts length mismatch");
        for(uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            _balance[id][to] += amount;
        }
        require(to.code.length == 0 
            || MyERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) 
            == MyERC1155TokenReceiver.onERC1155BatchReceived.selector);
        emit TransferBatch(msg.sender, address(0), to, ids, amounts);
    }

    function burn(address from, uint256 id, uint256 amount) public virtual {
        _burn(from, id, amount);
    }

    function batchBurn(address from, uint256[] memory ids, uint256[] memory amounts) public virtual {
        _batchBurn(from, ids, amounts);
    }

    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        require(msg.sender == from || isApprovedForAll(from, msg.sender), "caller is not token owner or approved");
        uint256 fromBalance = _balance[id][from];
        require(fromBalance >= amount, "burn amount exceeds balance");

        _balance[id][from] = fromBalance - amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }

    function _batchBurn(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(ids.length == amounts.length, "ids and amounts length mismatch");
        require(msg.sender == from || isApprovedForAll(from, msg.sender), "caller is not token owner or approved");
        for(uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balance[id][from];
            require(fromBalance >= amount, "burn amount exceeds balance");

            _balance[id][from] = fromBalance - amount;
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

}
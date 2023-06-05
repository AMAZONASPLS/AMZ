// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AmazonasToken is ERC20, ERC20Burnable, Ownable {
    uint256 public constant MAX_SUPPLY = 21000000000 * (10 ** 18);
    uint256 private _burnRate = 100; // 1%
    uint256 private _charityFee = 200; // 2%
    address private _charityWallet = 0x1472D8919bAb0362c3AfCb603dD80d8755E7057B;
    uint256 private _maxTxAmount = MAX_SUPPLY / 100; // Anti-whale: 1%
    bool private _isRenounced = false;

    constructor() ERC20("AMAZONAS", "AMZ") {
        _mint(_msgSender(), MAX_SUPPLY);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _checkAmountLimits(amount);
        uint256 burnAmount = _calculateFee(amount, _burnRate);
        uint256 charityAmount = _calculateFee(amount, _charityFee);
        uint256 actualAmount = amount - burnAmount - charityAmount;

        super._burn(_msgSender(), burnAmount);
        super._transfer(_msgSender(), _charityWallet, charityAmount);
        return super.transfer(recipient, actualAmount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _checkAmountLimits(amount);
        uint256 burnAmount = _calculateFee(amount, _burnRate);
        uint256 charityAmount = _calculateFee(amount, _charityFee);
        uint256 actualAmount = amount - burnAmount - charityAmount;

        super._burn(sender, burnAmount);
        super._transfer(sender, _charityWallet, charityAmount);
        return super.transferFrom(sender, recipient, actualAmount);
    }

    function renounceOwnership() public override onlyOwner {
        require(!_isRenounced, "Ownership already renounced");
        _isRenounced = true;
        super.renounceOwnership();
    }

    function _checkAmountLimits(uint256 amount) private view {
        require(amount <= _maxTxAmount, "Transfer amount exceeds the maximum allowed");
    }

    function _calculateFee(uint256 amount, uint256 feeRate) private pure returns (uint256) {
        return amount * feeRate / 10000;
    }
}
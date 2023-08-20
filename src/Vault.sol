///SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.21;

import {IERC20, ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {IERC4626, ERC4626} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";

contract Vault is ERC4626 {

    uint8 decimalsOffset;
    constructor(address underlying) ERC20("Vault", "VLT") ERC4626(IERC20(underlying)) {}


    /* 
     * @dev This function is added for testing purpose, it shouldn't be allowed to modify the decimalOffset after initialization of the contract
    */
    function setDecimalsOffset(uint8 _decimalOffset) external {
        decimalsOffset = _decimalOffset;
    }

    function getDecimalsOffset() external view returns (uint8) {
        return _decimalsOffset();
    }
    function _decimalsOffset() internal view override returns (uint8) {
        return decimalsOffset;
    }
}

///SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.21;

import {IERC20, ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {IERC4626, ERC4626} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";

contract Vault is ERC4626 {
    constructor(address underlying) ERC20("Vault", "VLT") ERC4626(IERC20(underlying)) {}


    function _decimalsOffset() internal pure override returns (uint8) {
        return 4;
    }
}

///SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.21;

import {IERC20, ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {ERC4626, Math} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";

contract PreUpdateVault is ERC4626 {

    //As per the latest ERC4626.sol documentation states, to return to the pre-update version of the vault,
    //we must override the  `_convertToShares` and `_convertToAssets` functions
    //I went to the v4.8.3 of the repo (latest one before 4.9) to copy the functions 

    using Math for uint256;
    constructor(address underlying) ERC20("PreVault", "PREVLT") ERC4626(IERC20(underlying)) {}


    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     *
     * Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. That corresponds to a case where any asset
     * would represent an infinite amount of shares.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view override returns (uint256 shares) {
        uint256 supply = totalSupply();
        return
            (assets == 0 || supply == 0)
                ? _initialConvertToShares(assets, rounding)
                : assets.mulDiv(supply, totalAssets(), rounding);
    }

    /**
     * @dev Internal conversion function (from assets to shares) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {_initialConvertToAssets} when overriding it.
     */
    function _initialConvertToShares(
        uint256 assets,
        Math.Rounding /*rounding*/
    ) internal view virtual returns (uint256 shares) {
        return assets;
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view override returns (uint256 assets) {
        uint256 supply = totalSupply();
        return
            (supply == 0) ? _initialConvertToAssets(shares, rounding) : shares.mulDiv(totalAssets(), supply, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {_initialConvertToShares} when overriding it.
     */
    function _initialConvertToAssets(
        uint256 shares,
        Math.Rounding /*rounding*/
    ) internal view virtual returns (uint256 assets) {
        return shares;
    }


}

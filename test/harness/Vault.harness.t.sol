///SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.21;

import {IERC20, ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {IERC4626, ERC4626} from "openzeppelin-contracts/token/ERC20/extensions/ERC4626.sol";
import {Math, PreUpdateVault} from "../../src/PreUpdateVault.sol";
import {Vault} from "../../src/Vault.sol";

enum Rounding {
	Down,
	Up
}

contract PreUpdateVaultHarness is PreUpdateVault {

	using Math for uint256;

    constructor(address underlying) PreUpdateVault(underlying) {}

	function exposed__convertToShares(uint256 assets, Rounding rounding) external view returns (uint256 shares) {
		if (rounding == Rounding.Down) return _convertToShares(assets,Math.Rounding.Down);
		else return _convertToShares(assets,Math.Rounding.Up);
	}

	function exposed__convertToAssets(uint256 shares, Rounding rounding) external view returns (uint256 assets) {
		if (rounding == Rounding.Down) return _convertToAssets(shares,Math.Rounding.Down);
		else return _convertToAssets(shares,Math.Rounding.Up);
	}	
}


contract VaultHarness is Vault {

	using Math for uint256;

    constructor(address underlying) Vault(underlying) {}

	function exposed__convertToShares(uint256 assets, Rounding rounding) external view returns (uint256 shares) {
		if (rounding == Rounding.Down) return _convertToShares(assets,Math.Rounding.Down);
		else return _convertToShares(assets,Math.Rounding.Up);
	}

	function exposed__convertToAssets(uint256 shares, Rounding rounding) external view returns (uint256 assets) {
		if (rounding == Rounding.Down) return _convertToAssets(shares,Math.Rounding.Down);
		else return _convertToAssets(shares,Math.Rounding.Up);
	}	

	function exposed__decimalsOffset() external view returns (uint8) {
        return _decimalsOffset();
    }
}
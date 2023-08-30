# 4626-vaults-attack-playground
A already set-up 4626-vault project to discover existing attacks, or just play around to better understand its mechanisms

## Contracts 
- Vault : This contract implement the post-update Vault contract by Open-Zeppelin, which mitigate the [inflation attack risk](https://docs.openzeppelin.com/contracts/4.x/erc4626)
- PreUpdateVault : Modification of `_convertToShares` and `_convertToAssets` functions back to their old implementation, which is vulnerable to the inflation attack
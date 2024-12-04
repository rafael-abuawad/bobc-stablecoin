import pytest
import boa


INITIAL_BALANCE = int(100e18)


@pytest.fixture(scope="module")
def accounts():
    accounts = [boa.env.generate_address() for _ in range(10)]
    for account in accounts:
        boa.env.set_balance(account, INITIAL_BALANCE)
    return accounts


@pytest.fixture(scope="module")
def owner():
    owner = boa.env.generate_address()
    boa.env.set_balance(owner, INITIAL_BALANCE)
    return owner


@pytest.fixture(scope="module")
def asset(owner):
    with boa.env.prank(owner):
        return boa.load("contracts/token.vy", "Wrapped ETH", "WETH", 18, "wrapped-eth", "0.0.1") 


@pytest.fixture(scope="module")
def oracle(owner):
    with boa.env.prank(owner):
        return boa.load("tests/mocks/mock_v3_aggregator.vy", 8, int(2000e8)) 


@pytest.fixture(scope="module")
def stablecoin(owner):
    with boa.env.prank(owner):
        return boa.load("contracts/token.vy", "Collateralized BOB", "CBOB", 18, "collateralized-bob", "0.0.1") 


@pytest.fixture(scope="module")
def engine(stablecoin, asset, oracle, owner):
    with boa.env.prank(owner):
        engine =  boa.load("contracts/engine.vy", stablecoin, asset, oracle) 
        stablecoin.set_minter(engine, True)
        stablecoin.renounce_ownership()
        return engine

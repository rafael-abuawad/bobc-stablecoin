# pragma version ~=0.4.0
"""
@title `BOBC Engine` Overcollateralized BOBC stablecoin
@custom:contract-name engine
@license GNU Affero General Public License v3.0 only
@author rabuawad
"""

# @dev We import and implement the `IERC20` interface,
from ethereum.ercs import IERC20


# @dev We import  the `IToken` interface
from .interfaces import IToken


# @dev We import the `AggregatorV3` interface.
from .interfaces import IAggregatorV3


# @dev Returns the address of the underlying custom token
# used for the protocl.
stablecoin: public(immutable(address))


# @dev Stores the IToken interface object of the underlying
# custom token used for the protocol
_STABLECOIN: immutable(IToken)


# @dev Returns the address of the underlying oracle
# used for the protocl.
oracle: public(immutable(address))


# @dev Stores the Aggregator V3 interface object of the underlying
# oravle used for the protocol
_ORACLE: immutable(IAggregatorV3)


# @dev Maximum staletime (timeout) for the oracle,
# set to 10,800 seconds (3 hours).
TIMEOUT: constant(uint256) = 10800


# @dev Liquidation threshold; 50 means assets must be
# 200% over-collateralized to avoid liquidation.
LIQUIDATION_THRESHOLD: constant(uint256) = 50


# @dev Liquidation bonus; set to 10, allowing a 10%
# discount on assets during liquidation.
LIQUIDATION_BONUS: constant(uint256) = 10


# @dev Precision used for liquidation calculations,
# standardized at 100.
LIQUIDATION_PRECISION: constant(uint256) = 100


# @dev Minimum health factor; 1e18 indicates the
# threshold for asset health before liquidation risk.
MIN_HEALTH_FACTOR: constant(uint256) = 10**18


# @dev General calculation precision, typically
# set to 1e18 to minimize rounding errors.
PRECISION: constant(uint256) = 10**18


# @dev Additional precision for feed calculations,
# set at 1e10 for greater granularity.
ADDITIONAL_FEED_PRECISION: constant(uint256) = 10**10


# @dev Base precision for feed data, commonly set
# to 1e8 for accurate token representation.
FEED_PRECISION: constant(uint256) = 10**8


# @dev Conversion rate between 1 USD and BOB.
# @notice This constant represents the fixed conversion rate,
# where 1 USD is equivalent to 10 BOB.
CONVERSION_RATE: constant(int256) = 10


# @dev Mapping of the amount of collateral deposited
# by users
collateralDeposited: public(HashMap[address, uint256])


# @dev Mapping of the amount of BOBC minted by each user.
bobcMinted: public(HashMap[address, uint256])


# @dev Emitted when collateral is deposited by a user.
event CollateralDeposited:
    amount: indexed(address)
    user: indexed(uint256)


# @dev Emitted when collateral is redeemed.
# @notice If redeemFrom is not equal to redeemTo, it indicates a liquidation.
event CollateralRedeemed:
    redeemTo: indexed(address) 
    redeemFrom: indexed(address) 
    amount: uint256


# @dev We import and initialise the `ownable` module.
from snekmate.auth import ownable as ow
initializes: ow


# @dev We export all `external` functions
# from the `ownable` module.
exports: ow.__interface__


@deploy
@payable
def __init__(stablecoin_: IToken, oracle_: IAggregatorV3):
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    @param oracle_ The address of the Chainlink Aggregator V3 oracle contract
           used to provide price feed data for the application.
    @notice The `owner` role will be assigned to
            the `msg.sender`.
    """
    _STABLECOIN = stablecoin_
    stablecoin = _STABLECOIN.address

    _ORACLE = oracle_
    oracle = _ORACLE.address

    # The following line assigns the `owner`
    # to the `msg.sender`.
    ow.__init__()


@internal
@view
def _get_price_from_oracle() -> int256:
    roundId: uint80 = 0
    answer: int256 = 0
    startedAt: uint256 = 0
    updatedAt: uint256 = 0
    answeredInRound: uint80 = 0
    (roundId, answer, startedAt, updatedAt, answeredInRound) = staticcall _ORACLE.latestRoundData()

    assert updatedAt != 0 and answeredInRound >= roundId, "engine: stale oracle price"
    assert TIMEOUT > (block.timestamp - updatedAt), "engine: stale oracle price"
    answer *= CONVERSION_RATE

    return answer


@internal
@view
def _get_bob_value(amount: uint256) -> uint256:
    price: int256 = self._get_price_from_oracle()
    return ((convert(price, uint256) * ADDITIONAL_FEED_PRECISION) * amount) // PRECISION


@external
@view
def get_bob_value(amount: uint256) -> uint256:
    return self._get_bob_value(amount)


@internal
@view
def _get_token_amount_from_bob(amount: uint256) -> uint256:
    """
    @dev Converts a BOB amount (in Wei) to the equivalent token amount.
    Uses Chainlink price feed to fetch the token price in BOB at the current
    conversion rate.
    """
    price: int256 = self._get_price_from_oracle()
    return (amount * PRECISION) // (convert(price, uint256) * ADDITIONAL_FEED_PRECISION)


@external
@view
def get_token_amount_from_bob(amount: uint256) -> uint256:
    return self._get_token_amount_from_bob(amount)


@external
@view
def get_bobc_available(user: address) -> uint256:
    amount: uint256 = self.collateralDeposited[user] * 40 // 100
    bobc: uint256 = self._get_bob_value(amount)
    minted: uint256 = staticcall _STABLECOIN.balanceOf(user)
    return bobc - minted


@internal
@view
def _get_account_collateral_value(user: address) -> uint256:
    amount: uint256 = self.collateralDeposited[user]
    totalCollateral: uint256 = self._get_bob_value(amount)
    return totalCollateral


@external
@view
def get_account_collateral_value(user: address) -> uint256:
    return self._get_account_collateral_value(user)


@internal
@view
def _get_account_information(user: address) -> (uint256, uint256):
    minted: uint256 = self.bobcMinted[user]
    collateral: uint256 = self._get_account_collateral_value(user)
    return minted, collateral


@external
@view
def get_account_information(user: address) -> (uint256, uint256):
    return self._get_account_information(user)


@internal
@pure
def _calculate_health_factor(minted: uint256, collateral: uint256) -> uint256:
    if minted == 0:
        return max_value(uint256)
    
    collateralAdjustedForThreshold: uint256 = (collateral * LIQUIDATION_THRESHOLD) // LIQUIDATION_PRECISION
    return (collateralAdjustedForThreshold * PRECISION) // minted


@internal
@view
def _health_factor(user: address) -> uint256:
    minted: uint256 = 0
    collateral: uint256 = 0
    minted, collateral = self._get_account_information(user)
    return self._calculate_health_factor(minted, collateral)


@external
@view
def health_factor(user: address) -> uint256:
    return self._health_factor(user)


@internal
@view
def _revert_if_health_factor_is_broken(user: address):
    userHealthFactor: uint256 = self._health_factor(user)
    assert userHealthFactor >= MIN_HEALTH_FACTOR, "engine: breaks health factor"


@internal
def _deposit_collateral(amount: uint256):
    """
    @param amount The amount of collateral to deposit.
    @dev Deposits the specified collateral for the caller.
    """
    assert amount > 0, "engine: amount must be greater than zero"
    self.collateralDeposited[msg.sender] += amount
    log CollateralDeposited(msg.sender, amount)


@external
@payable
@nonreentrant
def deposit_collateral():
    self._deposit_collateral(msg.value)


@internal
def _mint_bobc(amount: uint256):
    """
    @param amount The amount of BOBC to mint.
    @dev Mints BOBC for the caller if they have sufficient collateral.
    """
    assert amount > 0, "engine: amount must be greater than zero"

    self.bobcMinted[msg.sender] += amount
    self._revert_if_health_factor_is_broken(msg.sender)

    extcall _STABLECOIN.mint(msg.sender, amount)

    
@external
@nonreentrant
def mint_bobc(amount: uint256):
    self._mint_bobc(amount)


@external
@nonreentrant
def deposit_collateral_and_mint_bobc(
    collateral: uint256, 
    amountToMint: uint256
):
    """
    @param collateral The amount of collateral to deposit.
    @param amountToMint The amount of BOBC to mint.
    @notice Deposits collateral and mints BOBC in one transaction.
    """
    self._deposit_collateral(collateral)
    self._mint_bobc(amountToMint)


@internal
def _redeem_collateral(amount: uint256, from_: address, to: address):
    self.collateralDeposited[from_] -= amount
    log CollateralRedeemed(from_, to, amount)
    send(to, amount) 


@internal
def _burn_bobc(amountToBurn: uint256, onBehalfOf: address, bobcFrom: address):
    self.bobcMinted[onBehalfOf] -= amountToBurn
    
    success: bool = extcall _STABLECOIN.transferFrom(bobcFrom, self, amountToBurn)
    assert success, "engine: tranfers failed"
    
    extcall _STABLECOIN.burn(amountToBurn)


@external
@nonreentrant
def redeem_collateral(amountCollateral: uint256):
    assert amountCollateral > 0, "engine: amount must be more than zero"
    self._redeem_collateral(amountCollateral, msg.sender, msg.sender)
    self._revert_if_health_factor_is_broken(msg.sender)


@external
def burn_bobc(amount: uint256):
    assert amount > 0, "Amount must be more than zero" 
    
    self._burn_bobc(amount, msg.sender, msg.sender)
    self._revert_if_health_factor_is_broken(msg.sender)


@external
@nonreentrant
def liquidate(user: address, debtToCover: uint256):
    """
    @dev Liquidate an insolvent user by burning BOBC and redeeming their collateral.
    @param user The user who is insolvent and has a health factor below the minimum.
    @param debtToCover The amount of BOBC to burn to cover the user's debt.
    @notice 
    Notes:
        - The liquidator receives a 10% bonus in collateral for helping liquidate.
        - The liquidation assumes the protocol is 150% overcollateralized.
        - Partial liquidation is allowed.
        - Known limitation: If the protocol is only 100% collateralized, liquidation may not work.
    """
    assert debtToCover > 0, "engine: amount must be more than zero" 

    startingUserHealthFactor: uint256 = self._health_factor(user)
    assert startingUserHealthFactor < MIN_HEALTH_FACTOR, "engine: health factor is ok"

    tokenAmountFromDebtCovered: uint256 = self._get_token_amount_from_bob(debtToCover)
    bonusCollateral: uint256 = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) // LIQUIDATION_PRECISION

    self._redeem_collateral(tokenAmountFromDebtCovered + bonusCollateral, user, msg.sender)
    self._burn_bobc(debtToCover, user, msg.sender)

    endingUserHealthFactor: uint256 = self._health_factor(user)
    assert endingUserHealthFactor > startingUserHealthFactor, "engine: health factor not improved"

    self._revert_if_health_factor_is_broken(msg.sender)


@external
@payable
def __default__():
    self._deposit_collateral(msg.value)

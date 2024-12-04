# pragma version ~=0.4.0
"""
@title Aggregator V3 Interface
@dev Interface for interacting with Chainlink's AggregatorV3,
     used for fetching price feed data.
@author chainlink
"""

# @dev We import and implement the `IERC20` interface,
from ethereum.ercs import IERC20

version: constant(uint256) = 0

# State Variables
decimals: public(uint8)
latestAnswer: public(int256)
latestTimestamp: public(uint256)
latestRound: public(uint256)

# Mappings (converted to dictionaries in Vyper)
getAnswer: HashMap[uint256, int256]
getTimestamp: HashMap[uint256, uint256]
getStartedAt: HashMap[uint256, uint256]


@deploy
@payable
def __init__(_decimals: uint8, _initialAnswer: int256):
    self.decimals = _decimals
    self._updateAnswer(_initialAnswer)


@external
@view
def latestRoundData() -> (uint80, int256, uint256, uint256, uint80):
    round_id: uint80 = convert(self.latestRound, uint80)
    answer: int256 = self.latestAnswer
    timestamp: uint256 = self.latestTimestamp
    startedAt: uint256 = self.getStartedAt[self.latestRound]
    return (round_id, answer, startedAt, timestamp, round_id)


@internal
def _updateAnswer(_answer: int256):
    self.latestAnswer = _answer
    self.latestTimestamp = block.timestamp
    self.latestRound += 1
    self.getAnswer[self.latestRound] = _answer
    self.getTimestamp[self.latestRound] = block.timestamp
    self.getStartedAt[self.latestRound] = block.timestamp


@external
def updateAnswer(_answer: int256):
    self._updateAnswer(_answer)

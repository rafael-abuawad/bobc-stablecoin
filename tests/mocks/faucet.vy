# pragma version ~=0.4.0
"""
@title Mock `WETH` Faucet 
@custom:contract-name facute
@license GNU Affero General Public License v3.0 only
@author rabuawad
"""

# @dev We import the `IToken` interface,
from ..interfaces import IToken


# @dev Returns the address of the underlying token
# used for the protocl.
asset: public(immutable(address))


# @dev Stores the ERC-20 interface object of the underlying
# token used for the protocol
_ASSET: immutable(IToken)


@deploy
def __init__(_asset: address):
    _ASSET = IToken(_asset)
    asset = _ASSET.address


@external
@nonreentrant
def mint(to: address, amount: uint256):
    extcall _ASSET.mint(to, amount)

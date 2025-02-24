## Repro

https://github.com/foundry-rs/foundry/issues/3357

_bug(forge coverage): stack too deep when using --ir-minimum and coverage report is not accurate_

Reported issues:

`--ir-minimum` disables optimizations causing stack to deep.

The limitation ultimately lies in the current implementation of our Yul->EVM transform. It's sometimes unable to produce a viable stack layout and gives up. The minimum optimizations added here (i.e. unused pruner) reduce the stack pressure, making this happen less but there are still some hard cases where this happens even with the help of the stack-to-memory mover.

This will be solved eventually, but it'll still be a while until any of the solutions land. On one hand we're working on a better Yul->EVM transform. On other the EVM is also moving towards EOF where the problem will no longer exist thanks to SWAPN/DUPN opcodes.

## Setup

Run [`./scripts/coverage.sh`](./scripts/coverage.sh)

After running you can relaunch the HTTP servers using [`./scripts/serve.sh`](./scripts/serve.sh)

## Reproduction cases

Multiple cases of lines not being hit and branches not being covered.

Haven't yet seen a false positive however.

`MorphoLib.sol`, reported 0 hits:

```
      58                 :       97831 :     function _array(bytes32 x) private pure returns (bytes32[] memory) {
      59                 :       97831 :         bytes32[] memory res = new bytes32[](1);
      60                 :       97831 :         res[0] = x;
      61                 :           0 :         return res;
      62                 :             :     }
```

`MarketParamsLib.sol`, reported 0 hits:

```
      16                 :      156257 :     function id(MarketParams memory marketParams) internal pure returns (Id marketParamsId) {
      17                 :             :         assembly ("memory-safe") {
      18                 :           0 :             marketParamsId := keccak256(marketParams, MARKET_PARAMS_BYTES_LENGTH)
      19                 :             :         }
      20                 :             :     }
      21                 :             : }
```

`UtilsLib.sol`, multiple reported 0 hits:

```
       1                 :             : // SPDX-License-Identifier: GPL-2.0-or-later
       2                 :             : pragma solidity ^0.8.0;
       3                 :             : 
       4                 :             : import {ErrorsLib} from "../libraries/ErrorsLib.sol";
       5                 :             : 
       6                 :             : /// @title UtilsLib
       7                 :             : /// @author Morpho Labs
       8                 :             : /// @custom:contact security@morpho.org
       9                 :             : /// @notice Library exposing helpers.
      10                 :             : /// @dev Inspired by https://github.com/morpho-org/morpho-utils.
      11                 :             : library UtilsLib {
      12                 :             :     /// @dev Returns true if there is exactly one zero among `x` and `y`.
      13                 :       43647 :     function exactlyOneZero(uint256 x, uint256 y) internal pure returns (bool z) {
      14                 :             :         assembly {
      15                 :           0 :             z := xor(iszero(x), iszero(y))
      16                 :             :         }
      17                 :             :     }
      18                 :             : 
      19                 :             :     /// @dev Returns the min of `x` and `y`.
      20                 :        2383 :     function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
      21                 :             :         assembly {
      22                 :           0 :             z := xor(x, mul(xor(x, y), lt(y, x)))
      23                 :             :         }
      24                 :             :     }
      25                 :             : 
      26                 :             :     /// @dev Returns `x` safely cast to uint128.
      27                 :      188307 :     function toUint128(uint256 x) internal pure returns (uint128) {
      28         [ #  # ]:      188307 :         require(x <= type(uint128).max, ErrorsLib.MAX_UINT128_EXCEEDED);
      29                 :      188307 :         return uint128(x);
      30                 :             :     }
      31                 :             : 
      32                 :             :     /// @dev Returns max(0, x - y).
      33                 :        4944 :     function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
      34                 :             :         assembly {
      35                 :           0 :             z := mul(gt(x, y), sub(x, y))
      36                 :             :         }
      37                 :             :     }
      38                 :             : }
```

`Morpho.sol`, reported 0 hit and inaccurate branch coverage 17.9% as oppposed to 98.2%


```
     544                 :       98343 :     function extSloads(bytes32[] calldata slots) external view returns (bytes32[] memory res) {
     545                 :       98343 :         uint256 nSlots = slots.length;
     546                 :             : 
     547                 :       98343 :         res = new bytes32[](nSlots);
     548                 :             : 
     549                 :       98343 :         for (uint256 i; i < nSlots;) {
     550                 :      102439 :             bytes32 slot = slots[i++];
     551                 :             : 
     552                 :             :             assembly ("memory-safe") {
     553                 :           0 :                 mstore(add(res, mul(i, 32)), sload(slot))
     554                 :             :             }
     555                 :             :         }
     556                 :             :     }
```

`ArrayLib.sol`, reported 0 hit

```
       4                 :             : library ArrayLib {
       5                 :       14428 :     function removeAll(address[] memory inputs, address removed) internal pure returns (address[] memory result) {
       6                 :       14428 :         result = new address[](inputs.length);
       7                 :             : 
       8                 :       14428 :         uint256 nbAddresses;
       9                 :       14428 :         for (uint256 i; i < inputs.length; ++i) {
      10                 :       14428 :             address input = inputs[i];
      11                 :             : 
      12            [ + ]:       14428 :             if (input != removed) {
      13                 :        7135 :                 result[nbAddresses] = input;
      14                 :        7135 :                 ++nbAddresses;
      15                 :             :             }
      16                 :             :         }
      17                 :             : 
      18                 :             :         assembly {
      19                 :           0 :             mstore(result, nbAddresses)
      20                 :             :         }
      21                 :             :     }
      22                 :             : }
```

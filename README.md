## Repro

https://github.com/foundry-rs/foundry/issues/3357

_bug(forge coverage): stack too deep when using --ir-minimum and coverage report is not accurate_

Reported issues:

`--ir-minimum` disables optimizations causing stack to deep.

The limitation ultimately lies in the current implementation of our Yul->EVM transform. It's sometimes unable to produce a viable stack layout and gives up. The minimum optimizations added here (i.e. unused pruner) reduce the stack pressure, making this happen less but there are still some hard cases where this happens even with the help of the stack-to-memory mover.

This will be solved eventually, but it'll still be a while until any of the solutions land. On one hand we're working on a better Yul->EVM transform. On other the EVM is also moving towards EOF where the problem will no longer exist thanks to SWAPN/DUPN opcodes.

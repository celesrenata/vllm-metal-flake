# Codex continuation: Apple Metal workflow

Use the existing checkout; cloud tasks are isolated. Do not create a worktree
unless requested. Preserve user changes and the current upstream pins.

## Established state

- Target host: user's Apple M5 Max, `aarch64-darwin`, macOS 15 or later.
- Flake supplies Apple SDK 15.5 and deployment target 15.0. SDK 14.4 lacks
  `MTLCompileOptions.mathMode` / `MTLMathModeSafe` required by upstream.
- Darwin configure flags downgrade only unused-variable warnings from errors.
  The pinned upstream has empty non-Linux NUMA guards; other warnings retain
  upstream's `-Werror` policy.
- Full upstream build fails at `test_kolibri1_numa` due to unconditional
  `#include <malloc.h>`. Do not treat the entire suite as passing.
- User successfully built `vllm`, `vllm-cli`, `vllm-server`,
  `test_metal_backend`, and `test_platform` on the Mac.
- User's CTest output: `test_platform` passed in 0.50s,
  `test_metal_backend` passed in 2.44s; 2/2 passed, total 2.96s.
  CTest summary does not enumerate internal device-dependent skipped cases.
- Model inference and optional MLX remain untested. Cloud is Linux and cannot
  reproduce native Metal execution. Cloud dependency installation previously
  failed because cache.nixos.org was blocked; retry after network changes.

## Resume on the Mac

If imported into another flake under input `vllm-metal` and shell `vllm-metal`,
exit the old shell, update the input, and enter the new shell:

```sh
nix flake update vllm-metal
nix develop .#vllm-metal
export VLLM_CPP_BUILD_DIR="$PWD/build-metal-sdk15"
vllm-configure
vllm-build && vllm-test
```

If working in this standalone repository, pull the latest main and use
`nix develop path:.#metal` instead. `vllm-build` now defaults to exactly the
successful Mac targets. Explicit arguments override the default.

The existing successful build is at
`/Users/celes/sources/celesrenata/vllm-metal-flake/build-metal-sdk15`.
Reuse it when working there; do not assume it exists on another machine.

## Next useful work

Verify CLI/server help and inspect the selected targets' output paths in the
existing build. Then establish a representative inference check using an
available local model compatible with upstream's native Metal backend. Inspect
local model availability and CLI help first; if none is available, ask for the
desired model or its local path. Do not download a large checkpoint by default.
Record model, invocation, expected behavior, observed output, and limitations.
Keep backend tests, model inference, and optional MLX validation distinct.

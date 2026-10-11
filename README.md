# vllm.cpp Apple Metal flake

A Nix development shell for **Apple Silicon macOS** (`aarch64-darwin`),
based on the upstream [vllm.cpp flake](https://github.com/localai-org/vllm.cpp/blob/main/flake.nix).
This builds the C++ engine's native Metal backend. It does not package the Python
vLLM project. Linux shells provide a CPU workflow for development and validation.

## Build on an Apple Silicon Mac

Install Nix with flakes enabled, then run from this repository:

```sh
nix develop path:.#metal
vllm-configure
vllm-build
vllm-test
```

The shell supplies CMake, Ninja, Python, OpenSSL, and the Darwin C++ toolchain
with its Nix-packaged Apple SDK 15 and a macOS 15 minimum deployment target.
Metal and Foundation come from that SDK. The native backend requires macOS 15+.
Upstream compiles its embedded Metal shaders at runtime, so an offline Xcode
`metal` compiler is not required. GPU execution requires an actual Metal device;
evaluation or compilation alone does not validate inference.

The default source is the upstream revision pinned in `flake.lock`. Builds go
into `build-metal` in the current directory, keeping the Nix store read-only.
On macOS, `vllm-build` defaults to the validated targets: `vllm`, `vllm-cli`,
`vllm-server`, `test_metal_backend`, and `test_platform`. Explicit arguments
override that default (for example, `vllm-build --target vllm`). The full upstream
build includes `test_kolibri1_numa`, which fails on macOS because it includes
`malloc.h`; it is not part of this default workflow. `vllm-test` runs the
existing Metal backend and platform suites, and fails if no tests are found.
Inspect test output for device-dependent skips before claiming GPU readiness.

The Darwin configure helper keeps upstream's unused-variable warnings visible
without treating them as errors: the pinned source declares empty NUMA guards
on macOS. Other warnings retain upstream's error policy.

After changing the SDK, use a new build directory to avoid cached compiler and
SDK paths from the previous shell:

```sh
export VLLM_CPP_BUILD_DIR="$PWD/build-metal-sdk15"
vllm-configure
vllm-build
vllm-test
```

For a quicker backend validation build:

```sh
vllm-build --target vllm test_metal_backend test_platform
vllm-test
```

To work on a separate upstream checkout:

```sh
export VLLM_CPP_SOURCE=/absolute/path/to/vllm.cpp
export VLLM_CPP_BUILD_DIR="$PWD/build-metal-dev"
vllm-configure
JOBS=4 vllm-build
vllm-test
```

MLX is optional and disabled by default. For an existing compatible MLX
installation containing `include/mlx/array.h` and `lib/libmlx.dylib`, opt in:

```sh
vllm-configure -DVLLM_CPP_MLX=ON -DMLX_ROOT=/absolute/path/to/mlx
```

## Linux validation

```sh
nix flake check path:. --all-systems --no-build
nix develop path:. -c vllm-configure
nix develop path:. -c vllm-build --target vllm test_backend test_platform
nix develop path:. -c vllm-test
```

Linux explicitly disables Metal and the other GPU backends, and uses `build-cpu`.
It cannot validate the macOS compiler, Apple frameworks, or Metal GPU execution.
The user validated the targeted Apple build on an M5 Max with SDK 15.5:
`test_platform` and `test_metal_backend` both passed (2/2 CTest entries, 2.96s).
This is user-reported Mac validation; cloud checks only evaluate the flake.
Model inference, MLX, and the complete upstream test suite are not validated.

See [CODEX_HANDOFF.md](CODEX_HANDOFF.md) for the session continuation context.

Update pins intentionally with `nix flake update --flake path:.`. No model download or credential
is needed for the backend tests; inference requires a compatible local model.

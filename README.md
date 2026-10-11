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
with its Nix-packaged Apple SDK. Metal and Foundation come from that SDK.
Upstream compiles its embedded Metal shaders at runtime, so an offline Xcode
`metal` compiler is not required. GPU execution requires an actual Metal device;
evaluation or compilation alone does not validate inference.

The default source is the upstream revision pinned in `flake.lock`. Builds go
into `build-metal` in the current directory, keeping the Nix store read-only.
The CLI and server are built with upstream's defaults. `vllm-test` runs the
existing Metal backend and platform suites, and fails if no tests are found.
Inspect test output for device-dependent skips before claiming GPU readiness.

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
Run the Apple commands above before treating this flake as Metal-tested.

Update pins intentionally with `nix flake update --flake path:.`. No model download or credential
is needed for the backend tests; inference requires a compatible local model.

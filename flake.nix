{
  description = "Apple Silicon Metal development environment for vllm.cpp";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    vllm-cpp = {
      url = "github:localai-org/vllm.cpp";
      flake = false;
    };
  };

  outputs = { nixpkgs, vllm-cpp, ... }:
    let
      systems = [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          metal = system == "aarch64-darwin";
          backend = if metal then "metal" else "cpu";
          configure = pkgs.writeShellApplication {
            name = "vllm-configure";
            runtimeInputs = [ pkgs.cmake pkgs.ninja ];
            text = ''
              source_dir="''${VLLM_CPP_SOURCE:-${vllm-cpp}}"
              build_dir="''${VLLM_CPP_BUILD_DIR:-build-${backend}}"
              cmake -S "$source_dir" -B "$build_dir" -G Ninja \
                -DCMAKE_BUILD_TYPE=Release \
                ${nixpkgs.lib.optionalString metal "-DCMAKE_CXX_FLAGS=-Wno-error=unused-variable"} \
                -DVLLM_CPP_METAL=${if metal then "ON" else "OFF"} \
                -DVLLM_CPP_CUDA=OFF -DVLLM_CPP_HIP=OFF \
                -DVLLM_CPP_VULKAN=OFF -DVLLM_CPP_TRITON=OFF \
                -DVLLM_CPP_MLX=OFF -DVLLM_CPP_BUILD_TESTS=ON "$@"
            '';
          };
          build = pkgs.writeShellApplication {
            name = "vllm-build";
            runtimeInputs = [ pkgs.cmake ];
            text = ''
              cmake --build "''${VLLM_CPP_BUILD_DIR:-build-${backend}}" \
                --parallel "''${JOBS:-4}" "$@"
            '';
          };
          test = pkgs.writeShellApplication {
            name = "vllm-test";
            runtimeInputs = [ pkgs.cmake ];
            text = ''
              ctest --test-dir "''${VLLM_CPP_BUILD_DIR:-build-${backend}}" \
                --no-tests=error --output-on-failure \
                -R '${if metal then "^(test_metal_backend|test_platform)$" else "^(test_backend|test_platform)$"}' "$@"
            '';
          };
          shell = pkgs.mkShell {
            packages = with pkgs; [
              bashInteractive cmake ninja git pkg-config python312
              configure build test
            ];
            buildInputs = [ pkgs.openssl ] ++ pkgs.lib.optionals metal [
              # MTLCompileOptions.mathMode first appears in macOS 15's SDK.
              pkgs.apple-sdk_15
              (pkgs.darwinMinVersionHook "15.0")
            ];
            shellHook = ''
              export OBJCXX="$CXX"
              echo "vllm.cpp ${backend} shell: vllm-configure; vllm-build; vllm-test"
            '';
          };
        in { default = shell; } // nixpkgs.lib.optionalAttrs metal { metal = shell; });
    };
}

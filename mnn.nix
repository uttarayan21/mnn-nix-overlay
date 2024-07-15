{
  pkgs,
  stdenv,
  gcc12Stdenv,
  lib,
  cmake,
  vulkan-headers,
  vulkan-loader,
  fetchFromGitHub,
  cudatoolkit,
  enableVulkan ? true,
  enableCuda ? false,
  enableOpencv ? false,
  enableOpenmp ? stdenv.isLinux,
  enableMetal ? stdenv.isDarwin,
}:
(
  if enableCuda
  then gcc12Stdenv
  else stdenv
)
.mkDerivation rec {
  pname = "mnn";
  version = "2.9.0";

  src = fetchFromGitHub {
    owner = "alibaba";
    repo = pname;
    rev = version;
    hash = "sha256-7kpErL53VHksUurTUndlBRNcCL8NRpVuargMk0EBtxA=";
  };

  # The patch is only needed when building with normal stdenv and on linux but not with gcc12Stdenv or on darwin
  patches = lib.optionals (stdenv.isLinux && !enableCuda) [
    ./patches/linux-string.patch
  ];

  cmakeFlags =
    [
      "-DMNN_USE_SYSTEM_LIB=OFF"
      "-DMNN_BUILD_CONVERTER=ON"
      "-DMNN_BUILD_SHARED_LIBS=OFF"
      "-DMNN_PORTABLE_BUILD=ON"
      "-DMNN_BUILD_TOOLS=OFF"
    ]
    ++ lib.optionals (stdenv.isDarwin && enableMetal) [
      "-DMNN_METAL=ON"
    ]
    ++ lib.optionals enableOpenmp [
      "-DMNN_OPENMP=ON"
    ]
    ++ lib.optionals enableVulkan [
      "-DMNN_VULKAN=ON"
    ]
    ++ lib.optionals enableCuda [
      "-DMNN_CUDA=ON"
    ]
    ++ lib.optionals enableOpencv [
      "-DMNN_BUILD_OPENCV=ON"
    ];

  nativeBuildInputs = [cmake] ++ lib.optionals enableCuda [cudatoolkit];
  buildInputs =
    lib.optionals enableCuda [cudatoolkit]
    ++ (
      if stdenv.isDarwin
      then
        (with pkgs.darwin.apple_sdk.frameworks;
          [
            Metal
            Foundation
            CoreGraphics
          ]
          ++ lib.optionals enableVulkan [darwin.moltenvk])
      else (lib.optionals enableVulkan [vulkan-headers vulkan-loader])
    );
}

{
  pkgs,
  stdenv,
  gcc12Stdenv,
  darwin,
  lib,
  cmake,
  vulkan-headers,
  vulkan-loader,
  fetchFromGitHub,
  cudatoolkit,
  buildPortable ? true,
  buildConverter ? false,
  buildTools ? false,
  enableVulkan ? stdenv.isLinux,
  enableCuda ? false,
  buildOpencv ? false,
  enableOpenmp ? false,
  enableMetal ? stdenv.isDarwin,
  enableAppleFramework ? false,
  enableShared ? false,
  enableSepBuild ? enableShared,
  useSystemLib ? false,
}:
(
  if enableCuda && stdenv.isDarwin
  then throw "Cuda is not supported on darwin"
  else if enableCuda
  then gcc12Stdenv
  else stdenv
)
.mkDerivation rec {
  pname = "mnn";
  version = "2.9.0";

  src = fetchFromGitHub {
    owner = "alibaba";
    repo = pname;
    # rev = version;
    # hash = "sha256-7kpErL53VHksUurTUndlBRNcCL8NRpVuargMk0EBtxA="; 2.9.0
    rev = "d9f7679db27e6beb84703b9757f48af063f48ebb";
    sha256 = "sha256-fnoCwZfnnPVZDq0irMRCD/AD0AMxRsHWGKHpuccbr48=";
  };

  # The patch is only needed when building with normal stdenv and on linux but not with gcc12Stdenv or on darwin
  # patches = lib.optionals (stdenv.isLinux && !enableCuda) [
  #   ./patches/linux-string.patch
  # ];

  cmakeFlags =
    []
    ++ lib.optionals (!useSystemLib) [
      "-DMNN_USE_SYSTEM_LIB=OFF"
    ]
    ++ lib.optionals (!enableShared) [
      "-DMNN_BUILD_SHARED_LIBS=OFF"
    ]
    ++ lib.optionals (!enableShared && !enableSepBuild) [
      "-DMNN_SEP_BUILD=OFF"
    ]
    ++ lib.optionals (enableAppleFramework && !enableSepBuild) [
      "-DMNN_AAPL_FMWK=ON"
    ]
    ++ lib.optionals (!buildTools) [
      "-DMNN_BUILD_TOOLS=OFF"
    ]
    ++ lib.optionals buildConverter [
      "-DMNN_BUILD_CONVERTER=ON"
    ]
    ++ lib.optionals buildPortable [
      "-DMNN_PORTABLE_BUILD=ON"
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
    ++ lib.optionals buildOpencv [
      "-DMNN_BUILD_OPENCV=ON"
    ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/include
    mkdir -p $out/lib
    cp -r $src/include/* $out/include
    ${lib.strings.optionalString buildConverter "mkdir -p $out/bin && cp MNNConvert $out/bin"}
    find -type f -name 'libMNN*.a' -exec cp {} $out/lib \;
    ${lib.strings.optionalString enableAppleFramework "mkdir -p $out/Frameworks && cp -r MNN.framework $out/Frameworks"}
    runHook postInstall
  '';

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

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
  buildLlm ? false,
  enableVulkan ? stdenv.isLinux,
  enableCuda ? false,
  buildOpencv ? false,
  enableOpenmp ? false,
  enableMetal ? stdenv.isDarwin,
  enableAppleFramework ? false,
  enableShared ? false,
  enableSepBuild ? enableShared,
  useSystemLib ? false,
}: let
  cmakeFlag = flag: cflag:
    "-D"
    + cflag
    + "="
    + (
      if flag
      then "ON"
      else "OFF"
    );
in
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

    patches = [
      ./patches/no_llm_demo.patch
    ];

    cmakeFlags = [
      (cmakeFlag
        useSystemLib
        "MNN_USE_SYSTEM_LIB")
      (
        cmakeFlag
        buildLlm
        "MNN_BUILD_LLM"
      )
      (
        cmakeFlag
        enableShared
        "MNN_BUILD_SHARED_LIBS"
      )
      (
        cmakeFlag
        enableSepBuild
        "MNN_SEP_BUILD"
      )
      (
        cmakeFlag
        enableAppleFramework
        "MNN_AAPL_FMWK"
      )
      (
        cmakeFlag
        buildTools
        "MNN_BUILD_TOOLS"
      )
      (
        cmakeFlag
        buildConverter
        "MNN_BUILD_CONVERTER"
      )
      (
        cmakeFlag
        buildPortable
        "MNN_PORTABLE_BUILD"
      )
      (
        cmakeFlag
        enableMetal
        "MNN_METAL"
      )
      (
        cmakeFlag
        enableOpenmp
        "MNN_OPENMP"
      )
      (
        cmakeFlag
        enableVulkan
        "MNN_VULKAN"
      )
      (
        cmakeFlag
        enableCuda
        "MNN_CUDA"
      )
      (
        cmakeFlag
        buildOpencv
        "MNN_BUILD_OPENCV"
      )
    ];

    installPhase = ''
      runHook preInstall
      cmake --build . --target install
      ${lib.strings.optionalString buildConverter "mkdir -p $out/bin && cp MNNConvert $out/bin"}
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

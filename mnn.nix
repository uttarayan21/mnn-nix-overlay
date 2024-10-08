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
  buildDiffusion ? false,
  enableVulkan ? stdenv.isLinux,
  enableCuda ? false,
  enableOpencl ? (stdenv.isLinux || stdenv.isDarwin),
  buildOpencv ? buildDiffusion,
  imgcodecs ? buildDiffusion,
  enableOpenmp ? true,
  enableMetal ? stdenv.isDarwin,
  enableAppleFramework ? false,
  enableShared ? false,
  enableSepBuild ? enableShared,
  useSystemLib ? false,
  src ?
    fetchFromGitHub {
      owner = "alibaba";
      repo = "MNN";
      # rev = version;
      # hash = "sha256-7kpErL53VHksUurTUndlBRNcCL8NRpVuargMk0EBtxA="; 2.9.0
      rev = "d9f7679db27e6beb84703b9757f48af063f48ebb";
      sha256 = "sha256-fnoCwZfnnPVZDq0irMRCD/AD0AMxRsHWGKHpuccbr48=";
    },
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
    inherit src;
    pname = "mnn";
    version = "2.9.0";

    # patches = [
    #   ./patches/no_llm_demo.patch
    # ];

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
        buildDiffusion
        "MNN_BUILD_DIFFUSION"
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
        enableOpencl
        "MNN_OPENCL"
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
      (
        cmakeFlag
        imgcodecs
        "MNN_IMGCODECS"
      )
    ];

    installPhase = ''
      runHook preInstall
      cmake --build . --target install
      ${lib.strings.optionalString buildConverter "mkdir -p $out/bin && cp MNNConvert $out/bin"}
      ${lib.strings.optionalString (buildDiffusion && buildOpencv && imgcodecs) "mkdir -p $out/bin && cp diffusion_demo $out/bin"}
      runHook postInstall
    '';

    nativeBuildInputs = [cmake] ++ lib.optionals enableCuda [cudatoolkit];
    buildInputs =
      lib.optionals enableCuda [cudatoolkit]
      ++ (
        if stdenv.isDarwin
        then
          (
            with pkgs.darwin.apple_sdk.frameworks;
              [
                Metal
                Foundation
                CoreGraphics
              ]
              ++ lib.optionals enableVulkan [darwin.moltenvk]
              ++ lib.optionals enableOpencl [pkgs.darwin.apple_sdk.frameworks.OpenCL]
          )
        else (lib.optionals enableVulkan [vulkan-headers vulkan-loader])
      );
  }

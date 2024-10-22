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
  version ? "2.9.0",
  patches ? [
  ],
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
    inherit src patches version;
    pname = "mnn";

    cmakeFlags =
      lib.attrsets.mapAttrsToList (name: value: (cmakeFlag value name))
      {
        "MNN_USE_SYSTEM_LIB" = useSystemLib;
        "MNN_BUILD_LLM" = buildLlm;
        "MNN_BUILD_DIFFUSION" = buildDiffusion;
        "MNN_BUILD_SHARED_LIBS" = enableShared;
        "MNN_SEP_BUILD" = enableSepBuild;
        "MNN_AAPL_FMWK" = enableAppleFramework;
        "MNN_OPENCL" = enableOpencl;
        "MNN_BUILD_TOOLS" = buildTools;
        "MNN_BUILD_CONVERTER" = buildConverter;
        "MNN_PORTABLE_BUILD" = buildPortable;
        "MNN_METAL" = enableMetal;
        "MNN_OPENMP" = enableOpenmp;
        "MNN_VULKAN" = enableVulkan;
        "MNN_CUDA" = enableCuda;
        "MNN_BUILD_OPENCV" = buildOpencv;
        "MNN_IMGCODECS" = imgcodecs;
      };

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

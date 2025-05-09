{ sources ? import ./nix/sources.nix }: with (import sources.nixpkgs {});
let kernel = linux_latest;
  version = "0.0.0";

  src = ./.;

  monitor-cpu = stdenv.mkDerivation {
    pname = "monitor-cpu";
    inherit version src;

    makeFlags = [
      "-C userspace"
    ];

    installPhase = ''
      runHook preInstall

      install userspace/monitor_cpu -Dm755 -t $out/bin

      runHook postInstall
    '';
  };

in
stdenv.mkDerivation {
  pname = "ryzen-smu-${kernel.version}";
  inherit version src;

  hardeningDisable = [ "pic" ];

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = [
    "TARGET=${kernel.modDirVersion}"
    "ccflags-y+=-DDEBUG"
    "KERNEL_BUILD=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  installPhase = ''
    runHook preInstall

    install ryzen_smu.ko -Dm444 -t $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/ryzen_smu
    install ${monitor-cpu}/bin/monitor_cpu -Dm755 -t $out/bin

    runHook postInstall
  '';

  meta = with lib; {
    description = "Linux kernel driver that exposes access to the SMU (System Management Unit) for certain AMD Ryzen Processors";
    homepage = "https://gitlab.com/leogx9r/ryzen_smu";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [
      Cryolitia
      phdyellow
    ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "monitor_cpu";
  };
}
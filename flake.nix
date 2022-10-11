{
  description = "A very basic flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    deploy-rs.url = "github:serokell/deploy-rs";
  };
  outputs = { self, nixpkgs, deploy-rs }: {

    nixosConfigurations = {
      blackhole =
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ({ config, pkgs, lib, modulesPath, ... }: with lib; {
              imports = [
                (modulesPath + "/installer/netboot/netboot-base.nix")
              ];
              boot.initrd.kernelModules = [ "dm-snapshot" "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
              system.build.myInit = pkgs.runCommand "init" { } ''
                mkdir -p $out
                echo -n "init=${config.system.build.toplevel}/init initrd=initrd loglevel=4" > $out/init
              '';
              system.stateVersion = "22.05";
            })
          ];
        };
      snowflake =
        let
          system = "x86_64-linux";
          overlay-lab = final: prev: {
            lab = self.packages.${prev.system};
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ({ config, pkgs, lib, modulesPath, ... }: with lib; {
              imports = [
                (modulesPath + "/installer/scan/not-detected.nix")
              ];

              boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "sd_mod" "sdhci_acpi" ];
              nixpkgs.overlays = [ overlay-lab ];
              environment.systemPackages = [ pkgs.pixiecore pkgs.lab.blackhole ];

              services.pixiecore.enable = true;
              services.pixiecore.openFirewall = true;
              services.pixiecore.debug = true;
              services.pixiecore.kernel = "${pkgs.lab.blackhole}/bzImage";
              services.pixiecore.initrd = "${pkgs.lab.blackhole}/initrd";
              services.pixiecore.cmdLine = lib.readFile "${pkgs.lab.blackhole}/init";

              services.getty.autologinUser = mkForce "root";
              system.stateVersion = "22.05";
            })
          ];
        };
    };

    packages.x86_64-linux.blackhole = nixpkgs.legacyPackages.x86_64-linux.symlinkJoin {
      name = "blackhole";
      paths = with self.nixosConfigurations.blackhole.config.system.build; [
        netbootRamdisk
        kernel
        netbootIpxeScript
        myInit
      ];
    };
  };
}

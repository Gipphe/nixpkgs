{ lib, config, pkgs, ... }:

with lib;

let
  templateSubmodule = { ... }: {
    options = {
      enable = mkEnableOption "this template";

      target = mkOption {
        description = "Path in the container";
        type = types.path;
      };
      template = mkOption {
        description = ".tpl file for rendering the target";
        type = types.path;
      };
      when = mkOption {
        description = "Events which trigger a rewrite (create, copy)";
        type = types.listOf (types.str);
      };
      properties = mkOption {
        description = "Additional properties";
        type = types.attrs;
        default = {};
      };
    };
  };

  toYAML = name: attrs: pkgs.runCommandNoCC name {
    preferLocalBuild = true;
    json = builtins.toFile "${name}.json" (builtins.toJSON attrs);
    nativeBuildInputs = [ pkgs.remarshal ];
  } "json2yaml -i $json -o $out";

  cfg = config.virtualisation.lxc;
  templates = if cfg.templates != {} then let
    list = mapAttrsToList (name: value: { inherit name; } // value)
      (filterAttrs (name: value: value.enable) cfg.templates);
  in
    {
      files = map (tpl: {
        source = tpl.template;
        target = "/templates/${tpl.name}.tpl";
      }) list;
      properties = listToAttrs (map (tpl: nameValuePair tpl.target {
        when = tpl.when;
        template = "${tpl.name}.tpl";
        properties = tpl.properties;
      }) list);
    }
  else { files = []; properties = {}; };

in
{
  imports = [
    ../profiles/docker-container.nix # FIXME, shouldn't include something from profiles/
  ];

  options = {
    virtualisation.lxc = {
      templates = mkOption {
        description = "Templates for LXD";
        type = types.attrsOf (types.submodule (templateSubmodule));
      };
    };
  };

  config = {
    system.build.metadata = pkgs.callPackage ../../lib/make-system-tarball.nix {
      contents = [
        {
          source = toYAML "metadata.yaml" {
            architecture = builtins.elemAt (builtins.match "^([a-z0-9_]+).+" (toString pkgs.system)) 0;
            creation_date = 1;
            properties = {
              description = "NixOS ${config.system.nixos.codeName} ${config.system.nixos.label} ${pkgs.system}";
              os = "nixos";
              release = "${config.system.nixos.codeName}";
            };
            templates = templates.properties;
          };
          target = "/metadata.yaml";
        }
      ] ++ templates.files;
    };

    system.build.tarball = mkForce (pkgs.callPackage ../../lib/make-system-tarball.nix {
      extraArgs = "--owner=0";

      storeContents = [
        {
          object = config.system.build.toplevel;
          symlink = "none";
        }
      ];

      contents = [
        {
          source = config.system.build.toplevel + "/init";
          target = "/sbin/init";
        }
      ];

      extraCommands = "mkdir -p proc sys dev";
    });

    # Add the overrides from lxd distrobuilder
    systemd.extraConfig = ''
      [Service]
      ProtectProc=default
      ProtectControlGroups=no
      ProtectKernelTunables=no
    '';

    # Allow the user to login as root without password.
    users.users.root.initialHashedPassword = mkOverride 150 "";

    # Some more help text.
    services.getty.helpLine =
      ''

        Log in as "root" with an empty password.
      '';

    # Containers should be light-weight, so start sshd on demand.
    services.openssh.enable = mkDefault true;
    services.openssh.startWhenNeeded = mkDefault true;

    # Allow ssh connections
    services.openssh.openFirewall = mkDefault true;
  };
}

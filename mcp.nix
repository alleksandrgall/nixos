# MCP-серверы для Claude Code и OpenCode, по проектам из ./mcp/projects.nix.
#
# В репозитории проекта не создаётся ничего: конфиг лежит в сторе, а обёртка
# над claude подставляет нужный по корню git-репозитория. Причина — .mcp.json
# и .claude/settings.json в рабочих репах уже под гитом, класть туда своё нельзя.
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  localUser = import ./user.nix;
  localName = localUser.name;

  mkServers = import ./mcp/servers.nix { inherit pkgs lib config inputs; };
  projects = import ./mcp/projects.nix;

  projectDir = dir: "${localUser.home}/${dir}";

  mkMcpJson =
    dir: names:
    pkgs.writeText "mcp-${builtins.replaceStrings [ "/" ] [ "-" ] dir}.json" (
      builtins.toJSON { mcpServers = lib.getAttrs names (mkServers (projectDir dir) "claude-code"); }
    );

  mkOpenCodeJson =
    dir: names:
    pkgs.writeText "opencode-mcp-${builtins.replaceStrings [ "/" ] [ "-" ] dir}.json" (
      builtins.toJSON {
        mcp = lib.mapAttrs (_: server: {
          type = "local";
          command = [ server.command ] ++ (server.args or [ ]);
        }) (lib.getAttrs names (mkServers (projectDir dir) "ide"));
      }
    );

  # Сопоставление корня репозитория с его конфигом.
  dispatch = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      dir: names: ''    ${lib.escapeShellArg (projectDir dir)}) cfg=${mkMcpJson dir names} ;;''
    ) projects
  );

  openCodeDispatch = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      dir: names: ''    ${lib.escapeShellArg (projectDir dir)}) cfg=${mkOpenCodeJson dir names} ;;''
    ) projects
  );

  claude-wrapped = pkgs.writeShellApplication {
    name = "claude";
    runtimeInputs = [ pkgs.git ];
    text = ''
      # Запуск из подкаталога проекта должен давать тот же конфиг, отсюда git rev-parse.
      root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
      [[ -n "$root" ]] || root="$PWD"

      cfg=""
      case "$root" in
      ${dispatch}
      esac

      if [[ -n "$cfg" ]]; then
        exec ${pkgs.claude-code}/bin/claude --mcp-config "$cfg" "$@"
      fi

      exec ${pkgs.claude-code}/bin/claude "$@"
    '';
  };

  opencode-wrapped = pkgs.writeShellApplication {
    name = "opencode";
    runtimeInputs = [ pkgs.git ];
    text = ''
      root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
      [[ -n "$root" ]] || root="$PWD"

      cfg=""
      case "$root" in
      ${openCodeDispatch}
      esac

      if [[ -n "$cfg" ]]; then
        export OPENCODE_CONFIG="$cfg"
      fi

      export OPENCODE_EXPERIMENTAL_LSP_TOOL=true
      exec ${inputs.opencode-flake.packages.${pkgs.system}.default}/bin/opencode "$@"
    '';
  };
in
{
  sops.defaultSopsFile = ./secrets/secrets.yaml;
  # Ssh host-ключей на этой машине нет, поэтому дефолтный sshKeyPaths не сработает.
  # Файл кладётся руками: sudo install -Dm600 ~/.config/sops/age/keys.txt <путь>
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  sops.secrets = lib.genAttrs [
    "gitlab-personal-access-token"
    "perplexity-token"
    "grafana-mcp-service-account-token"
  ] (_: {
    owner = localName;
    mode = "0400";
  });

  home-manager.users.${localName}.home.packages = [ claude-wrapped opencode-wrapped ];
}

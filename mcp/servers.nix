# Реестр MCP-серверов. Единственное место, где сервер описывается.
# Выбор серверов по проектам — в ./projects.nix.
#
# Результат — функция от абсолютного пути проекта: некоторым серверам
# (serena) нужно знать, какой проект открывать.
{
  pkgs,
  lib,
  config,
  inputs,
}:
let
  # Секреты расшифровываются sops-nix в /run/secrets/<name> при активации.
  # В nix store попадает только путь, не содержимое.
  secretPath = name: config.sops.secrets.${name}.path;

  # Обёртка, читающая токен из файла в рантайме и пробрасывающая его в env.
  mkTokenServer =
    {
      name,
      secret,
      envVar,
      extraEnv ? { },
      command,
    }:
    pkgs.writeShellApplication {
      inherit name;
      text = ''
        token_file=${lib.escapeShellArg (secretPath secret)}

        if [[ ! -r "$token_file" ]]; then
          echo "${name}: не удаётся прочитать токен: $token_file" >&2
          exit 1
        fi

        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (k: v: "export ${k}=${lib.escapeShellArg v}") extraEnv
        )}

        export ${envVar}
        ${envVar}="$(<"$token_file")"

        exec ${lib.removeSuffix "\n" command} "$@"
      '';
    };

  mcp-gitlab = mkTokenServer {
    name = "mcp-gitlab";
    secret = "gitlab-personal-access-token";
    envVar = "GITLAB_PERSONAL_ACCESS_TOKEN";
    extraEnv = {
      GITLAB_API_URL = "https://gl.getshop.tv/api/v4";
      GITLAB_READ_ONLY_MODE = "false";
    };
    # npx тянет пакет из сети при каждом старте — единственный
    # невоспроизводимый кусок здесь, в nixpkgs этого сервера нет.
    command = "${pkgs.nodejs}/bin/npx --yes @zereight/mcp-gitlab";
  };

  mcp-perplexity = mkTokenServer {
    name = "mcp-perplexity";
    secret = "perplexity-token";
    envVar = "PERPLEXITY_API_KEY";
    command = "${pkgs.perplexity-mcp}/bin/perplexity-mcp";
  };

  mcp-grafana = mkTokenServer {
    name = "mcp-grafana";
    secret = "grafana-mcp-service-account-token";
    envVar = "GRAFANA_SERVICE_ACCOUNT_TOKEN";
    extraEnv.GRAFANA_URL = "https://grafana.getads.ru/";
    command = ''
      ${pkgs.mcp-grafana}/bin/mcp-grafana -t stdio \
        --enabled-tools "search,datasource,incident,prometheus,loki,alerting,dashboard,folder,oncall,asserts,sift,pyroscope,navigation,proxied,annotations,rendering,plugin,api,clickhouse"
    '';
  };

  localHome = (import ../user.nix).home;

  serena = inputs.serena.packages.${pkgs.system}.serena;
in
projectDir: {
  gitlab = {
    command = "${mcp-gitlab}/bin/mcp-gitlab";
  };

  perplexity = {
    command = "${mcp-perplexity}/bin/mcp-perplexity";
  };

  grafana = {
    command = "${mcp-grafana}/bin/mcp-grafana";
  };

  playwright = {
    # Пакет сам подкладывает PLAYWRIGHT_BROWSERS_PATH, браузеры доставать не надо.
    command = "${pkgs.playwright-mcp}/bin/playwright-mcp";
    args = [
      # .mcp.json раскрывает ${VAR:-default}, но не вложенный $HOME внутри default,
      # поэтому путь абсолютный.
      "--user-data-dir"
      "${localHome}/.local/state/playwright-mcp"
      "--no-sandbox"
    ];
  };

  serena = {
    command = "${serena}/bin/serena";
    args = [
      "start-mcp-server"
      "--context"
      "claude-code" # дефолт desktop-app — не тот профиль инструментов
      "--project"
      projectDir
    ];
  };
}

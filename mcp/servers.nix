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

  serenaEnv = inputs.serena.packages.${pkgs.system}.serena-env;
  serenaHaskell = pkgs.runCommand "serena-haskell-no-project-check" { } ''
    mkdir -p "$out"
    cp -rL ${serenaEnv}/lib/python3.11/site-packages/solidlsp "$out/solidlsp"
    chmod -R u+w "$out"
    substituteInPlace "$out/solidlsp/language_servers/haskell_language_server.py" \
      --replace-fail '"checkProject": True' '"checkProject": False'
    substituteInPlace "$out/solidlsp/language_servers/haskell_language_server.py" \
      --replace-fail 'from solidlsp.ls import SolidLanguageServer' 'from solidlsp import ls_types
    from solidlsp.ls import SolidLanguageServer'
    substituteInPlace "$out/solidlsp/language_servers/haskell_language_server.py" \
      --replace-fail '    def _create_base_initialize_params(self) -> dict:' '
        @override
        def _supports_pull_diagnostics(self) -> bool:
            return False

        @override
        def _get_published_diagnostics_wait_timeout(self, pull_diagnostics_failed: bool) -> float:
            return 30.0

        @override
        def _accept_published_diagnostics(self, diagnostics: list[ls_types.Diagnostic]) -> bool:
            return True

        @override
        def _wait_for_relevant_published_diagnostics(
            self, uri: str, after_generation: int, timeout: float, allow_cached: bool = True
        ) -> list[ls_types.Diagnostic] | None:
            # An old publication must not be mistaken for diagnostics of a changed file.
            diagnostics = super()._wait_for_relevant_published_diagnostics(
                uri, after_generation, timeout, allow_cached=False
            )
            if diagnostics is None:
                raise TimeoutError("Timed out waiting for HLS diagnostics")
            return diagnostics

        @override
        def request_text_document_diagnostics(
            self, relative_file_path: str, start_line: int = 0, end_line: int = -1, min_severity: int = 4
        ) -> list[ls_types.Diagnostic]:
            mtime = os.stat(os.path.join(self.repository_root_path, relative_file_path)).st_mtime_ns
            checked = getattr(self, "_diagnostic_mtimes", {})
            if checked.get(relative_file_path) == mtime:
                cached = self.get_cached_published_text_document_diagnostics(
                    relative_file_path, start_line, end_line, min_severity
                )
                if cached is not None:
                    return cached
            result = super().request_text_document_diagnostics(relative_file_path, start_line, end_line, min_severity)
            checked[relative_file_path] = mtime
            self._diagnostic_mtimes = checked
            return result

        def _create_base_initialize_params(self) -> dict:'
  '';
  serena = pkgs.writeShellScriptBin "serena" ''
    export PYTHONPATH="${serenaHaskell}''${PYTHONPATH:+:$PYTHONPATH}"
    exec ${inputs.serena.packages.${pkgs.system}.serena}/bin/serena "$@"
  '';
in
projectDir: context: {
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
      context # дефолт desktop-app — не тот профиль инструментов
      "--project"
      projectDir
    ];
  };
}

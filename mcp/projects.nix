# Какому проекту какие MCP-серверы. Путь — относительно $HOME.
# Имена серверов берутся из ./servers.nix; опечатка роняет eval, а не рантайм.
#
# Единственный файл, который правится при добавлении проекта.
let
  getshop = [
    "gitlab"
    "grafana"
    "serena"
  ];
in
{
  "nixos" = [ "serena" ];

  "adserver" = getshop;
  "adserver-wip" = getshop;
  "mist" = getshop;
  "mist-wip" = getshop;
  "lynx" = getshop;
}

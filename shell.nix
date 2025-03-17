# Virtual environment for HighestBidder Elixir/Phoenix development
#
#

{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "crucible-env";
  buildInputs = with pkgs; [
    docker
    elixir_1_18
    inotify-tools
    git
    wget
    htop
    sysstat
    direnv
    nixpkgs-fmt
    gcc
    zip
    bat
    gh
    inetutils
  ];

  shellHook = ''
    #
    # Source ENVVARs
    source .env
    #
    #docker compose -f ./shell.compose.yml build
    #docker compose -f ./shell.compose.yml up -d
    #
    # Move to code src
    cd ./src
    mix Deps.get
    #
    echo -e "\n"
    echo -e "\033[0;34mWelcome to Nix-shell development environment for Crucible!\e[0m"
    echo "Run 'iex -S mix phx.server' to start the Phoenix server."
    echo "Then run ':observer.start()', if you want to start observer."
    #
    #
    # holds user session to kill docker containers on closure.
    #nix-shell ./zzz.hold-shell.nix
    #
    #echo -e "\033[0;31mKilling Development containers:\e[0m"
    #docker compose -f ../shell.compose.yml down
    #exit
  '';
}

# Virtual environment for HighestBidder Elixir/Phoenix development
#
#

{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "crucible-env";
}
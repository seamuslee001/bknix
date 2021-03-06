/**
 * The `max` list identifies the highest recommended versions of the system requirements.
 *
 * We rely on a mix of packages from Nix upstream v18.09 (`pkgs`) and custom forks (`bkpkgs`).
 */
let
    pkgs = import (import ../../pins/18.09.nix) {};
    bkpkgs = import ../../pkgs;
in [
    /* Custom programs */
    bkpkgs.launcher

    /* Major services */
    bkpkgs.php73
    pkgs.nodejs-8_x
    pkgs.apacheHttpd
    pkgs.memcached
    pkgs.mysql57
    pkgs.redis

    /* CLI utilities */
    pkgs.bzip2
    pkgs.curl
    pkgs.git
    pkgs.gitAndTools.hub
    pkgs.gnugrep
    pkgs.gnutar
    pkgs.hostname
    pkgs.ncurses
    pkgs.patch
    pkgs.rsync
    pkgs.unzip
    pkgs.which
    pkgs.zip
    bkpkgs.transifexClient
]

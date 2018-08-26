`bknix` is a highly opinionated environment for developing in PHP/JS -- esp for developing patches/add-ons for CiviCRM.

__Comparison with other development environments__: `bknix` serves a function similar to MAMP or XAMPP -- it facilitates local development by
bundling Apache/PHP/etc with a small launcher to run the servers.  However, it is built with the open-source [nix package
manager](https://nixos.org/nix) (compatible with OS X and Linux).  Like Docker, `nix` lets you create a small project with a manifest-file, and it
won't interfere with your normal system settings.  However, unlike Docker, it is not coupled to the Linux kernel.  This significantly improves
performance on OS X workstations -- especially if the PHP/JS codebase is large.

__Highly opinionated__:

 * It is primarily intended for developing patches and extensions for CiviCRM -- this influences the set of tools included.
 * It combines service binaries (`mysqld`, `httpd`, etc) from [nix](https://nixos.org/nix) and a toolchain from [buildkit](https://github.com/civicrm/civicrm-buildkit) and an unsophisticated process-management script (`bknix`).
 * To facilitate quick development with any IDE/editor, all file-storage and development-tasks run in the current users' local Linux/macOS (*without* any virtualization, containerization, invisible filesystems, or magic permissions).
 * To optimize DB performance, `mysqld` stores all its data in a ramdisk.
 * To avoid conflicts with other tools on your system, all binaries are stored in their own folders, and services run on their own ports.

__This project is a work-in-progress.__ Some tasks/issues are described further down.

## Requirements

The system should meet two basic requirement:

* Run Linux or OS X on the local workstation
* Install the [nix package manager](https://nixos.org/nix/)

Additionally, you should have some basic understanding of the tools/systems involved:

* Git
* PHP/JS development (e.g. `composer`, `npm`)
* Unix CLI (e.g. `bash`)
* Process management (e.g. `ps`, `kill`), esp for `httpd` and `mysqld`
* Filesystem management (e.g. "Disk Utility" on OSX; `umount` on Linux)

## Tutorial: Download

After installing [nix package manager](https://nixos.org/nix/), simply clone this repo:

```
git clone https://github.com/totten/bknix
```

## Tutorial: Service startup

We need to start various servers (Apache, PHP-FPM, etc). This command will run the services in the foreground and display a combined console log.

```

me@localhost:~$ cd bknix
me@localhost:~/bknix$ nix-shell --command 'bknix run'
...
[apache] Starting
[php-fpm] Starting
[redis] Starting
...
```

__Note__: If this is the first time that you run `nix-shell` command, then the local computer needs to download or compile some software. This is
handled automatically. It may take a while the first time -- but, eventually, it ends at the same point.

## Tutorial: Command line access

We'd like to have a shell where we can run developer commands like `civibuild`, `composer`, `drush`, or `civix`.  Open a new terminal and run `nix-shell` without any arguments:

```
me@localhost:~$ cd bknix
me@localhost:~/bknix$ nix-shell
[nix-shell:~/bknix]$
```

Within the `nix-shell`, you have access to all commands.  For example, you can use one of these commands to create a dev site:

```
[nix-shell:~/bknix]$ civibuild create dmaster
[nix-shell:~/bknix]$ civibuild create wpmaster
```

In the dev site, you can browse the site, edit code, etc.

## Tutorial: Shutdown and restart services

Eventually, you may need to shutdown or restart the services. Here's how:

* *To shutdown Apache, PHP, and Redis*: Go back to the original terminal where `bknix run` is running. Press `Ctrl-C` to stop it.
* *To shutdown MySQL*: Run `killall mysqld`. Then, use `umount` (Linux) or `Disk Utility` (OS X) to eject the ramdisk.

You can start Apache/PHP/Redis again by simply invoking the `bknix run` command again.

Restarting MySQL is a bit more tricky -- all the databases were lost when the ramdisk was destroyed. You can restore
the databases to a pristine snapshot with `civibuild restore` or `civibuild reinstall` -- either:

```
[nix-shell:~/bknix]$ civibuild restore dmaster
[nix-shell:~/bknix]$ civibuild reinstall dmaster
```

## Policies/Opinions

* A "build" is a collection of PHP/JS/CSS/etc source-code projects, with a database and an HTTP virtual host. You can edit/commit directly in the source-tree.
* All builds are stored in the `build` folder.
* All builds are given the URL `http://<name>.bknix:8001`. (Changeable)
* All hostnames are registered in `/etc/hosts` using `sudo`. (Changeable)
* All services run as the current, logged-in user. This means that files require no special permissions.
* MySQL launches on-demand with all-ram-disk-based storage, and it listens on TCP port 3307. (Launching is triggered when calling `amp create`, `civibuild create`, `civibuild reinstall`, `civibuild restore`, or similar).
* PHP enables `xdebug`, which connects to a debugger UI on port 9000. (Changeable)
* PHP is serviced by `php-fpm`, which listens on TCP port 9009.
* Redis runs on TCP port 6380.
* Memcached (if enabled) runs on TCP port 12221.

Some of these policies/opinions can be changed, as described below ("Extended installation")

## TODO/Issues

* Sort out php-imap
* Make it easier to switch between php56, php70, php71. (Currently, you need to search/replace in `default.nix`.)
* Instead of putting most code in `./civicrm-buildkit`, put it in `$out`. (Preferrably... without neutering git cache.)
* `mysqld` is spawned in the background via `amp` (b/c that has the automated ramdisk handling). However, it'd be conceptually cleaner
  to launch `mysqld` in the foreground via `bknix run`.

## Tips

* To run Civi unit tests with xdebug in PHPStorm...
    * Lookup and register the PHP interpreter.
        * In CLI, run `nix-shell` and `which php`.
        * In PHPStorm, open "Preferences" and find list of PHP interpreters. Register this one.
    * Lookup and register the PATH.
        * In CLI, run `nix-shell` and `echo $PATH`.
        * In PHPStorm, open "Run => Edit Configurations". For the default PHPUnit, add an environment variable `PATH` with the given value.
        * If there are active PHPUnit configurations, update them or delete them (so they can be regenerated on-demand).
    * In the future -- whenever you upgrade the PHP runtime -- you may need to update these settings.
* If you don't already have `git` on your system, patch `default.nix` and add it to the list of `buildInputs`.
  However, if you already have it, then leave the default. (This would prevent potential concerns about different programs managing the same `.git` folders.)
* To open a MySQL command prompt with admin credentials, run `amp sql -a`.
* If you're doing development on the bknix initialization process, use `bknix purge` to produce a clean folder (without any data or config).
* When you shutdown, the mysql ramdisk remains in memory. To remove or reset it, unmount it with `umount` (in Linux) or *Disk Utility* (in OS X).

## Extended installation

Some of the policies/opinions are amenable to customization. If you were
setting up a clean build with some customizations, the flow would look
generally like this;

```bash
## 1. Setup a clean environment
git clone https://github.com/totten/bknix
cd bknix
nix-shell

## 2. Initialize default configuration
bknix init

## 3. Alter the configuration, e.g.
amp config
less civicrm-buildkit/app/civibuild.conf.tmpl
vi civicrm-buildkit/app/civibuild.conf

## 4. Run services
bknix run
```

Note how we interject with steps 2 and 3. For example, I often do these around step #3:

* Set a default `ADMIN_PASS` for new websites by editing `civicrm-buildkit/app/civibuild.conf`. This way you don't
  need to lookup random passwords for each build.
* Setup wildcard DNS for `*.bknix` using `dnsmasq`.  (Search for instructions for installing `dnsmasq` on your
  platform.) Then, configure `amp` to disable management of `/etc/hosts` (`amp config:set --hosts_type=none`).
  This saves you from running `sudo` or entering a password.
* Set the PHP timezone in `config/php.ini`.
* Create `config/bashrc.local` with some CLI customizations

(*Aside*: You can update these settings after initial setup, but some settings may require destroying/rebuilding.)

## Updates

There are a few levels of updates. They run a spectrum from regular (daily)
to irregular (once every months).

* (*Most frequent; perhaps every day*) *Update the CiviCRM source*: See [CiviCRM Developer Guide: civibuild](https://docs.civicrm.org/dev/en/latest/tools/civibuild/#upgrade-site)
* (*Mid-level; perhaps every couple weeks*) *Update buildkit's CLI tools*: Run `bknix update`.
* (*Least frequent; perhaps every couple months*) *Update the full `bknix` stack (mysqld/httpd/etc)*: This takes a few steps.
    * If you haven't already, shutdown any active services (`Ctrl-C` in the background terminal)
    * Exit any active `nix-shell` environments.
    * In the `bknix` directory, update the git repo (i.e. `git pull`).
    * Open a new `nix-shell` and run `bknix update`
    * If you have an IDE configuration which references the PHP interpreter or PATH, update the IDE.

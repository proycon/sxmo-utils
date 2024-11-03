sxmo_migrate.sh(1)

# NAME

sxmo_migrate.sh - migration tool for sxmo

# SYNOPSIS
	
*sxmo_migrate.sh* [subcommands...]

# SUBCOMMANDS

*reset*
	Reverts *all* your configuration files and hooks to the default. Be careful with this one.
	This is intended as a last resort if you end up with a broken system.
	All your configuration files will moved out of the way and
	flagged for migration then.

*state*
	Reports whether there are any configuration files/hooks pending migration.

*sync*
	Triggers a check of the versions of your configuration files and hooks.
	It runs automatically when Sxmo starts.

*sync state*
	Use this combination after you just finished a migration but didn't restart the
	system yet

# DESCRIPTION

While developing sxmo, we will regularly update certain configuration files
such as the xinit/sway template, the hooks or whatever. These files are
typically a mixture of changes by us and customizations by the user. This
mixture gives the user maximum flexibility to adapt Sxmo to their liking.
However, when we update such files, the challenge is to ensure that user
modifications can be easily merged back in again. Moreover, we must ensure the
system is never in a broken state because of outdated configurations and
version mismatches.

Whenever your configuration files are out-of-date when starting Sxmo, they will
be moved aside (i.e. renamed with *.needs-revision* extension) and the default
configuration will take its place. This ensures that the system always remains
functional and no conflicts should arise. A red notification will pop up
telling you have configuration files that need to be migrated. This migration
is done by running a script named _sxmo_migrate_(1). This script can simply be
launched from the configuration menu or via ssh (recommended). It first shows
the differences between your configuration and the new default, and allows you
to edit and apply your configuration accordingly. _sxmo_migrate_(1) uses
*$DIFFTOOL* to help you merge your changes. By default $DIFFTOOL is set to
*vimdiff*.

If you have any pending migrations, always make sure to complete the migration
process before making any new changes to your configuration. It is also
recommended to keep your configuration under version control (e.g. git).

# TECHNICAL DETAILS

Sxmo uses explicitly versioned configuration files, meaning
that they each carry a simple version hash unique to the file.
This version hash is expressed in a comment in the file itself, such as:

```
# configversion: d8aaf01c9489793bda3686ef23b2b192
```

You should *only* update this version hash when *sxmo_migrate.sh*
prompts you to do so by showing a diff of a newer configversion hash.

##  RESOLVING SYSTEM CONFIGURATIONS ON SYSTEM UPGRADE AND MAKE 

_apk_(1), on postmarketOS, will install new configs as *.apk-new* on upgrades if you
have modified the original config in */etc*. Moreover, when hacking on Sxmo,
you will often run *make install* and this may _modify_ a config in */etc* from
apk's perspective. You can merge apk's config changes by running *doas
update-conf*. You can also run *apk audit* to list all the files that have
changed from what apk originally installed.

SEE ALSO: _sxmo_migrate_(1)

# SEE ALSO

_sxmo_(7)

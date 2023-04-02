*Update migrations*

While developing sxmo, we will regularly update certain configuration
files such as the xinit/sway template, the hooks or whatever. These
files are typically a mixture of changes by us and customizations by
the user. This mixture gives the user maximum flexibility to adapt Sxmo
to their liking. However, when we update such files, the challenge is
to ensure that user modifications can be easily merged back in again.
Moreover, we must ensure the system is never in a broken state because
of outdated configurations and version mismatches.

Whenever your configuration files are out-of-date when starting Sxmo,
they will be moved aside (i.e. renamed with *.needs-revision* extension)
and the default configuration will take its place. A red notification
will pop up telling you have configuration files that need to be
migrated. This migration is done by running a script named
_sxmo_migrate_(1). This script can simply be launched from the
configuration menu or via ssh (recommended).
It first shows the differences between your configuration and the new
default, and allows you to edit and apply your configuration accordingly.
_sxmo_migrate_(1) use *$DIFFTOOL* to help you merge your changes. By default
$DIFFTOOL is set to *vimdiff*.

If you have any pending migrations, always make sure to complete the
migration process before making any new changes to your configuration.
It is also recommended to keep your configuration under version control
(e.g. git).

*Techical details*:

Sxmo (since 1.8.1) uses explicitly versioned configuration files, meaning
that they each carry a simple version hash unique to the file.
This version hash is expressed in a comment in the file itself, such as:

```
# configversion: d8aaf01c9489793bda3686ef23b2b192
```

You should *only* update this version hash when *sxmo_migrate.sh*
prompts you to do so by showing a diff of a newer configversion hash.

If you want to see what files are disabled and need migration, run
*sxmo_migrate.sh state*, or run *sxmo_migrate.sh sync state* if
you just performed an upgrade and haven't restarted yet. If you want to
revert *all* your configuration files to the default, then you can
run *sxmo_migrate.sh reset*. This is usually a last resort if you
end up with a broken system and can be considered a kind of factory
reset, all your configuration files will moved out of the way and
flagged for migration then.

The process that checks the versions of your configuration files is
*sxmo_migrate.sh sync*, it runs automatically when Sxmo starts.

*Resolving system configs on system upgrade and make*

Apk will install new configs as
*.apk-new* on upgrades if you have modified the original config in */etc*.
Moreover, when hacking on Sxmo, you will often run `make install`and this may "modify" 
a config in /etc from apk's perspective.
You can merge apk's config changes by running `doas update-conf`. You can also run `apk audit` 
to list all the files that have changed from what apk originally installed.

SEE ALSO: _sxmo_migrate_(1)



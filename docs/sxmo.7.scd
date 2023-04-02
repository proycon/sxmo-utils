sxmo(7)

# NAME

sxmo - a simple X mobile operating system

# DESCRIPTION

*sxmo* is a collection of simple and suckless programs and scripts used together
to create a fully functional mobile user interface adhering to the Unix philosophy. We focus
on Linux smartphones such as the Pinephone. Sxmo is primarily written in POSIX
shell scripts and can be easily modified and extended using our hook system.

Sxmo >= 1.6.0 runs both on Xorg (using dwm) as well as on Wayland (using sway).
The X in our name historically referred to Xorg, but is now open to whatever
interpretation you prefer (eXtensible, eXcellent, eXperimental, etc...)

A brief overview of Sxmo's features:

- *Hardware buttons action*: press hardware buttons different number of times
  for different actions (like launching terminals, browsers, and window
  management)
- *Swipe gestures*: (via _lisgd_(1)) move between workspaces, move windows between
  workspaces, and raise/lower volume via swipe gestures
- *Menu interfaces*: (via _bemenu_(1) or _dmenu_(1)) use the Pinephone hardware buttons to
  select menu entries (e.g. volume up/volume down/select translates to
  previous/next/select)
- *Onscreen keyboard*: (via _svkbd_(1) or _wvkbd_(1)) Multiple layer responsive onscreen
  keyboard that autoadjusts WM space
- *Window Managment*: (via _sway_(1) or _dwm_(1)) Arrange windows (in classic dwm layouts
  like monocle, tile, and bstack), kill clients, and cycle window focus using
  Pinephone buttons
- *Calls & Texting*: (via _mmcli_(1) and _mmsdtng_(1)) Compose texts,
  send group texts and add attachments, read texts, make and receive 
  calls.
- *Incoming Text/Call notifications*: (via _sxmo_notifications_(1)) Vibrate phone & blink led
  when there is an incoming call/text
- *Lock Screen*: (via custom script) Disable screen input, toggle screen on/off
  for listening to music / pocket use, automatic deep sleep when idle
- *Menu Scripts*: Web Search, Files, Countdown Timer, Youtube audio and video
  (mpv-based), Weather, RSS
- *Web browser*: (e.g. firefox) Browse the web while saving screenspace and
  includes Pinephone buttons (via dmenu) based link-following
- *Terminal*: (via foot or st) Excellent terminal support with scrollback,
  copy-paste, and color invert
- *Camera* (via megapixels) Take photos and videos
- *System-menus*: Control Volume, Brightness, Wifi, Logout, Modem Info,
  Launching Apps, and more
- *Application-specific context menus*: Increase font-size, zoom, paste, on
  per-application level via dmenu scripts
- *Auto Login*: (via _tinydm_(1))
- *SSH as a first class citizen*: Log into your phone over ssh and have full
  access to all sxmo menus and functionality.
- *Alpine Linux / PmOS Based Images*: postmarketOS's infrastructure bakes
  images that bundle Sxmo and pmOS (based on Alpine Linux) which keeps things
  small, simple, and pragmatic

Sxmo 1.4.1 was presented at AlpineConf 2021, you can watch the video.

A screenshot of the interface: TODO

# INTERFACE \& BASICS

After login, you will be presented the SXMO interface as follows:

![screenshot](assets/screenshot.jpg)

Sxmo runs on either X11 or Wayland, with different but very similar software to
make it possible. You may switch between the two environment via the *Toggle WM*
option in the *Power* menu (provided you have both installed).

Regardless of the environment you use Sxmo consists in a large set of POSIX
shell scripts that glue all these tools together. All these shell scripts comply
to the pattern *sxmo_\*.sh* and can be found in your */usr/bin/* directory. A
lot of functionality is also contained in hooks *sxmo_hook_\*.sh* and can be found in
*/usr/share/sxmo/default_hooks/* or *~/.config/sxmo/hooks/*.

Note that sxmo respects the xdg specification, e.g., $XDG_CACHE_HOME,
$XDG_CONFIG_HOME, etc.

## STATUSBAR

The statusbar relies upon _sxmobar_(1). It has space for the following information 
(from left to right) has icons for:
- The current and active workspace(s) (in the form of numbers). You can tap these to switch to them.
- The title of the active window (if any).
- GSM modem state icon (i.e., what state modemmanager reports, e.g., registered, initializing, etc.)
- GSM network type icon (e.g., 2g, 3g, etc.).
- GSM network stregnth icon.
- Wifi icon (including strength).
- Battery icon (including strength).
- Microphone icon (enabled or disabled).
- Sound icon (or headphone).
- An icon also represents what "state" the device is in: unlock (open circle), lock (circle with slash), screenoff (filled circle), or proximity lock (circle with dot)
- Time.

HOOKS: _sxmo_hook_statusbar.sh_(1) (override look and feel of the statusbar),
_sxmo_hook_icons.sh_(1) (adjust icons)

## HARDWARE INPUT

On devices with three buttons (power, volume raise, volume lower), the default
button bindings are:
- *Volume Raise*:
	- *1 tap*: Launch Main Menu if no app open or Context Menu if app open.
	- *2 taps*: Launch Main Menu
	- *3 taps (or hold)*: Launch Window Management Menu
- *Volume Lower*:
	- *1 tap*: Toggle virtual keyboard
	- *2 taps*: Toggle the window manager layout state (between monocle/tile/bstack)
	- *3 taps (or hold)*: Kill app
- *Power button*:
	- *1 tap*: Transition to next state
	- *2 taps*: Transition to state after next state
	- *3 taps (or hold)*: Launch terminal

On devices with one button (power), the default button bindings are:
TODO

HOOKS: _sxmo_hook_inputhandler.sh_(1) (override input handling behavior)

## SWIPE GESTURES

In addition to the button bindings, a custom application called *lisgd* was
developed to provide touchscreen swipe gestures within Sxmo. These gestures are
sensitive to the edge of the screen where the gesture is initiated or where they
end up, and some are sensitive to the length/distance of the swipe. Gestures in
the main part of the screen, staying clear of the edges, are usually not
interpreted and passed to the underlying application unmodified (assuming it has
gesture support).

The SXMO gestures are visualized in the following schematic:

![gestures](assets/sxmo_gestures.png)

The default swipe gestures are:
- *1 finger right-to-left from right edge*: Focus next tag/workspace
- *1 finger left-to-right from left edge*: Focus previous tag/workspace
- *2 fingers right-to-left (anywhere)*: Move focused application to previous tag/workspace
- *2 fingers left-to-right (anywhere)*: Move focused application to next tag/workspace
- *1 finger top-to-bottom along the left edge (held pressed)*: Volume down
- *1 finger bottom-to-top from the top edge*: Show the application menu
- *2 finger bottom-to-top from the top edge*: Show the system menu
- *1 finger top-to-bottom onto the top edge*: Close the active menu
- *1 finger bottom-to-top from the bottom edge*: Show virtual keyboard
- *1 finger top-to-bottom onto the bottom edge*: Hide virtual keyboard
- *2 finger top-to-bottom onto the bottom edge*: Close the current active window
- *3 finger top-to-bottom onto the bottom edge*: Kill the current active window
- *1 finger from bottom-right corner, swiping diagonally*:  Rotate the screen
- *1 finger from bottom-left corner, swiping diagonally*:  Lock the device
- *1 finger left-to-right along the top edge (held pressed)*: Increase screen brightness
- *1 finger right-to-left along the top edge (held pressed)*: Decrease screen brightness

There are various default gestures that translate to keypresses for the
underlying application, this facilitates navigation in a variety of
applications, including terminal-based applications, without needing the virtual
keyboard:
- *1 finger right-to-left onto the left edge*: Send Left arrow
- *1 finger left-to-right onto the right edge*: Send Right arrow
- *1 finger top-to-bottom along the right edge (held pressed)*: Send Key down (scroll down)
- *1 finger bottom-to-top along the right edge (held pressed)*: Send Key up (scroll up)
- *1 finger right-to-left along the bottom edge*: Send Backspace
- *1 finger left-to-right along the bottom edge*: Send Return

HOOKS: _sxmo_hook_lisgdstart.sh_(1) (controls how lisgd is started)

SEE ALSO: _lisgd_(1)

## MENUS

Menus are a central feature of sxmo and are navigable through using hardware
buttons. On three button devices like the pinephone:
- *Volume Raise*: Previous item
- *Volume Lower*: Next item
- *Power*: Select item

You can also simply use the touchscreen to tap your selection if you'd like as well.

In addition to a Main Menu, each application can have its own Context Menu
associated with it.

If no application is open, swiping down from the top of the screen, or pressing
the volume raise button once, will bring up the Main Menu.  If an application is
open, this will bring up the Context Menu instead.  (To access the Main Menu
while in an application, press the volume raise button twice.)

You can close any open menu with a gesture, swipe straight up (vertically) onto
the top edge of the screen and all the open menus will close.

HOOKS: _sxmo_hook_apps.sh_(1) (what shows up on Apps submenu),
_sxmo_hook_scripts.sh_(1) (what shows up in Scripts submenu),
_sxmo_hook_contextmenu.sh_(1) (controls the content of all the menus, including
contextmenus),
_sxmo_hook_icons.sh_(1) (icons)

# STATES

Sxmo recognizes five basic states:

- *unlock*: Screen is on; touchscreen is enabled.
- *lock*: Screen is on; touchscreen is disabled.
- *screenoff*: Screen is off; touchscreen is disabled. There is a short purple blink while in this state.
- *suspend or CRUST*: This is the kernel CRUST, where the modem will still be
active to monitor incoming calls/texts but everything else will be suspended..
- *Proximity Mode*: This is a special state when one is in a phone call. If you
bring it close to your face, it will lock input and blank the screen, and if you
move it away from your face, it will unlock input and unblank the screen.

![schema of the lock states when pressing power](schemas/lock-power-states.png)

The usual workflow is this. If the phone is in the "unlock" state and you wish
to suspend it, click the power button once. This will transition to the
"screenoff" state which will automatically move to the "suspend" state unless
something is blocking it. If the phone is in the "suspend" state and you wish
to use it, click the power button once (to move to "lock" state) and then once
more to move to "unlock" state.

Sxmo also handles automatic transitions from some states to others.

- It will automatically transition rom unlock -> screenoff after a certain amount of time (120s).
- It will automatically transition from lock -> screenoff after a certain amount of time (8s).
- It will automatically transition from screenoff -> suspend after a certain amount of time unless something is blocking it (2s).

You can set up suspend blockers in the wakelocks hook.

HOOKS:
_sxmo_hook_postwake.sh_(1) (what to do after waking up from suspend state)
_sxmo_hook_lock.sh_(1) (what to do when transitioning into lock state)
_sxmo_hook_screenoff.sh_(1) (what to do when transitioning into screenoff state)
_sxmo_hook_unlock.sh_(1) (what to do when transitioning into unlock state)
_sxmo_hook_wakelocks.sh_(1) (set what block suspend)

# CRONJOBS

Sxmo ensures that cron jobs run and will actively wake the phone from sleep temporarily to this end.
The cron daemon is installed but not enabled in postmarketOS. Cron has to be started manually
with *rc-service crond start* and set to start on boot with *rc-update add crond
default*. We use a little program called _mnc_(1) to wake the phone up before the next 
planned cron job. We also wrap some sxmo logic in _sxmo_rtcwake_(1) which
launches the cronjob and puts the phone back to sleep when finished.

```
*/15 * * * * sxmo_rtcwake.sh sleep 10
```

This example will wake the phone up for 10 seconds every 15 minutes.

If you omit *sxmo_rtcwake.sh* for a job, the system will *not* wake up from
crust to execute the job.  Note that in such cases, you might want to use
*sxmo_wm.sh execwait* instead as this will set most of the sxmo environment
variables, e.g.:

```
*/15 * * * * sxmo_wm.sh execwait sleep 20
```

HOOKS: _sxmo_hook_mnc.sh_(1) (change the program that calculates when to wakeup)

# CALLS AND TEXTING

Calling and texting is fully functional and should work out-of-the-box. Make
sure you have the modem killswitch in the enabled position and wait a little
bit after booting before trying modem functionality to allow the modem to
connect.

The scripting behind the scenes works via _mmcli_(1).

## UNLOCKING THE SIM

As long as your SIM is locked, a lock icon should appear in the status bar.
SXMO automatically asks for your SIM's PIN code using a menu (since sxmo 1.4.1).

Alternatively, you can do so from the command-line as follows:

```
mmcli -i 0 --pin 1234
```

You could put this in _sxmo_hook_modem.sh_(1), but there is of course a
significant security risk involved if your device gets compromised!

HOOKS: _sxmo_hook_modem.sh_(1) (what to do when modem chanes states)

## CALLING

To place a new call, you can use the *Dialer* entry in the Main Menu.
You will be prompted for a number to dial. Once the call connects, a menu
will automatically be launched which let's you send DTMF or Hang Up.

A proximity lock is automatically enabled that will lock and turn off your
screen during a call if you have the phone close to your ear. See STATES.

HOOKS: _sxmo_hook_call_audio.sh_(1) (launch programs when a call is initiated and
finished)

## SENDING TEXTS

To compose a new text message, from the *Texts* entry you will see a
*Send a Text* entry which first prompt you for a number. After entering
the destination number you will by default be dropped into your editor
(our default is _vis_(1)) to compose your message. Once
your message is as you'd like it, exit the editor using `ZZ`/`:wq!`.  You
will now be taken to a new menu to confirm your message from which you can
edit/send/add recipients/add attachments/cancel the message.

HOOKS: _sxmo_hook_sendsms.sh_(1) (what to do when sending sms/mms)

## READING TEXTS

To view existing text message threads you can use the *Texts* entry in the Main
Menu. This menu will let
you tail follow a logfile for your conversation with each number. When
a new text is sent or received; the tail will automatically be updated
with the new text contents.

While displaying the conversation you can pop out a contextual menu with
power up button to reply by text or to start a call with the number.

You can also open a "conversation" window with a gesture from the botton edge. It will
open your editor and the virtual keyboard to type your sms. Save and close the
file to send the sms. A new editor will be openned again to type a new
message.

HOOKS: _sxmo_hook_tailtextlog.sh_(1) (controls look and feel of view of message text, e.g., colors, etc.)

## MONITORING FOR INCOMING CALLS AND TEXTS

A vital feature of a working phone is being able to receive new texts and
pickup calls. This functionality is made possible through a script that
monitors the modem activities and vibrates the phone, plays a notification or ringing sound, 
and blinks the green LED when there is an incoming text/call. 

While a call is incoming:
- The phone will ring and vibrate (unless you disabled these in the [Audio menu](#strongincluded-menustrong)).
- The green LED will trigger.
- A menu will appear to allow you to pickup the call. You can also discard
  the call or ignore the call (mute the ring). If you missed the menu, you can also open 
  the [global system menu](#strongincluded-menusstrong) menu and you'll
  see a menu entry to pickup the call; of course this is time-sensitive and this
  menu entry will only be visible while the other party's line is ringing

HOOKS:
_sxmo_hook_call_audio.sh_(1) (adjust volume level when starting/ending call)
_sxmo_hook_discard.sh_(1) (if you hangup without answering)
_sxmo_hook_hangup.sh_(1) (if you hangup)
_sxmo_hook_missed_call.sh_(1) (if you miss the call)
_sxmo_hook_mute_ring.sh_(1) (if you click ignore to ignore the call, i.e., mute the ringing)
_sxmo_hook_pickup.sh_(1) (if you pickup)
_sxmo_hook_ring.sh_(1) (what to do when ringing)

When a new text message comes in:
- The phone will play a notification sound and vibrate(unless you disabled these in the [Audio menu](#strongincluded-menustrong)).
- The green LED will trigger.
- A popup notification will appear.

HOOKS:
_sxmo_hook_sms.sh_(1) (what to do when an sms/mms is received)

## CONFIGURING THE GSM

To have a working gsm connection you can use the dedicated Networks submenu entry
"Add a GSM Network". You then must type the APN your provider gave you. You can
then toggle this GSM entry as other network manager ones.

## CONFIGURING MMS

MMS messaging should work just like regular text messaging.  When you *Send a
Text* there will be the option to add multiple recipients or attachments.  To
make mms work, sxmo relies on [mmsd-tng](https://gitlab.com/kop316/mmsd).  The
main configuration will be located in ~/.mms/modemmanager/mms. To make things
easier in sxmo, we have a dedicated menu entry in *Configuration* called
*Config MMS*. This menu will create a default config and you then can edit
fields one by one.  The script should take care of restarting mmsd when closed.

*Note* that you likely will *not* have to configure mmsd-tng, if your settings
are already in [the
database](https://wiki.gnome.org/Projects/NetworkManager/MobileBroadband/ServiceProviders).
Consider contributing your own if it is not.

*Note* that your carrier's nameserver must be present in `/etc/resolv.conf` in
order to send/receive mms.  This should be automatic.  However, sometimes
NetworkManager will place the wifi's nameservers *above* the carrier's
nameservers, and since `/etc/resolv.conf` can only use the first three entries,
the carrier's nameservers will not be used.  To fix this, you can set dns=none
in `/etc/NetworkManager/NetworkManager.conf` and use a static `/etc/resolv.conf`
instead.

## BLOCKING NUMBERS

TODO

# CONTACTS

The Sxmo contacts system based on a plain TSV file that can be placed at
~/.config/sxmo/contacts.tsv`.  This TSV file is expected to have
two tab separated columns: phonenumber, and contactname. Upon receiving a call if you
have a contact stored associated with the incoming number, the contact
name will appear instead of the number. Also contact names will appear
in the Texts and Dialer menus if they are present in the contacts TSV
file. If no `contacts.tsv` is present, or the number is missing from
this file; the contact in menus will show up as `???`.
An `contacts.tsv` example might look like:

```
+122345628	John Smith
+128371642	Jeff Foo
+31612345678	Jan Janssen
```

# SCRIPTS AND APPLICATIONS

In App and Scripts menu there are some included scripts. You can edit these in
_sxmo_hook_apps.sh_(1) and _sxmo_hook_scripts.sh_(1).

Some Included Scripts:
- *Web Search*: Search duckduckgo with the query provided by the user (bangs work too)
- *Timer*: A simple countdown timer script that vibrates the phones upon completion
- *Youtube*: Search youtube by keyword in dmenu and then view in mpv (script based on [idiotbox](https://codemadness.org/idiotbox.html))
- *Youtube (audio)*: Search youtube by keyword in dmenu and then listen in mpv (script based on [idiotbox](https://codemadness.org/idiotbox.html))
- *Weather*: United States weather forecast (by zipcode) dmenu script
- *RSS*: Aggregates RSS feeds and let's you view by timespan dmenu script (based on [sfeed](https://codemadness.org/sfeed-simple-feed-parser.html))

User scripts are custom scripts the user can run via the Scripts Menu.
To add your own custom
userscript, you have two options: edit the `userscripts` file or
place a shell script in the `userscripts` directory.

- Option 1. Edit `$XDG_CONFIG_HOME/sxmo/userscripts` and write your entries
in it, following the appmenu format `<name> ^ <should-return-to-menu> ^ <script-path-or-command>`
one entry per line. Example: ` Weather ^ 0 ^ sxmo_terminal.sh -f "monospace:size=5" sh -c "curl http://wttr.in/ | less -SR"`
- Option 2. Create the ~/.config/sxmo/userscripts` directory and place your
*.sh* scripts in the `userscripts` directory. Note, Userscripts should be set to
be executable. You can set a title for the script by adding a comment line of the following ofrmat near the top of the file:

```
# title="$icon_glb My World"
```

For examples of scripts Sxmo users have made for their mobile devices, see:

- [~anjan/sxmo-userscripts](https://git.sr.ht/~anjan/sxmo-userscripts).

Some Supported Applications:
- *St*: The suckless terminal
- *Foot*: The minimalistic wayland terminal
- *Firefox*: The infamous FOSS browser often symbolized by a fox
- *Surf*: The suckless minimalistic browser based on Webkit
- *Netsurf*: An alternative minimalistic browser that renders really fast
- *Lagrange*: A gemini browser
- *Sacc*: A great minimalistic gopher browser; launches by default to a good phlog aggregator (optional)
- *Vim/Neovim/Vis*: A modal terminal-based text editor
- *Feh/Sxiv*: Image viewers for X
- *Mpv*: Video player
- *Nano*: A simple text-based text editor
- *Mutt/Neomutt*:  A text-based mail client
- *W3m*: A text-based browser with vim-like keybindings
- *Weechat*: A text-based IRC client and much more
- *Ncmpcpp*: A text-based music client for MPD
- *Cmus*: Another terminal-based music player
- *Aerc*:  A simple terminal-based mail client
- *Xcalc*: A nice (and fast) calculator app

# WIFI

There is a menu entry in the Networks Menu to add an APN and connect to wifi.
This is essentially this is just a wrapper to launch _nmtui_(1)..
If your phone has a wifi killswitch (like the Pinephone or Librem 5), make sure it is in the enabled position.

# MOBILE DATA

Mobile data can be simarly added via the Networks Menu. It will ask for an APN, you may also
consult the [postmarketOS](https://wiki.postmarketos.org/wiki/PINE64_PinePhone_(pine64-pinephone)#Modem) pinephone
documentation for that aspect.

# AUDIO

You can use the Audio Menu to toggle which audio output you want to send sound to.

Sxmo uses pipewire and pulseaudio nowadays. You can access an Audio menu and a Bluetooth menu from the main menu. We use callaudiod to route audio during a phone call.

Currently, bluetooth audio during phone calls does not work. Please see:

- https://gitlab.com/mobian1/issues/-/issues/345
- https://gitlab.com/mobian1/callaudiod/-/issues/12

# UPDATING

Sxmo's packages are currently distributed through packages in pmOS so
when new package versions are periodically pushed; your install can be

To update run:

```
apk update
apk upgrade -aiv
```

There is also a menu entry within the Config Menu 
to update as well which runs the same commands as above.

For details on what changed between package versions or image releases
refer to [the changelog](./CHANGELOG.md).

*Update migrations*

While developing Sxmo, we will regularly update certain configuration
files such as the xinit/sway template, the hooks or whatever. These
files are typically a mixture of changes by us and customizations by
the user. This mixture gives the user maximum flexibility to adapt Sxmo
to their liking. However, when we update such files, the challenge is
to ensure that user modifications can be easily merged back in again.
Moreover, we must ensure the system is never in a broken state because
of outdated configurations and version mismatches.

Whenever your configuration files are out-of-date when starting Sxmo,
they will be moved aside (i.e. renamed with ``.needs-revision`` extension)
and the default configuration will take its place. A red notification
will pop up telling you have configuration files that need to be
migrated. This migration is done by running a script named
_sxmo_migrate_(1). This script can simply be launched from the
configuration menu or via ssh (recommended).
It first shows the differences between your configuration and the new
default, and allows you to edit and apply your configuration accordingly.
_sxmo_migrate_(1) use `$DIFFTOOL` to help you merge your changes. By default
$DIFFTOOL is set to `vimdiff`.

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

You should **only** update this version hash when ``sxmo_migrate.sh``
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

# FURTHER CUSTOMIZATION

Much of Sxmo's core-functionality in regards to menus
are built out via plain shell scripts. So further
cutomization should be simple. See sxmo-util's [scripts
directory](https://git.sr.ht/~mil/sxmo-utils/tree/master/scripts)
to get a better sense of how things are put together. You can edit
the scripts on your system for temporary fixes and please consider [contributing](./CONTRIBUTING.md)
your changes if you believe your modifications may be useful to other
users.

# HOOKS

If a user-defined hook file does not exist on activity, sxmo will run the
corresponding project defined default hook from `/usr/share/sxmo/default_hooks/`.
For example, if you pickup a call and `~/.config/sxmo/hooks/sxmo_hook_pickup.sh` does
not exist, `/usr/share/sxmo/default_hooks/sxmo_hook_pickup.sh` will be run.

Note also that some hooks will be in a subdirectory with a devicename.  For
instance, in `/usr/share/sxmo/default_hooks/` there are `one_button_ereader`
and `three_button_touchscreen` and various names linked to them.  (We determine
the name of your device by looking at
*/sys/firmware/devicetree/base/compatible*.) This allows you to have unique
hooks depending on the kind of device that you are running.

# NOTIFICATIONS

TODO

# LOGGING

Sxmo places its information in ~/.local/state/sxmo.log. You might find the other 
logfiles in that directory of use as well (e.g. ~/.local/state/superd/logs/\*)

# SUPERD AND DAEMONS

Sxmo uses _superd_(1) and _sxmo_daemons_(1) to handle launching daemons.

# FILES

Sxmo uses _sxmo_files_(1) via the Main Menu to access your files. It obeys xdg.

# AUTO-LOGIN WITH TINYDM

Sxmo uses _tinydm_(1) to automatically log you in.
You can configure the
UID to login as in `/etc/conf.d/tinydm`. (make sure to adapt this if you create a custom user!)

# ENVIRONMENTAL VARIABLES

The following environment variables can be set in *~/.config/sxmo/profile* or
*~/.profile*.

- $TERMCMD: Terminal to launch. Defaults to _foot_(1) or _st_(1).
- $KEYBOARD: Keyboard to launch. Defaults to _svkbd_(1) or _wvkbd_(1).
- $KEYBOARD_ARGS: Arguments to pass to $KEYBOARD, e.g., *-o | clickclack -f
  /usr/share/sxmo/keytap.wav*
- $EDITOR: Editor to use to handle files. Defaults to _vim_(1).
- $DEFAULT_COUNTRY: String to indicate the default country sxmo should fallback
  to when the phone numbers are not country code prefixed. Should be set to a
  country code (iso-3166?) such as *FR* for France, *DE* for Germany, *US*
  for the Unites States.
- $SXMO_DEVICE_NAME: See DEVICES
- $SXMO_CACHEDIR: Default: ~/.cache/sxmo
- $SXMO_BLOCKDIR: See BLOCKING NUMBERS.
- $SXMO_BLOCKFILE: See BLOCKING NUMBERS.
- $SXMO_CONTACTFILE: See CONTACTS.
- $SXMO_LOGDIR: Where to log text messages. Default: ~/.local/share/sxmo/modem
- $SXMO_NOTIFDIR: Default: ~/.local/share/sxmo/notifications. See NOTIFICATIONS.
- $SXMO_RINGTONE: Sound to play when incoming call
- $SXMO_TEXTSOUND: Sound to play when new message.
- $SXMO_RINGTIME: Number of times to play ring tone.
- $SXMO_DEFAULT_DRAFT: Default message when composing a message.
- $SXMO_BG_IMG: Background image.

There are other environmental variables that are device specific. See DEVICES.
As well, several scripts have their own environmental variables which we do not
list here.

# DEVICES

This section describes how to add a new device to sxmo.  There are three basic
steps:
- Determine the $SXMO_DEVICE_NAME
- Add a *sxmo_deviceprofile_SXMO_DEVICE_NAME.sh* file to
  *scripts/deviceprofiles/* in the source tree.
- Add (or symlink to an existing) SXMO_DEVICE_NAME folder in
  *configs/default_hooks/* in the source tree.

## DETERMINING THE SXMO_DEVICE_NAME

The $SXMO_DEVICE_NAME is determined by the following code in *sxmo_init.sh* upon
boot:

```
tr -c '\0[:alnum:].,-' '_' < /proc/device-tree/compatible | tr '\0' '\n' | head -n1
```

## ADDING A DEVICEPROFILE FILE

In the source tree navigate to *scripts/deviceprofiles/* and make a file called
*sxmo_deviceprofile_SXMO_DEVICE_NAME.sh*.  This file should contain various
shell variables that define things unique to your device, e.g., input ids, etc.
There is a *README.md* in the same directory that will help.

## DEVICE-SPECIFIC ENVIRONMENTAL VARIABLES

TODO: Include all the SXMO_ variables from README.md here?

## ADDING DEVICE_SPECIFIC HOOKS

In addition to the deviceprofile file, which defines things like touch input
ids, etc., you will also want to set a locking workflow for the device.  We
have three basic defaults to which all the devices symlink.  Navigate to
*configs/default_hooks/* in the source tree.  You will see there are three
folders and several symlinks.  These folders contain various hooks that handle
locking mechanisms.  There are at present three basic folders:
*three_button_touchscreen*, *one_button_e_reader*, and *desktop*.  You can also
create your own, but usually you'll just want to symlink to one of these.

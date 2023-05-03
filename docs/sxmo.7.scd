sxmo(7)

# NAME

sxmo - a simple X mobile operating system

# SYNOPSIS

*sxmo* is a collection of simple and suckless programs and scripts used together
to create a fully functional mobile user interface adhering to the Unix philosophy. We focus
on Linux smartphones such as the Pinephone. Sxmo is primarily written in POSIX
shell scripts and can be easily modified and extended using our hook system.

Sxmo >= 1.6.0 runs both on Xorg (using dwm) as well as on Wayland (using sway).
The X in our name historically referred to Xorg, but is now open to whatever
interpretation you prefer (eXtensible, eXcellent, eXperimental, etc...)

A brief overview of sxmo's features (in order of presentation):

- *Autologin*: sxmo uses _tinydm_(1) to automatically log you into the window
  manager of your choice. See DESCRIPTION.
- *Customizable hooks*: sxmo has many hooks (small shell scripts) which allow
  the user to override almost any behavior. See HOOKS.
- *Customizable statusbar*: sxmo uses _sxmobar_(1) to offer an informative,
  compact, and customizable statusbar. See STATUSBAR.
- *Multiple forms of input*: sxmo handles input from hardware buttons, gestures,
  touchscreen, stylus, and hardware and onscreen keyboards. See INPUT.
- *Fully customizable menus*: sxmo uses _bemenu_(1) or _dmenu_(1) for fully
  customizable menus which are context-sensitive (if in an application, it will
  open a menu of options for that application). As well, sxmo comes bundled with
  an *Apps Menu* and a *Scripts Menu* which are also customizable; a *Files
  Menu* which allows you to browser your filesystem via _sxmo_files_(1); and
  more. See MENUS.
- *Autosuspend, screen blanking, and input locking*: sxmo states allow sxmo to
  automatically suspend when idle unless certain programs block it; to offer 
  protection from accidental wakeups; and to blank the screen and lock the input
  while in a phone call and the phone is near your face. See STATES.
- *Smart cronjobs*: sxmo uses _crond_(1) to handle cronjobs and a special
  program called _mnc_(1) to wake the phone up in time to execute cron jobs.
  See CRONJOBS.
- *Calls and texting*: sxmo allows you to compose both sms and mms (group texts,
  attachments), and receive and make phone calls. See CALLS AND TEXTING.
- *Contact management*: sxmo has a script called _sxmo_contacts.sh_(1) which
  allows you to manage contacts. See CONTACTS.
- *Wifi support*: sxmo has a *Networks Menu* which uses _nmcli_(1) to setup
  wifi, including hotspots. See WIFI.
- *Audio support*: sxmo has full audio support via _pipewire_(1) and
  _pulseaudio_(1), and routes audio while a phone call via _callaudiod_(1). See
  AUDIO.
- *Bluetooth support*: sxmo has a *Bluetooth Menu* which uses _bluetoothctl_(1)
  to manage bluetooth devices.
- *Easily updated*: sxmo has a migration tool called _sxmo_migrate.sh_(1) which
  allows you to easily keep your custom hooks and configs up-to-date. See UPDATING.
- *Notifications system*: sxmo has an internal notifications system for texts and
  missed calls, including popups, led management, and sounds. See NOTIFICATIONS.
- *Multiple devices*: sxmo supports many different kinds of devices, and users
  can easily add more. See DEVICES.
- *Customizable environmental variables*: sxmo has a lot of environmental
  variables users can override. See ENVIRONMENT.

And more (not documented here):
- *SSH as a first class citizen*: Log into your phone over ssh and have full
  access to all sxmo menus and functionality.
- *Alpine Linux / PmOS Based Images*: postmarketOS's infrastructure bakes
  images that bundle sxmo and pmOS (based on Alpine Linux) which keeps things
  small, simple, and pragmatic

Sxmo 1.4.1 was presented at AlpineConf 2021, you can watch the video.

# DESCRIPTION

Sxmo uses _tinydm_(1) to automatically launch the window manager of your
choice (_sway_(1) or _dwm_(1)). Note: You can configure the UID in
*/etc/conf.d/tinydm*. Make sure to change this if you create a custom user. 
You may switch between the two window managers in the *Power Menu*.

Once the window manager launches, it will execute _sxmo_hook_start.sh_. Sxmo
relies on _superd_(1) and _sxmo_daemons.sh_(1) to launch various applications
from this start hook. You can edit the start hook directly and also edit
*~/.config/sxmo/profile* and *~/.profile* to override certain common
environmental variables such as background image (see ENVIRONMENT).
Note that sxmo respects the xdg specification, e.g., $XDG_CACHE_HOME,
$XDG_CONFIG_HOME, etc.

Regardless of the environment you use sxmo consists in a large set of POSIX
shell scripts that glue all these tools together. All these shell scripts comply
to the pattern *sxmo_\*.sh* and most can be found in your */usr/bin/* directory.

HOOKS: _sxmo_hook_start.sh_ (what executes on startup)

SEE ALSO: _tinydm_(1), _superd_(1), _sxmo_daemons.sh_(1)

# HOOKS

A lot of functionality is also contained in hooks (*sxmo_hook_\*.sh*). Sxmo uses
PATH to determine which hook executes. It will look first for hooks in 
*~/.config/sxmo/hooks/* before it looks in */usr/share/sxmo/default_hooks/*. 
For example, if you pickup 
a call and *~/.config/sxmo/hooks/sxmo_hook_pickup.sh* does not exist, 
*/usr/share/sxmo/default_hooks/sxmo_hook_pickup.sh* will be run.

Note that some hooks are in a subdirectory under the *hooks/* main
directory which will allow you to have hooks associated with a certain
device. See DEVICES. For instance, in */usr/share/sxmo/default_hooks/* there 
are several device subdirectories, one of which will be your $SXMO_DEVICE_NAME. 
It should be a symlink to another subdirectory, e.g., *one_button_ereader* or 
*three_button_touchscreen*. Device-specific hooks go here.

While you can manually copy and edit hooks to your liking,
_sxmo_hookmenu.sh_ (MENU > config > hooks) simplifies this process.

Note also that hooks do not have their own man pages. We have documented each
hook in the comments of that hook.

# STATUSBAR

After login, you will be presented the sxmo interface as follows:

https://sxmo.org/assets/screenshot.jpg

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

HOOKS: _sxmo_hook_statusbar.sh_ (override look and feel of the statusbar),
_sxmo_hook_icons.sh_ (adjust icons)

SEE ALSO: _sxmobar_(1)

# INPUT

The main forms of input are *Hardware buttons* (power, raise volume, lower
volume), *Touchscreen* (i.e., touching the screen), and *Gestures* (i.e., swipes).
Sxmo also allows input for a *Hardware keyboard* (e.g., the pinephone keyboard
case or a bluetooth keyboard) and a *Stylus*. Sxmo also supports a virtual
keyboard (_svkbd_(1) or _wvkbd_(1)).

## Hardware buttons

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

On devices with one button (power), the default button bindings are different.
Please refer to _sxmo_hook_inputhandler.sh_ for the exact details.

HOOKS: _sxmo_hook_inputhandler.sh_ (override input handling behavior)

## Touchscreen

Sxmo relies on _sway_(1) or _dwm_(1) to handle the touchscreen. You can
enable/disable touchscreen input via *Config*.

## Gestures

Sxmo relies on _lisgd_(1) for gestures. You can enable/disable gestures via
*Config*.

These gestures are sensitive to the edge of the screen where the gesture is
initiated or where they end up, and some are sensitive to the length/distance of
the swipe. Gestures in the main part of the screen, staying clear of the edges,
are usually not interpreted and passed to the underlying application unmodified
(assuming it has gesture support).

The default gestures are visualized in the following schematic:

https://sxmo.org/assets/sxmo_gestures.png

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

HOOKS: _sxmo_hook_lisgdstart.sh_ (controls how lisgd is started and what the
default gestures are)

SEE ALSO: _lisgd_(1)

## Hardware keyboard

If you have the pinephone keyboard case this should work ootb. If you have a
bluetooth keyboard, see BLUETOOTH.

TODO: Describe dwm/sway bindings?

## Stylus

Sxmo relies on _dwm_(1) and _sway_(1) to handle stylus input. You can
enable/disable stylus input from *Config*.

## Virtual keyboards

SEE ALSO: _svkbd_(1) or _wvkbd_(1).

# MENUS

Menus are a central feature of sxmo and are navigable through using hardware
buttons. On three button devices like the pinephone:
- *Volume Raise*: Previous item
- *Volume Lower*: Next item
- *Power*: Select item

You can also simply use the touchscreen to tap your selection if you'd like as well.

In addition to a Main Menu, each application can have its own Context Menu
associated with it which defines functions unique to that application (e.g.,
zoom in, zoom out, etc.).

If no application is focused, swiping down from the top of the screen, or pressing
the volume raise button once, will bring up the Main Menu.  If an application is
focused, this will bring up the application's Context Menu instead.  (To access the 
Main Menu while an application is focussed, press the volume raise button twice.)

You can close any open menu with a gesture: swipe straight up (vertically) onto
the top edge of the screen and all the open menus will close. See INPUT.

HOOKS: _sxmo_hook_apps.sh_ (what shows up on Apps submenu),
_sxmo_hook_scripts.sh_ (what shows up in Scripts submenu),
_sxmo_hook_contextmenu.sh_ (controls the content of all the menus, including
contextmenus),
_sxmo_hook_icons.sh_ (icons)

## SCRIPTS MENU

Some included Scripts:
- *Web Search*: Search duckduckgo with the query provided by the user (bangs work too)
- *Timer*: A simple countdown timer script that vibrates the phones upon completion
- *Youtube*: Search youtube by keyword in dmenu and then view in mpv (script based on [idiotbox](https://codemadness.org/idiotbox.html))
- *Youtube (audio)*: Search youtube by keyword in dmenu and then listen in mpv (script based on [idiotbox](https://codemadness.org/idiotbox.html))
- *Weather*: United States weather forecast (by zipcode) dmenu script
- *RSS*: Aggregates RSS feeds and let's you view by timespan dmenu script (based on [sfeed](https://codemadness.org/sfeed-simple-feed-parser.html))

To add your own custom userscripts, you have two options: edit the
*~/.config/sxmo/userscripts* file or
place a shell script in the *~/.config/sxmo/userscripts/* directory.

- Option 1. Edit *~/.config/sxmo/userscripts* and write your entries in it,
  following the appmenu format *<name> ^ <should-return-to-menu> ^
  <script-path-or-command>* one entry per line. Example: 

```
 Weather ^ 0 ^ sxmo_terminal.sh -f "Sxmo:size=5" sh -c "curl http://wttr.in/ | less -SR"
```

- Option 2. Create the *~/.config/sxmo/userscripts/* directory and place your
  scripts in it. Note, Userscripts should be set to be executable. You can set a
  title for the script by adding a comment line of the following ofrmat near the
  top of the file:

```
# title="$icon_glb My World"
```

For examples of scripts sxmo users have made for their mobile devices, see:

https://git.sr.ht/~anjan/sxmo-userscripts

HOOKS: _sxmo_hook_scripts.sh_ (control how userscripts are loaded)

## APPS MENU

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

HOOKS: _sxmo_hook_apps.sh_ (control list of apps)

## FILE BROWSER

SEE _sxmo_files.sh_(1).

# STATES

Sxmo recognizes five basic states:

- *unlock*: Screen is on; touchscreen is enabled.
- *lock*: Screen is on; touchscreen is disabled.
- *screenoff*: Screen is off; touchscreen is disabled. The led will also blink
  purple every few seconds to indicate that you are in this state.
- *suspend or CRUST*: This is CRUST (or suspend), where the modem will still be
  active and monitor for incoming calls/texts but everything else will be
  suspended.
- *Proximity Mode*: This is a special state when one is in a phone call. If you
  bring it close to your face, it will disable input and turn the screen off,
  and if you move the phone away from your face, it will enable input and turn
  the screen back on.

A diagram of the states can be found here:

https://sxmo.org/assets/lock-power-states.png

The usual workflow is this. 

- If the phone is in the *unlock* state (default when you boot up) and you wish
  to suspend it, tap the power button once. This will transition to the
  *screenoff* state which will then automatically transition to the *CRUST* state
  unless something is blocking it. 
- If the phone is in the *CRUST* state (i.e., suspended) and you wish to wake it
  up, tap the power button once (to transition to the *lock* state) and then tap
  it once again to transition to the *unlock* state. (This prevents accidental
  wakeups in the pocket.)

Sxmo also handles automatic transitions from some states to others.

- It will automatically transition from *unlock* to *screenoff* after a certain
  amount of idleness (120s).
- It will automatically transition from *lock* to *screenoff* after a certain 
  amount of time (8s).
- It will automatically transition from *screenoff* to *CRUST* immediately
  unless something is blocking it.

You can set up suspend blockers in the wakelocks hook.

HOOKS:
_sxmo_hook_postwake.sh_ (what to do after waking up from suspend state),
_sxmo_hook_lock.sh_ (what to do when transitioning into lock state),
_sxmo_hook_screenoff.sh_ (what to do when transitioning into screenoff state),
_sxmo_hook_unlock.sh_ (what to do when transitioning into unlock state),
_sxmo_hook_wakelocks.sh_ (set what block suspend)

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

HOOKS: _sxmo_hook_mnc.sh_ (change the program that calculates when to wakeup)

SEE ALSO: _sxmo_rtcwake.sh_(1), _mnc_(1)

# CALLS AND TEXTING

Calling and texting is fully functional and should work out-of-the-box. Make
sure you have the modem killswitch in the enabled position and wait a little
bit after booting before trying modem functionality to allow the modem to
connect.

The scripting behind the scenes works via _mmcli_(1).

## UNLOCKING THE SIM

As long as your SIM is locked, a lock icon should appear in the status bar.
Sxmo automatically asks for your SIM's PIN code using a menu (since sxmo 1.4.1).
Alternatively, you can do so from the command-line as follows:

```
mmcli -i 0 --pin 1234
```

You could put this in _sxmo_hook_modem.sh_, but there is of course a
significant security risk involved if your device gets compromised!

HOOKS: _sxmo_hook_modem.sh_ (what to do when modem chanes states)

## CALLING

To place a new call, you can use the *Dialer* entry in the Main Menu.
You will be prompted for a number to dial. Once the call connects, a menu
will automatically be launched which let's you send DTMF or Hang Up.

A proximity lock is automatically enabled that will lock and turn off your
screen during a call if you have the phone close to your ear. See STATES.

HOOKS: _sxmo_hook_call_audio.sh_ (launch programs when a call is initiated and
finished)

## SENDING TEXTS

To compose a new text message, from the *Texts* entry you will see a
*Send a Text* entry which first prompt you for a number. After entering
the destination number you will by default be dropped into your editor
(our default is _vis_(1)) to compose your message. Once
your message is as you'd like it, exit the editor using `ZZ`/`:wq!`.  You
will now be taken to a new menu to confirm your message from which you can
edit/send/add recipients/add attachments/cancel the message.

HOOKS: _sxmo_hook_sendsms.sh_ (what to do when sending sms/mms)

SEE ALSO: _sxmo_modemsendsms.sh_(1)

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

HOOKS: _sxmo_hook_tailtextlog.sh_ (controls look and feel of view of message text, e.g., colors, etc.)

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
_sxmo_hook_call_audio.sh_ (adjust volume level when starting/ending call),
_sxmo_hook_discard.sh_ (if you hangup without answering),
_sxmo_hook_hangup.sh_ (if you hangup),
_sxmo_hook_missed_call.sh_ (if you miss the call),
_sxmo_hook_mute_ring.sh_ (if you click ignore to ignore the call, i.e., mute the
ringing),
_sxmo_hook_pickup.sh_ (if you pickup),
_sxmo_hook_ring.sh_ (what to do when ringing)

When a new text message comes in:
- The phone will play a notification sound and vibrate(unless you disabled these in the [Audio menu](#strongincluded-menustrong)).
- The green LED will trigger.
- A popup notification will appear.

HOOKS:
_sxmo_hook_sms.sh_(1) (what to do when an sms/mms is received)

## CONFIGURING THE GSM

To configure the GSM, go to *Networks*.

## MOBILE DATA

Mobile data can be simarly added via the Networks Menu. It will ask for an APN, you may also
consult the https://wiki.postmarketos.org/wiki/PINE64_PinePhone_(pine64-pinephone)#Modem pinephone
documentation for that aspect.

## CONFIGURING MMS

To configure MMS, go to *Config*.

MMS messaging should work just like regular text messaging.  When you *Send a
Text* there will be the option to add multiple recipients or attachments.  To
make mms work, sxmo relies on _mmsd-tng_(1).  The
main configuration will be located in *~/.mms/modemmanager/mms*. To make things
easier in sxmo, we have a dedicated menu entry in *Config* called
*Config MMS*. This menu will create a default config and you then can edit
fields one by one.  The script should take care of restarting mmsd when closed.

*Note* that you likely will *not* have to configure mmsd-tng, if your settings
are already in 
https://wiki.gnome.org/Projects/NetworkManager/MobileBroadband/ServiceProviders.
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

The sxmo contacts system based on a plain TSV file that can be placed at
*~/.config/sxmo/contacts.tsv*.  This TSV file is expected to have
two tab separated columns: phonenumber, and contactname. Upon receiving a call if you
have a contact stored associated with the incoming number, the contact
name will appear instead of the number. Also contact names will appear
in the Texts and Dialer menus if they are present in the contacts TSV
file. If no *contacts.tsv* is present, or the number is missing from
this file; the contact in menus will show up as *???*.
A *contacts.tsv* example might look like:

```
+122345628	John Smith
+128371642	Jeff Foo
+31612345678	Jan Janssen
```

SEE ALSO: _sxmo_contacts.sh_(1)

# WIFI

There is a menu entry in the Networks Menu to add an APN and connect to wifi.
This is essentially this is just a wrapper to launch _nmtui_(1)..
If your phone has a wifi killswitch (like the Pinephone or Librem 5), make sure it is in the enabled position.

HOOKS: _sxmo_hook_network_up.sh_ (what to do when network goes up),
_sxmo_hook_network_down.sh_ (what to do when network goes down),
_sxmo_hook_network_preup.sh_,
_sxmo_hook_network_predown.sh_

# AUDIO

You can use the *Audio Menu* to toggle which audio output you want to send sound to.
Sxmo uses _pipewire_(1) and _pulseaudio_(1).
We use _callaudiod_(1) to route audio during a phone call.

Currently, bluetooth audio during phone calls does not work. Please see:

- https://gitlab.com/mobian1/issues/-/issues/345
- https://gitlab.com/mobian1/callaudiod/-/issues/12

SEE ALSO: _sxmo_hook_call_audio.sh_ (adjust volume after/before a call)

# BLUETOOTH

To enable bluetooth, toggle it in *Config*. A *Bluetooth Menu* will appear in
the *Main Menu*.

# UPDATING

Sxmo's packages are currently distributed through packages in pmOS so
when new package versions are periodically pushed; your install can be

To update run:

```
apk update
apk upgrade -aiv
```

There is also a menu entry within the *Config Menu* to do this.

After you update the sxmo packages themselves, be sure to run
_sxmo_migrate.sh_(1) to upgrade your (local) config files. 

SEE ALSO: _sxmo_migrate.sh_(1)

# NOTIFICATIONS

TODO

SEE ALSO: _sxmo_notificationwrite.sh_(1)

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

# MISC

sxmo offers so much more. For instance, _sxmo_rotate.sh_(1) for screen rotation,
TODO


# ENVIRONMENT

Hint: type *env* to see environmental variables. Environmental variables can be
overridden (generally) in *~/.config/sxmo/profile* or *~/.profile*. See also
*~/.Xdefaults*, *~/.config/sxmo/xinit*, and *~/.config/sxmo/sway*.

sxmo respects the xdg protocal, falling back to some sane defaults if this is
missing on your system. The most relevant ones are:

- XDG_DATA_HOME=/home/user/.local/share
- XDG_CONFIG_HOME=/home/user/.config
- XDG_CACHE_HOME=/home/user/.cache
- XDG_STATE_HOME=/home/user/.local/state
- XDG_RUNTIME_DIR=/dev/shm/user/1000
- XDG_DATA_DIRS=/home/user/.local/share

When the system boots, tinydm will will run either *sxmo_xinit.sh* or
*sxmo_winit.sh* depending on if you are running Xorg (dwm) or Wayland (sway).
Each of these then will load */etc/profile.d/sxmo_init.sh* which will set the
following environmental variables. Hint: you can type *\_sxmo_grab_session* 
from the commandline to reload these (e.g., if you switch window managers but
are logged into an ssh connection).

- SXMO_WM: the window manager (sway or dwm)
- DBUS_SESSION_BUS_ADDRESS: dbus socket
- SWAYSOCK: sway socket
- SXMO_OS: the distribution (archlinux, etc.)
- SXMO_CACHEDIR: temporary cache files (~/.cache/sxmo)
- SXMO_LOGDIR: where sxmo logs metadata about calls and texts received. Under this
  directory, there will be several subdirectories, one for each number, which
  contain the content of the text messages received. (~/.local/share/modem)
- SXMO_BLOCKDIR: blocked number metadata (~/.local/share/modem/block).
- SXMO_BLOCKFILE: a TSV file that logs blocked texts and calls
  (~/.local/share/sxmo/block/modemlog.tsv).
- SXMO_CONTACTFILE: a TSV file containing contacts
  (~/.config/sxmo/contacts.tsv)
- SXMO_STATE: the file containing the current state
- SXMO_NOTIFDIR: the directory containing _sxmo_notificationwrite.sh_(1)'s
  internal files.
- BEMENU_OPTS: options to pass to bemenu
- EDITOR: default text editor
- BROWSER: default web browser
- SHELL: default shell
- SXMO_DEVICE_NAME: the device name. Sxmo will also load all the
  variables in */usr/bin/sxmo_deviceprofile_$SXMO_DEVICE_NAME.sh*, such as id for
  touch input, whether the device has leds, and so on. See DEVICES.
- PATH: this will be set to look in ~/.config/sxmo/hooks/$SXMO_DEVICE_NAME/,
  /usr/share/sxmo/hooks/$SXMO_DEVICE_NAME/
  ~/.config/sxmo/hooks/,
  and ~/usr/share/sxmo/hooks/
  before the regular PATH the operating system sets.

It will then also set the following variables:

- KEYBOARD: the name of the virtual keyboard
- SXMO_WM: the name of the window manager
- MOZ_ENABLE_WAYLAND: special to wayland
- XDG_CURRENT_DESKTOP: the name of the desktop (sway or dwm)
- SDL_VIDEODRIVER: special to wayland
- DBUS_SESSION_BUS_ADDRESS: the dbus socket
- SWAYSOCK

It will then load everything in *~/.Xresources* and *~/.config/sxmo/xinit* (if
dwm).

You might also want to set various variables not listed above:

- DMENU_WRAP_AROUND: when scrolling past the beginning or end of a menu, wrap
  around it
- DEFAULT_COUNTRY: String to indicate the default country sxmo should fallback
  to when the phone numbers are not country code prefixed. Should be set to a
  country code (iso-3166?) such as *FR* for France, *DE* for Germany, *US*
  for the Unites States.
- SXMO_SWAY_SCALE: set the scale factor in sway
- SXMO_RINGTONE: Sound to play when incoming call
- SXMO_TEXTSOUND: Sound to play when new message.
- SXMO_RINGTIME: Number of times to play ring tone.
- SXMO_DEFAULT_DRAFT: Default message when composing a message.
- SXMO_BG_IMG: Background image.
- SXMO_STATUS_DATE_FORMAT: the format of the date command in statusbar
- SXMO_DEBUG: turn debugging on or off

There are other environmental variables that are device specific. See DEVICES.
As well, several scripts have their own environmental variables which we do not
list here.

# FILES

~/.local/state/sxmo.log - sxmo's logfiles

~/.config/sxmo - most sxmo config files

~/.config/sxmo/hooks - your local hooks. See HOOKS

~/.config/sxmo/userscripts - either a file or a directory containing your
userscripts. See MENUS.

~/.
TODO

# AUTHORS

TODO

# REPORTING BUGS

TODO

# COPYRIGHT

TODO

# SEE ALSO



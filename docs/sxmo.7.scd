sxmo(7)

# NAME

sxmo - a simple X mobile operating system

# SYNOPSIS

*Sxmo* is a collection of simple and suckless programs and scripts used together
to create a fully functional mobile user interface adhering to the Unix
philosophy. We focus on Linux smartphones such as the Pinephone. Sxmo is
primarily written in POSIX shell scripts and can be easily modified, customised
and extended using our hook system.

Sxmo provides an interface that is notably different from most other mobile
interfaces, especially in the degree of customisability, so reading this manual
is *strongly* recommended.

# DESCRIPTION

Sxmo runs both on Wayland (using _sway_(1)) as well as on Xorg (using _dwm_(1)).
The X in our name historically referred to Xorg, but is now open to whatever
interpretation you prefer (eXtensible, eXcellent, eXperimental, etc...)

All POSIX shell scripts provided by sxmo comply to the naming pattern
*sxmo_\*.sh* and and most can be found in your */usr/bin/* directory. Hooks, a
central feature of sxmo, are named *sxmo_hook_\*.sh* and a specifically designed
to be editable by users. See HOOKS.

## TABLE OF CONTENTS 

A brief overview of sxmo's features (in order of presentation):

- *Autologin*: sxmo uses _tinydm_(1) to automatically log you into the window
  manager of your choice. See INITIALIZATION.
- *Logging*: sxmo write logs to *~/.local/state/sxmo.log* and others. See LOGGING.
- *Services*: sxmo relies on various background services (deamons) that monitor
  various aspects of your device to provide functionality. See SERVICES.
- *Customizable hooks*: sxmo has many hooks (small shell scripts) which allow
  the user to override almost any behavior. See HOOKS.
- *Customizable statusbar*: sxmo uses _sxmobar_(1) to offer an informative,
  compact, and customizable statusbar. See STATUSBAR.
- *Multiple forms of input*: sxmo handles input from hardware buttons, gestures,
  touchscreen, stylus, and hardware and onscreen keyboards. See INPUT.
- *Fully customizable menus*: sxmo uses _bemenu_(1), _wofi_(1), or _dmenu_(1) for fully
  customizable menus which are context-sensitive (if in an application, it will
  open a menu of options for that application). Moreover, sxmo provides
  an *Apps Menu* and a *Scripts Menu* which are also customizable; a *Files
  Menu* which allows you to browser your filesystem via _sxmo_files.sh_(1); various
  menus for *Configuration* and more. See MENUS.
- *Window management*: sxmo uses tiling window managers, which makes for a nice
  fit on mobile devices.
- *Autosuspend, screen blanking, and locking*: sxmo uses a state
  mechanism that allows automatically suspends the device when idle (unless certain
  programs block it); it blanks the
  screen and locks the input while in a phone call and the phone is near your face.
  A locker screen _peanutbutter_(1) is also available for more secure locking. 
  See STATES AND SUSPENSION.
- *Smart cronjobs*: sxmo uses _crond_(1) to handle cronjobs and a special
  program called _mnc_(1) to wake the phone up in time to execute cron jobs.
  See CRONJOBS.
- *Calls and texting*: sxmo allows you to compose both sms and mms (group texts,
  attachments), and receive and make phone calls. See CALLS AND TEXTING.
- *Contact management*: sxmo has a script called _sxmo_contacts.sh_(1) which
  allows you to manage contacts. See CONTACTS.
- *Network configuration*: sxmo has a *Networks Menu* which uses _nmcli_(1) to setup
  wifi and mobile data, including hotspots. See NETWORK CONFIGURATION.
- *Audio support*: sxmo has full audio support via _pipewire_(1) and
  _pulseaudio_(1), and routes audio while a phone call via _callaudiod_(1). See
  AUDIO.
- *Bluetooth support*: sxmo has a *Bluetooth Menu* which uses _bluetoothctl_(1)
  to manage bluetooth devices.
- *Upgrading and migration*: sxmo has a migration tool called _sxmo_migrate.sh_(1) which
  allows you to easily keep your custom hooks and configs up-to-date. See UPDATING.
- *Notifications system*: sxmo has an internal notifications system for texts and
  missed calls, including popups, led management, and sounds. See NOTIFICATIONS.
- *Miscellaneous*: Screen rotation, camera. See MISC.
- *Multiple devices*: sxmo supports many different kinds of devices, and users
  can easily add more. See DEVICES.
- *Environmental variables*: sxmo has a lot of environmental variables for
  configuration purposes. Users can override these with their own preferences.
  See ENVIRONMENT.

And more (not documented here):
- *SSH as a first class citizen*: Log into your phone over ssh and have full
  access to all sxmo menus and functionality.
- *Alpine Linux / PmOS Based Images*: postmarketOS's infrastructure bakes
  images that bundle sxmo and pmOS (based on Alpine Linux) which keeps things
  small, simple, and pragmatic

Sxmo was presented at LibrePlanet 2022, you can watch the video at
https://framatube.org/w/dHBrnMQeEt8Mq82KxV4zKm .

If you encounter any bugs, want to request features, or have questions. See BUGS AND SUPPORT.

# INITIALIZATION

Sxmo is typically started via _tinydm_(1), which launches the window manager of
your choice (_sway_(1) or _dwm_(1)) by invoking _sxmo_winit.sh_ or
_sxmo_xinit.sh_, respectively. Both scripts wrap around a shared _sxmo_init.sh_.
The entry points _sxmo_winit.sh_ and _sxmo_xinit.sh_ are represented by
*.desktop* files in */usr/share/wayland-sessions/* or */usr/share/xsessions*.
This implies you also can use use any other display manager that reads from
there. You may want to consider another display manager if your device is a
multi-user device.

_tinydm_(1) is a tiny automatic login manager for single user machines, meaning
it has no password prompt. For security we always recommend setting up full disk
encryption on your device. A password prompt like _unl0kr_(1) is then provided
at boot time to unlock disk encryption and unauthorized users have no access to
the system.

*Note:* You can configure the UID in */etc/conf.d/tinydm* (on systems using
openrc), or using *systemctl edit tinydm.service* (on systems using systemd).
Make sure to change this if you create a custom user. You may switch between the
two window managers in the *Power Menu* if you installed both.

Once the window manager launches, it will execute _sxmo_hook_start.sh_. Sxmo
relies on _superd_(1) to launch various services from this start hook. See
SERVICES. You can edit the start hook to start additional services.

You can edit *~/.config/sxmo/profile* to override certain common environmental
variables such as background image. This will be loaded for every shell
environment. See ENVIRONMENT. 

Note that sxmo respects the xdg specification, e.g., $XDG_CACHE_HOME, $XDG_CONFIG_HOME,
etc.

HOOKS: _sxmo_hook_start.sh_ (what executes on startup)
_sxmo_hook_wallpaper.sh_ (give the displayed wallpaper file path)

SEE ALSO: _tinydm_(1), _superd_(1)

# LOGGING

As soon as the system initialiazes, the following logs will be available in your
*$XDG_STATE_HOME* directory, which usually corresponds to *~/.local/state/*:

*sxmo.log*
	The central log for Sxmo. Various scripts output a message here via the
	_sxmo_log_ function provided by _sxmo_common.sh_.
*tinydm.log*
	Contains standard error output from various programs running in your
	sessions if you are using _tinydm_(1).
*superd.log*
	Logs the start of various sxmo (and other) background processes. 

# SERVICES

Sxmo starts various background services, depending on your device and
configuration. An overview of can be obtained by running *superctl status*.

*bonsaid*
	_bonsaid_ manages the logic for the hardware buttons, and invokes
	_sxmo_hook_inputhandles.sh_ on presses.

*dunst*
	_dunst_(1) is our notification daemon for Xorg.

*geoclue-agent*
	Proxy location data to map applications. 

*mako*
	_mako_(1) is our notification daemon for Wayland.

*mmsd-tng*
	_mmsd-tng_(1) manages incoming MMS messages.

*pipewire*
	_pipewire_(1) is a media server.

*pulseaudio*
	_pulseaudio_(1) is a sound server.

*sxmo_autosuspend*
	Manages automatic suspension after a certain idle time. 

*sxmo_bg*
	Sets the wallpaper, invokes _sxmo_hook_wallpaper.sh_ to obtain the wallpaper
	filename.

*sxmo_battery_monitor*
	This script monitors the battery status using _upower_(1) and ensures the
	status bar is updated accordingly.

*sxmo_conky*
	Starts conky (desktop widget) 

*sxmo_desktop_widget*
	Starts the desktop widget via _sxmo_hook_desktop_widget.sh_ .

*sxmo_hook_lisgd*
	Invokes _sxmo_hook_startlisgd.sh_ with launches the gesture daemon.

*sxmo_menumode_toggler*
	Configures hardware buttons for sway in menus.

*sxmo_modemmonitor*
	The modemmonitor observes the modem for incoming calls, texts and other
	status changes. It is powered by _mmcli_(1) and _dbus_monitor_(1) and
	required to receive calls and texts. It can be toggled via the *Config
	Menu*.

*sxmo_networkmonitor*
	The network monitor looks out for new wifi/mobile connections.
	It is powered by _nmcli_(1) and _dbus_monitor_(1).

*sxmo_notificationmonitor*
	Monitors for notifications and dispatches them to the notification daemon
	(_sxmo_notifs.sh monitor_)

*sxmo_soundmonitor*
	Monitors audio setup changes and updates the status bar accordingly.

*sxmo-x11-status*
	This periodically sets the status bar content on Xorg.

*sxmo_xob*
	A lightweight overlay volume/backlight/progress/anything bar for Xorg

*sxmo_wob*
	A lightweight overlay volume/backlight/progress/anything bar for Wayland

*unclutter*
	Hides the mouse pointer when not in use.

*vvmd*
	_vvmd_(1) is a lower-level daemon to receive visual voicemail. 

*wireplumber*
	Session/policy manager for _pipewire_(1).


# HOOKS

A lot of functionality is also contained in hooks (*sxmo_hook_\*.sh*). Hooks are
associated with certain events, such as starting the system, receiving a call,
or opening menu. They are called by the core system, or other hooks.

Sxmo uses $PATH to determine which hook executes. It will look first for
user-provided hooks in *~/.config/sxmo/hooks/* before it looks in
*/usr/share/sxmo/default_hooks/* for the system defaults. For example, if you
pickup a call and *~/.config/sxmo/hooks/sxmo_hook_pickup.sh* does not exist,
*/usr/share/sxmo/default_hooks/sxmo_hook_pickup.sh* will be run.

Hooks (and configuration files) are versioned with a version hash in a comment.
After upgrading your installation you are asked to run _sxmo_migrate.sh_(1) to
consolidate any new changes from our side with your own modifications. See
UPDATING.

Note that some hooks are in a device-specific subdirectory under the *hooks/*
main directory. This allows you to have hooks associated with a certain device.
See DEVICES. For instance, in */usr/share/sxmo/default_hooks/* there are several
device subdirectories, one of which will be your $SXMO_DEVICE_NAME.
Device-specific hooks go here and these take presendence over the more generic
hooks.

While you can manually copy and edit hooks to your liking,
_sxmo_hookmenu.sh_ (MENU > config > hooks) simplifies this process.

Note also that hooks do not have their own man pages. We have documented each
hook in the comment header of that hook, that also explains possible parameters
that are provided to the hook. A list of all available hooks in
alphabetical order is provided below:

*sxmo_hook_apps.sh*
	Runs when display of the App menu is requested. Allows you to override the
	apps displayed.

*sxmo_hook_block_suspend.sh*
	Runs when the system wants to suspend and contains rules that check whether
	suspension may happen or should be blocked because certain programs are
	active.

*sxmo_hook_call_audio.sh*
	Runs phone successfully enables/disables callaudio mode.

*sxmo_hook_contextmenu.sh*
	Runs when a menu is loaded and an application is active. This hook defines
	all the context menus. You may override or add menus for applications here.

*sxmo_hook_desktop_widget.sh*
	Runs when the system starts to launch a desktop widget. Used to display the
	clock via _conky_(1).

*sxmo_hook_discard.sh*
	Runs asynchronously when you discard an incoming call. Stops the ringing
	hook.

*sxmo_hook_hangup.sh*
	Runs when the user ends an incoming call.

*sxmo_hook_icons.sh*
	Runs every time we load a script, you can override icons here.

*sxmo_hook_inputhandler.sh*
	Runs when a gesture is to be interpreted. This defines all kinds of actions
	that may be triggered by gestures.

*sxmo_hook_lisgdstart.sh*
	Runs when start of the gestured daemon (_lisgd_(1)) is requested. This hook
	allows defining custom gestures.

*sxmo_hook_lock.sh*
	Runs when the system enters a locked state where typically the screen is
	still on but input is off. This is *NOT* the state lockers like
	_peanutbutter_(1) use.

*sxmo_network_down.sh*
	Runs after disconnecting from a network. Called by _sxmo_networkmonitor.sh_ .

*sxmo_network_up.sh*
	Runs after connecting to a new network. Called by _sxmo_networkmonitor.sh_ .

*sxmo_hook_network_pre_down.sh*
	Runs when a network prepares to go down. Called by _sxmo_networkmonitor.sh_ .

*sxmo_hook_network_pre_up.sh*
	Runs when a network prepares to go up. Called by _sxmo_networkmonitor.sh_ .

*sxmo_hook_notification.sh*
	Runs when a notification is received. Runs once for each notification. May
	be used for forwarding the notification over a network. Called by the
	notification monitor (_sxmo_notifs.sh monitor_).

*sxmo_hook_notifications.sh*
	Runs when the number of the notifications changes, i.e. a new one comes in
	or they are all cleared. This is used for generic things like enabling a LED
	or playing a sound. Called by the notification monitor (_sxmo_notifs.sh
	monitor_).

*sxmo_hook_missed_call.sh*
	Runs when an incoming call was missed (not picked up). Stops the ringing
	hook. Called by the modem monitor (_sxmo_modemmonitor.sh_).

*sxmo_hook_modem.sh*
	Runs when the modem changes state, used for example to pop up the PIN entry
	menu. Can be overridden to provide a PIN automatically. Called by the modem
	monitor (_sxmo_modemmonitor.sh_).

*sxmo_hook_mute_ring.sh*
	Runs when the user requests to mute an incoming call. Stops the ringing.

*sxmo_hook_pickup.sh*
	Runs when the phone accepts an incoming call. This is used to stop the ringing.

*sxmo_hook_postwake.sh*
	Runs after waking for suspension.

*sxmo_hook_scripts.sh*
	Runs when display of the Scripts menu is requested. Allows you to override
	the scripts displayed.

*sxmo_hook_sendsms.sh*
	Runs after you just sent a text message.

*sxmo_hook_sms.sh*
	Runs when a message (sms/mms/vmm) is received.

*sxmo_hook_restart_modem_daemons.sh*
	Runs when a restart of the modem is requested.

*sxmo_hook_ring.sh*
	Runs asynchronously when the phone receives an incoming call and is used to
	play a ring tone. It is stopped again by other hooks (sxmo_hook_pickup.sh ,
	sxmo_hook_discard.sh, sxmo_missed_call.sh, sxmo_hook_mute_ring.sh) and
	called by the modem monitor (_sxmo_modemmonitor.sh_).

*sxmo_hook_rotate.sh*
	Runs just after the screen was rotated (explicitly).

*sxmo_hook_start.sh*
	Runs upon system start in order to start various background services.

*sxmo_hook_statusbar.sh*
	Runs to update one of the components of the statusbar

*sxmo_hook_stop.sh*
	Runs after the system has been stopped in order to do some cleanup.

*sxmo_hook_suspend.sh*
	Runs when the system suspends, the actual suspension call is in here.

*sxmo_hook_tailtextlog.sh*
	Runs when viewing incoming text messages for a given contact.

*sxmo_hook_unlock.sh*
	Runs when the system becomes unlocked again. This state is *NOT* the state
	that screen lockers like  _peanutbutter_(1) enter after unlocking.

In further sections in this documentations, all hooks relevant to the topic in
question will be mentioned.

SEE ALSO: _sxmo_migrate.sh_(1)

# STATUSBAR

The bar located at the top of the screen displays the various workspaces that
you have available. These come the form of the numbers 1,2,3,4 (inactive
workspaces are not shown). Tapping one of these numbers will take you to that
workspace. If you are running dwm rather than sway, you will see right next to
it the layout that is activated. The default layout is a vertical stack (three
lines). On sway you may see a dedicated input mode indicated with a red
background, such as "menu" when you open a menu. The center of the bar the title
of the active window.

The right part of the bar is the statusbar, powered by _sxmobar_(1). It presents
status icons for the following:

- GSM modem state icon (i.e. what state modemmanager reports, e.g. registered, initializing, etc.)
- GSM network type icon (e.g. 2g, 3g, etc.).
- GSM network strength icon.
- Wifi icon (representing strength).
- Battery icon (representing strength).
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
keyboard (_svkbd_(1) on Xorg or _wvkbd_(1) on Wayland).

## HARDWARE BUTTONS

On devices with three buttons (power, volume raise, volume lower), the default
button bindings are:

*Volume Raise*:
	- *1 tap*: Launch Main Menu if no app open or Context Menu if app open.
	- *2 taps*: Launch Main Menu
	- *3 taps (or hold)*: Launch Window Management Menu

*Volume Lower*:
	- *1 tap*: Toggle virtual keyboard
	- *2 taps*: Toggle the window manager layout state (between monocle/tile/bstack)
	- *3 taps (or hold)*: Kill app

*Power button*:
	- *1 tap*: Transition to next state
	- *2 taps*: Transition to state after next state
	- *3 taps (or hold)*: Launch terminal

On devices with one button (power), the default button bindings are different.
Please refer to _sxmo_hook_inputhandler.sh_ for the exact details.

HOOKS: _sxmo_hook_inputhandler.sh_ (override input handling behavior)

## TOUCHSCREEN

Sxmo relies on _sway_(1) or _dwm_(1) to handle the touchscreen. You can
enable/disable touchscreen input via the *Config Menu*.

## GESTURES

Sxmo relies on _lisgd_(1) for gestures. You can enable/disable gestures via
the *Config Menu*.

These gestures are sensitive to the edge of the screen where the gesture is
initiated or where they end up, and some are sensitive to the length/distance of
the swipe. Gestures in the main part of the screen, staying clear of the edges,
are usually not interpreted and passed to the underlying application unmodified
(assuming it has gesture support).

The default gestures are visualized in the following schematic:

https://man.sr.ht/~anjan/sxmo-docs/assets/sxmo_gestures.png

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
default gestures are), _sxmo_hook_inputhandler.sh_ defines the avarious actions.

SEE ALSO: _lisgd_(1)

## VIRTUAL KEYBOARDS

A virtual keyboard is essential on mobile devices that lack a hardware keyboard.
We use _svkbd_(1) on Xorg and _wvkbd_(1) on Wayland. They contain layouts
specialized for mobile devices and suitable for a variety of international
scripts.

The default gesture to show the keyboard is to swipe up from the bottom edge.
The default gesture to hide the keyboard is to swipe down onto the bottom edge.
The default hardware key to toggle the keyboard is the volume down button.

Note that with both svkbd and wvkbd, you decide when the keyboard hides and
shows. It does not pop up automatically on selection of text input fields.

SEE ALSO: _svkbd_(1) or _wvkbd_(1).

## HARDWARE KEYBOARD

If you have a hardware keyboard such as the pinephone keyboard case this should
work out-of-the-box. If you have a bluetooth keyboard, see BLUETOOTH.

TODO: Describe dwm/sway bindings?

## STYLUS

Sxmo relies on _dwm_(1) and _sway_(1) to handle stylus input. You can
enable/disable stylus input from the *Config Menu*.

# MENUS

Menus are a central feature of sxmo and are navigable through using hardware
buttons. On three button devices:

- *Volume Raise* (upper button): Previous item
- *Volume Lower* (lower button): Next item
- *Power*: Select item

You can also simply use the touchscreen to tap your selection if you'd like as well.

The menu backend can be configured via the *$SXMO_MENU* environment variable,
which you can set in your *~/.profile*. Supported menu backends are:

- *dmenu* (only for Xorg)
- *bemenu* 
- *wofi* (Wayland only)

All are mediated via _sxmo_dmenu.sh_(1).

Note that you can also make full use of the menu system when you are connected
over SSH, just run _sxmo_appmenu.sh_(1) to start the main menu! When running in
the tty, bemenu will always serve as backend.

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

The scripts menu includes some scripts that go well with Sxmo and provide
various functionality. Some are included out of the box:

- *Web Search*: Search duckduckgo with the query provided by the user (bangs
work too) (_sxmo_websearch.sh_)
- *Timer*: A simple countdown timer script that vibrates the phones upon
completion (_sxmo_timer.sh_)
- *Screenshot*: Take a screenshot of the screen or a portion thereof
(_sxmo_screenshot.sh_)
- *Youtube*: Search youtube by keyword via a menu and then view in mpv, script
based on idiotbox (https://codemadness.org/idiotbox.html. (_sxmo_youtube.sh_)
- *Youtube (audio)*: Like above, but audio-only 
- *Weather*: United States weather forecast (by zipcode) menu script
- *RSS*: Aggregates RSS feeds and let's you view by timespan menu script (based
  on _sfeed_(1)

To add your own custom userscripts, you have two options: edit the
*~/.config/sxmo/userscripts* file or
place a shell script in the *~/.config/sxmo/userscripts/* directory.

- Option 1. Edit *~/.config/sxmo/userscripts* and write your entries in it,
  following the appmenu format *<icon> <name> ^ <should-return-to-menu> ^
  <script-path-or-command>* one entry per line. Example:

```
$icon_wtr Weather ^ 0 ^ sxmo_terminal.sh -f "Sxmo:size=5" sh -c "curl http://wttr.in/ | less -SR"
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

New submissions are welcome there.

HOOKS: _sxmo_hook_scripts.sh_ (control how userscripts are loaded)

## APPS MENU

The application menu displays a curated list of applications, provided they are
installed on your system. If you use wofi as your menu backend ($SXMO_MENU) or
if you have _j4-dmenu-desktop_(1) installed you also have an "All Apps" menu
entry that scans *\*.desktop* files dynamically.

HOOKS: _sxmo_hook_apps.sh_ (control list of apps)

## FILE BROWSER

A simple menu-based file browser.

SEE _sxmo_files.sh_(1).

## CONFIG MENU

The configuration menu provides access to various toggles for enabling,
disabling background services. 

Further configuration is done using environment variables which are set in
~/.config/sxmo/profile . See ENVIRONMENT. Various tools can also be configured
through specific configuration files. In most cases, this comes down to editing
a simple configuration in your favourite text editor.

# WINDOW MANAGEMENT

Sxmo uses tiling window managers such as _sway_(1) and _dwm_(1). This makes a
particularly good fit on mobile devices where screen estate is sparse, as
windows are automatically laid out to make maximum use of the available space.

Window management is done using menus. When you do a long press on the volume up
hardware button, the window management menu will pop up and allow to switch
layouts when multiple windows are open, and to close windows.

Windows can also be conveniently closed via a quick gesture; move with two fingers
down onto the bottom edge of the screen to close the focussed window. Focussing
windows is done by simply tapping them on the touchscreen.

# STATES AND SUSPENSION

Sxmo recognizes five basic states:

- *Unlocked* (unlock): Screen is on; touchscreen is enabled.
- *Locked* (lock): Screen is on; touchscreen is disabled. 
- *Screenoff* (screenoff): Screen is off; touchscreen is disabled. The led will also blink
  purple every few seconds to indicate that you are in this state.
- *Proximity Lock* (proximitylock/unlock): When close to your face, the screen will be off and touchscreen disabled; when
  far from your face, screen will be on and touchscreen enabled. This is used
  during phone calls, for instance.
- *Suspend*: The device is asleep in a low-power mode. 

A schema illustrates the transition between states:

https://man.sr.ht/~anjan/sxmo-docs/schemas/lock-power-states.png

Specific devices may call for specific state workflows:

On desktop systems, which is the default mode if a device is not recognised,
there are two states:

- *unlock*: The default state
- *locker*: A state that indicates that a session locker is running, preventing
  any interaction with the environment until it is unlocked with a password.

On e-ink display devices, such e-readers we often only have one state:

- *unlock*: The screen stays on while the device is suspended, which means that the power button is only a refresh of
  the suspension idle timeout, and a way to bring back interactivity.

Sxmo will also *suspend* on most devices, when this feature is available.

- *suspend*: In this state, the modem will still be
  active and monitor for incoming calls/texts but everything else will be
  suspended.

The usual workflow is this.

- If the phone is in the *unlock* state (default when you boot up) and you wish
  to suspend it, tap the power button once. This will transition to the
  *screenoff* state which will then automatically transition to the *suspend* state
  unless something is blocking it.
- If the phone is in the *suspend* state and you wish to wake it
  up, tap the power button once (to transition to the *lock* state) and then tap
  it once again to transition to the *unlock* state. (This prevents accidental
  wakeups in the pocket.)

Sxmo also handles automatic transitions from some states to others.

- It will automatically transition from *unlock* to *screenoff* after a certain
  amount of idleness (120s).
- It will automatically transition from *lock* to *screenoff* after a certain
  amount of time (8s).
- It will automatically transition from *screenoff* to *suspend* immediately
  unless something is blocking it.

You can set up suspend blockers in the _sxmo_hook_block_suspend.sh_ hook.

HOOKS:
_sxmo_hook_postwake.sh_ (what to do after waking up from suspend state),
_sxmo_hook_lock.sh_ (what to do when transitioning into lock state),
_sxmo_hook_screenoff.sh_ (what to do when transitioning into screenoff state),
_sxmo_hook_unlock.sh_ (what to do when transitioning into unlock state),
_sxmo_hook_block_suspend.sh_ (which processes should prevent the system from to
into suspension),

SEE ALSO: _sxmo_wakelock.sh_(1)

## LOCKSCREEN

On Wayland, we use _peanutbutter_(1) as our lockscreen. This locks the screen
and protects it from unauthorized acces. It shows the time and status icons when
locked. To unlock, the user has to tap any of four quadrants (1 - top left, 2 -
top right, 3 - bottom left, 4 - bottom right) in a user-defined order. This
constitutes as the passphrase and is configured via the *$PEANUTBUTTER_PASSCODE*
environment variable. It takes an integer (arbitrary length) where numbers (1-4)
correspond to the aforemention quadrants, in that order. 

NOTE: The default unlock code is 1132 (top left, top left, bottom left, top
right).

Peanutbutter needs to be explicitly installed by the user if you want a
lockscreen. It doesn't come enabled by default to prevent users from
locking themselves out due to not knowing how it works.

See _peanutbutter_(1).

# CRONJOBS

Sxmo ensures that cron jobs run and will actively wake the phone from sleep
temporarily to this end. The cron daemon is installed but not enabled in
postmarketOS. Cron has to be started manually with *rc-service crond start* and
set to start on boot with *rc-update add crond default*. We use a little program
called _mnc_(1) to wake the phone up just before the next planned cron job. We
also wrap some sxmo logic in _sxmo_rtcwake_(1) which launches the cronjob and
puts the phone back to sleep when finished.

```
*/15 * * * * sxmo_rtcwake.sh sleep 10
```

This example will wake the phone up for 10 seconds every 15 minutes.

If you omit *sxmo_rtcwake.sh* for a job, the system will *not* wake up from
suspension to execute the job.  Note that in such cases, you might want to use
*sxmo_wm.sh execwait* instead as this will set most of the sxmo environment
variables, e.g.:

```
*/15 * * * * sxmo_wm.sh execwait sleep 20
```

HOOKS: _sxmo_hook_mnc.sh_ (change the program that calculates when to wakeup)

SEE ALSO: _sxmo_rtcwake.sh_(1), _mnc_(1)

# CALLS AND TEXTING

Calling and texting is fully functional and should work out-of-the-box if your
device has a support modem. On devices with a hardware switch such as the
pinephone or Librem 5, make sure you have the modem killswitch in the enabled
position. You may also need to wait a little bit after booting before 
modem functionality becomes available. 

The scripting behind the scenes works via _mmcli_(1).

## UNLOCKING THE SIM

As long as your SIM is locked, a lock icon should appear in the status bar. Sxmo
automatically asks for your SIM's PIN code using a menu. Alternatively, you can
do so from the command-line as follows:

```
mmcli -i 0 --pin 1234
```

You could put this in _sxmo_hook_modem.sh_, but there is of course a
significant security risk involved if your device gets compromised!

HOOKS: _sxmo_hook_modem.sh_ (runs when the modem changes states)

## CALLING

To place a new call, you can use the *Dialer* entry in the Main Menu. You will
be prompted for a contact or number to dial. Once the call connects, a menu will
automatically be launched which hang up or send DTMF tones.

A proximity lock is automatically enabled that will lock and turn off your
screen during a call if you have the phone close to your ear. See STATES.

HOOKS: _sxmo_hook_call_audio.sh_ (launch programs when a call is initiated and
finished)

## SENDING TEXTS

To compose a new text message, the *Texts* entry in the menu has a *Send a Text*
entry (_sxmo_modemtext.sh_) which first prompts you for a contact (See CONTACTS) or number.
After choosing the recipient will by default be dropped into your editor (our
default is _vis_(1)) to compose your message. Once your message is as you'd like
it, exit the editor using `ZZ`/`:wq!`.  You will now be taken to a new menu to
confirm your message from which you can edit/send/add recipients/add
attachments/cancel the message.

HOOKS: _sxmo_hook_sendsms.sh_ (what to do when sending sms/mms)

SEE ALSO: _sxmo_modemsendsms.sh_(1)

## READING TEXTS

To view existing text message threads you can use the *Texts* entry in the Main
Menu. This menu will let you follow a text file, as it changes, containing your
conversation with each number. When a new text is sent or received; the message
will automatically be displayed in your standard $PAGER.

While displaying the conversation you can pop out a contextual menu with
power up button to reply by text or to start a call with the sender

You can also open a "conversation" window with a gesture from the bottom edge. It will
open your editor and the virtual keyboard to type your sms. Save and close the
file to send the sms. A new editor will be opened again to type a new
message.

HOOKS: _sxmo_hook_tailtextlog.sh_ (you can edit this to control the look and
feel of view of message text, e.g., colors, etc.)

## MONITORING FOR INCOMING CALLS AND TEXTS

A vital feature of a working phone is being able to receive new texts and pickup
calls. This functionality is made possible through a script
(_sxmo_modemmonitor.sh_) that monitors the modem activities and vibrates the
phone, plays a notification or ringing sound, and blinks the green LED when
there is an incoming text/call. This monitor is automatically run on start but
can be disabled via the menu.

While a call is incoming:

- The phone will ring and vibrate (unless you disabled these in the *Audio menu*
  or in your hooks).
- A green notification LED will be enabled if your device has one.
- A menu will appear to allow you to pickup the call. You can also discard
  the call or ignore the call (mute the ring) from that menu. If you missed the
  menu for any reason, you can always open
  the global system menu menu and you'll
  see a menu entry to pickup the call; of course this is time-sensitive and this
  menu entry will only be visible while the other party's line is ringing

HOOKS:
_sxmo_hook_call_audio.sh_ (adjust volume level when starting/ending call),
_sxmo_hook_discard.sh_ (if you hangup without answering),
_sxmo_hook_hangup.sh_ (if you hangup),
_sxmo_hook_missed_call.sh_ (if you miss the call),
_sxmo_hook_mute_ring.sh_ (if you tap ignore to ignore the call, i.e., mute the
ringing),
_sxmo_hook_pickup.sh_ (if you pickup),
_sxmo_hook_ring.sh_ (what to do when ringing)

When a new text message comes in:

- The phone will play a notification sound and vibrate (unless you disabled
  these in the *Audio menu*.
- A green notification LED will be enabled if your device has one.
- A popup notification will appear.

For more information on viewing incoming messages: See READING TEXTS.

HOOKS:
_sxmo_hook_sms.sh_(1) (what to do when an sms/mms is received)

# NETWORK CONFIGURATION

The *Networks* menu (_sxmo_networks.sh_(1)) provides access various kinds of
network configuration.

## WIFI

From the *Networks* select *Add a WPA network*. This first scans the networks in
your vicinity and shows their SSIDs in a menu. Subsequent selection of one will
prompt for the password.

Alternatively, you can launch _nmtui_(1) for more in-depth configuration.

If your device has a wifi killswitch (like the Pinephone or Librem 5), make sure
it is in the enabled position.

HOOKS: _sxmo_hook_network_up.sh_ (what to do when network goes up),
_sxmo_hook_network_down.sh_ (what to do when network goes down),
_sxmo_hook_network_pre_up.sh_,
_sxmo_hook_network_pre_down.sh_

## MOBILE DATA

Mobile data (GSM) can be added via the *Networks* Menu (_sxmo_networks.sh_). It will
ask for an APN. It is a wrapper around _nmcli_(1).

## CONFIGURING MMS

To configure MMS, go to *Config*.

MMS messaging should work just like regular text messaging.  When you *Send a
Text* there will be the option to add multiple recipients or attachments.  To
make mms work, sxmo relies on _mmsd-tng_(1).  The
main configuration will be located in *~/.mms/modemmanager/mms*. To make things
easier in sxmo, we have a dedicated menu entry in *Config* called
*Config MMS*. This menu will create a default config and you then can edit
fields one by one.  The script should take care of restarting mmsd when closed.

*Note* that you likely will *not* have to configure _mmsd-tng_, if your settings
are already in
https://wiki.gnome.org/Projects/NetworkManager/MobileBroadband/ServiceProviders.
Consider contributing your own if it is not.

*Note* that your carrier's nameserver must be present in */etc/resolv.conf* in
order to send/receive mms.  This should be automatic.  However, sometimes
NetworkManager will place the wifi's nameservers *above* the carrier's
nameservers, and since */etc/resolv.conf* can only use the first three entries,
the carrier's nameservers will not be used.  To fix this, you can set dns=none
in */etc/NetworkManager/NetworkManager.conf* and use a static */etc/resolv.conf*
instead.

## BLOCKING NUMBERS

You can block incoming calls and texts by adding the numbers to
*~/.config/sxmo/block.tsv* (this filename is actually stored in
*$SXMO_BLOCKFILE*). It syntax is the same as the contacts file. See CONTACTS.

# CONTACTS

The sxmo contacts system is based on a plain TSV file that can be placed at
*~/.config/sxmo/contacts.tsv* (the actual filename is actually kept in the
*$SXMO_CONTACTFILE* environment variable, here we assume the default). This TSV
file is expected to have two tab separated columns: phonenumber, and
contactname. Upon receiving a call, if you have a contact stored associated with
the incoming number, the contact name will be displayed instead of the number.
Contact names will also appear in the Texts and Dialer menus if they are present
in the contacts TSV file. If no *contacts.tsv* is present, or the number is
missing from this file; the contact in menus will show up as *???*. A
*contacts.tsv* example might look like:

```
+122345628	John Smith
+128371642	Jeff Foo
+31612345678	Jan Janssen
```

You may edit the file in an editor of your choice or use the *New Contact* entry
from the *Contacts* menu.

SEE ALSO: _sxmo_contacts.sh_(1), _sxmo_contactmenu.sh_(1)

# AUDIO

You can use the *Audio Menu* (_sxmo_audio.sh_) to toggle which audio output you
want to send sound to. Sxmo uses _pipewire_(1) and _pulseaudio_(1). We use
_callaudiod_(1) to route audio during a phone call.

Currently, bluetooth audio during phone calls does not work. Please see:

- https://gitlab.com/mobian1/issues/-/issues/345
- https://gitlab.com/mobian1/callaudiod/-/issues/12

SEE ALSO: _sxmo_hook_call_audio.sh_ (adjust volume after/before a call)

# BLUETOOTH

To enable bluetooth, toggle it in *Config*. A *Bluetooth Menu*
(_sxmo_bluetoothmenu.sh_) can be chosen from the *Main Menu*.

# UPDATING

Sxmo's packages are typically distributed via your Linux distribution (e.g.
postmarketOS). To update run:

```
sxmo_upgrade.sh
```

...or just use the menu entry within the *Config Menu* which does the same.
This is a just tiny wrapper that invokes your distribution's package manager.

After you update the sxmo packages themselves, be sure to run
_sxmo_migrate.sh_(1) to guide you through upgrading your (local) config files
and hooks, if needed. Your configuration files and hooks may be temporarily
stashed away until you complete the migration process. This is so the system can 
remain fully functional at all times. See _sxmo_migrate.sh_(1) for further
documentation on this.

New releases will be announced on the ~mil/sxmo-announce@lists.sr.ht mailing
list. See https://lists.sr.ht/~mil/sxmo-announce for the archives.
Mail ~mil/sxmo-announce+subscribe@lists.sr.ht to automatically subscribe.

SEE ALSO: _sxmo_migrate.sh_(1)

# NOTIFICATIONS

When a notification comes in, the status bar will indicate this with an icon,
and the menu will have a *Notifications* entry that also mentioned the number of
unread notifications. They can be viewed and cleared through this submenu. 

If your device has a green status LED, it will be default be enabled when you
have unread notifications.

Notifications are mediated by _sxmo_notifs.sh_. Whenever a notification comes in
or is cleared, then _sxmo_hook_notifications.sh_ will be called with the number of
notifications. This puts an icon status in the status bar if there are any
notifications. For each specific notification, _sxmo_hook_notification.sh_ is
called. This hook can be used, for instance, to forward the notification content
over a network.

HOOKS: _sxmo_hook_notifications.sh_ (runs when there is any notification),
_sxmo_hook_notification.sh_ (runs once for each notification)

See _sxmo_notifs.sh_(1)

# DEVICES

This section describes how to add a new device to sxmo. If you are instead
looking for what devices are suitable to run Sxmo, then check the **postmarketOS
device page** at https://wiki.postmarketos.org/wiki/Devices instead.

When adding a new device, there are three basic steps:

- Determine the *$SXMO_DEVICE_NAME*
- Add a *sxmo_deviceprofile_${SXMO_DEVICE_NAME}.sh* file to
  *scripts/deviceprofiles/* in the source tree. Please send us the patch too.
- Add (or symlink to an existing) SXMO_DEVICE_NAME folder in
  *configs/default_hooks/* in the source tree.

## FINDING THE SXMO_DEVICE_NAME

The *$SXMO_DEVICE_NAME* is determined by the following code in *sxmo_init.sh* upon
boot:

```
tr -c '\0[:alnum:].,-' '_' < /proc/device-tree/compatible | tr '\0' '\n' | head -n1
```

## ADDING A DEVICEPROFILE FILE

In the source tree navigate to *scripts/deviceprofiles/* and make a file called
*sxmo_deviceprofile_SXMO_DEVICE_NAME.sh*.  This file should contain various
environment variables that define things unique to your device, e.g., input ids, etc.
There is a *README.md* in the same directory that will help.

## DEVICE PROFILE VARIABLES

The following variables are used in device profiles, see DEVICES.

*SXMO_DISABLE_KEYBINDS* (input)
	If set, this disables most custom Sxmo binds on the volume keys.
*SXMO_LISGD_THRESHOLD* (input)
	Threshold for detecting touches [default: 125]
*SXMO_LISGD_THRESHOLD_PRESSED* (input)
	Threshold for detecting long presses [default: 60]
*SXMO_LISGD_INPUT_DEVICE* (input)
	Input device [default: /dev/input/by-path/first/touchscreen]
*SXMO_MIN_BRIGHTNESS* (display)
	Minimum brightness level (default: 5)
*SXMO_MODEM_GPIO_KEY_RI* (modem)
	If the modem driver handles gpio, sxmo has to know to disable the events
	from this input source. This is the name of the input device.
*SXMO_MONITOR* (display)
	The name of the output device for the primary display (e.g. DSI-1). The
	output can be found with `swaymsg -t get_outputs` or `xrandr` when running
	dwm.
*SXMO_NO_VIRTUAL_KEYBOARD* (input)
	If defined, all virtual keyboard management is disabled, and some related
	gesture behavior is changed.
*SXMO_NO_MODEM* (modem)
	Define this if your device has no modem, modem-related functionality will be
	disabled.
*SXMO_POWER_BUTTON* (input)
	Power button "Identifier" from *swaymsg -t get_inputs* command.
*SXMO_ROTATE_DIRECTION* (display)
	The direction to rotate when using the gesture [default: right]
*SXMO_ROTATE_START* (display)
	Should the display rotate on start? (useful when the device is landscape by default)
*SXMO_STATES* (states)
	Space separated list of states this device can be in. See STATES.
*SXMO_STYLUS_ID* (input)
	ID (from xinput) for the stylus device [DWM-ONLY] [default: 10]
*SXMO_SUSPENDABLE_STATES* (states)
	The list of suspendable states, with their timeout duration [default: "screenoff 3"]
*SXMO_TOUCHSCREEN_ID* (input)
	ID (from xinput) for the touchscreen device [DWM-ONLY] [default: 10]
*SXMO_VIBRATE_DEV* (misc)
	Path to vibration device (see sxmo_vibrate.c and clickclack.c) [default: /dev/input/by-path/platform-vibrator-event]
*SXMO_VIBRATE_STRENGTH* (misc)
	Strength parameter to pass to sxmo_vibrate [default: 1]
*SXMO_VOLUME_BUTTON* (input)
	Volume button "Identifier" from *swaymsg -t get_inputs* command. If the
	volume up identifier (*$VOL_UP_ID*) is different from the volume down
	identifier (*$VOL_DOWN_ID*), set *$SXMO_VOLUME_BUTTON="$VOL_UP_ID
	$VOL_DOWN_ID"*. See for example the
	sxmo-utils/scripts/deviceprofiles/sxmo_deviceprofile_xiaomi,beryllium.sh
	file.

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

This sections explains some smaller miscellaneous aspects of Sxmo.

## ROTATION

Rotating the screen (from portrait to landscape) can be done either
automatically or manually. Automatic rotation can be enabled or disable
via the *Config Menu*. The _sxmo_rotate.sh_ script performs the actual rotation.

A default gesture is also available to rotate, swipe from the bottom-right
corner towards the center.

## FLASHLIGHT

If your device has a flashlight, you can toggle it via the main menu.

## CAMERA

If your device has a suppored camera, you can launch a viewer to take photos and
videos via the main menu.

# ENVIRONMENT

Hint: type *env* to see environmental variables. Environmental variables can be
overridden (generally) in *~/.config/sxmo/profile* or *~/.profile*. See also
*~/.Xdefaults*, *~/.config/sxmo/xinit*, and *~/.config/sxmo/sway*.

sxmo respects the xdg protocal, falling back to some sane defaults if this is
missing on your system. The most relevant ones are:

*XDG_DATA_HOME*
	~/.local/share
*XDG_CONFIG_HOME*
	~/.config
*XDG_CACHE_HOME*
	~/.cache
*XDG_STATE_HOME*
	~/.local/state
*XDG_RUNTIME_DIR*
	/dev/shm/$USER/1000
*XDG_DATA_DIRS*
	~/.local/share

The default values for environment variables are set in 
*/etc/profile.d/sxmo_init.sh* . If you want to override them, use your
*~/.profile*. Sxmo itself defines the following variables, in alphabetical order:


*DEFAULT_COUNTRY*
	String to indicate the default country sxmo should fallback to when the
	phone numbers are not country code prefixed. Should be set to a country code
	(iso-3166) such as *FR* for France, *DE* for Germany, *US* for the Unites
	States. See CONTACTS.
*KEYBOARD*
	the virtual keyboard used, defaults to *svkbd-mobile-intl* (_svkbd_(1)) on
	Xorg on *wvkbd-mobile-intl* on Wayland.
*KEYBOARD_ARGS*
	parameters to pass to the virtual keyboard upon launch
*SXMO_BLOCKDIR*
	blocked number metadata (~/.local/share/modem/block).
*SXMO_BLOCKFILE*
	A file with phone numbers to block (~/.config/sxmo/block.tsv).
*SXMO_CACHEDIR*
	temporary cache files (~/.cache/sxmo)
*SXMO_CONTACTFILE*
	a TSV file containing contacts (~/.config/sxmo/contacts.tsv)
*SXMO_DEBUG*
	if defined, extra debug messages will appear in ~/.local/state/sxmo.log .
*SXMO_DEFAULT_DRAFT*
	a string containg the default draft text for text messages.
*SXMO_DEVICE_NAME*
	the device name. Sxmo will also load all the variables in
	*/usr/bin/sxmo_deviceprofile_$SXMO_DEVICE_NAME.sh*, such as id for touch
	input, whether the device has leds, and so on. See DEVICES.
*SXMO_LOGDIR* 
	where sxmo logs metadata about calls and texts received. Under this
	directory, there will be several subdirectories, one for each number, which
	contain the content of the text messages received. (~/.local/share/modem)
*SXMO_MENU* 
	The menu program to use. This must be either _dmenu_(1), _bemenu_(1) or
	_wofi_(1), you can not just specify an arbitrary binary here as Sxmo must
	have internal support for it.
*SXMO_NOTIFDIR*
	The directory where notifications are stored (mediated by
	_sxmo_notifs.sh_(1))
*SXMO_OS* 
	the distribution (postmarketos, archlinux, etc.)
*SXMO_TERMINAL*
	Terminal to launch. Defaults to _foot_(1)  on wayland or _st_(1) on Xorg.
	Launching a terminal is mediated via _sxmo_terminal.sh_, which reads this
	variable.
*SXMO_RINGTONE*
	The audio file to play when the phone is ringing.
*SXMO_RINGNUMBER*
	The number of times the audio file will play.
*SXMO_STATE*
	the file containing the current state
*SXMO_SWAY_SCALE*
	the scaling factor to use for sway 
*SXMO_TEXTSOUND*
	The audio file to play when the phone is receives a text.
*SXMO_VIBRATE_STRENGTH*
	The vibration strength to pass to the haptic feedback when a text arrives. 
*SXMO_WM*
	the window manager used (sway or dwm)


Other relevant environment variables are, in alphabetical order:

*BROWSER*
	default web browser
*DMENU_WRAP_AROUND*
	If set to 1, when scrolling past the beginning or end of a menu, wraps
	around it (dmenu only)
*DBUS_SESSION_BUS_ADDRESS*
	dbus socket
*BEMENU_OPTS*
	options to pass to bemenu
*EDITOR*
	default text editor
*MOZ_ENABLE_WAYLAND*
	Set to 1 when running under Wayland.
*PATH* 
	the system path, this will be set to look in
	~/.config/sxmo/hooks/$SXMO_DEVICE_NAME/,
	/usr/share/sxmo/hooks/$SXMO_DEVICE_NAME/,  ~/.config/sxmo/hooks/, and
	~/usr/share/sxmo/hooks/ before the regular PATH the operating system sets.
*SDL_VIDEODRIVER*
	Set to value *wayland* when running under Wayland.
*SHELL*
	default shell
*SWAYSOCK*
	sway socket
*XDG_CURRENT_DESKTOP*
	The current desktop (sway or dwm)

*Hint:* you can type *\_sxmo_grab_session* from the commandline to reload
environment variables (e.g., if you switch window managers but are logged in
over an ssh connection).

There are other environmental variables that are device specific. See DEVICES.
As well, several scripts have their own environmental variables which we do not
list here.

# FILES

~/.local/state/sxmo.log - sxmo's logfiles. See LOGGING.

~/.config/sxmo - most sxmo config files

~/.config/sxmo/profile - profile where you can customise environment variables. See ENVIRONMENT.

~/.config/sxmo/hooks - your user-defined hooks. See HOOKS.

~/.config/sxmo/userscripts - either a file or a directory containing your
userscripts. See MENUS.

# AUTHORS

Sxmo is developed by a wide community of contributors, to whom we are all
grateful. See the git log for full details.

# MAINTAINERS

- Anjandev Momi <anjan@momi.ca>
- Aren Moynihan <aren@peacevolution.org>
- Maarten van Gompel <proycon@anaproy.nl>
- Willow Barraco <contact@willowbarraco.fr>

Former maintainers:

- Miles Alan <m@milesalan.com> (the original creator of Sxmo)
- Peter John Hartman <peterjohnhartman@gmail.com>

# BUGS AND SUPPORT

We have the following support channels for questions and bug reports:

*~mil/sxmo-announce@lists.sr.ht* (e-mail)
	This is a low-volume read-only mailing list used for announcing new package
	releases. See https://lists.sr.ht/~mil/sxmo-announce . 

*~mil/sxmo-devel@lists.sr.ht* (e-mail)
	This is our primary asynchronous *developer* support channel where you can
	send code contributions as patches via _git-send-email_(1). See https://lists.sr.ht/~mil/sxmo-devel .

*~mil/sxmo-user@lists.sr.ht* (e-mail)
	This is our primary asynchronous *user* support channel where you can send
	questions, bug reports, and featVure requests. Please check if your question
	is not already answered before posting. Here you can also discuss the
	general goals of the project, your experience daily driving, and have other
	fun discussions with the Sxmo community. See https://lists.sr.ht/~mil/sxmo-user .

*https://todo.sr.ht/~mil/sxmo-tickets* (web)
	This is our bug/feature tracker. It is for confirmed bugs and tracking
	feature requests. Not for user support. See https://todo.sr.ht/~mil/sxmo-tickets .

*#sxmo* (IRC)
	We have the channel *#sxmo* and *#sxmo-offtopic* on the OFTC IRC Network
	(*irc.oftc.net*). Here you can talk to Sxmo users and developers in
	realtime. Moreover, you can get help with Sxmo and related projects. Please
	stay around for answers when asking questions. A web-based chat is available
	via https://webchat.oftc.net/?channels=#sxmo

*#otfc#sxmo:matrix.org* (Matrix)
	This is a Matrix bridge to the IRC chat. See https://matrix.to/#/#\_oftc\_#sxmo:matrix.org .

*PostmarketOS Wiki* (web)
	The postmarketOS Wiki contains user-maintained Tips & Tricks pages for Sxmo
	like https://wiki.postmarketos.org/wiki/Sxmo/Tips_and_Tricks . 

There are a number of communities working on FOSS mobile distros, middleware,
apps, and hardware development. You can join the other chatrooms related to FOSS
mobile via the following matrix space:

https://matrix.to/#/#FOSSMobile:matrix.org

# COPYRIGHT

Sxmo is licensed under the GNU Affero General Public License v3.

# SEE ALSO

_sxmo_appmenu.sh_(1)
_sxmo_files.sh_(1)
_sxmo_migrate.sh_(1)
_sxmo_wakelock.sh_(1)
_lisgd_(1)
_peanutbutter_(1)
_svkbd_(1)
_wvkbd_(1)

DESTDIR=
PREFIX:=/usr
SYSCONFDIR:=/etc
SHAREDIR=$(PREFIX)/share
MANDIR=$(SHAREDIR)/man

# use $(PREFIX)/lib/systemd/user for systemd integration
SERVICEDIR:=$(PREFIX)/share/superd/services

# Install services for packages outside sxmo
EXTERNAL_SERVICES:=1

SCDOC=scdoc

.PHONY: install shellcheck

VERSION:=1.13.0

GITVERSION:=$(shell git describe --tags)

OPENRC:=1

CC ?= $(CROSS_COMPILE)gcc
PROGRAMS = \
	programs/sxmo_aligned_sleep \
	programs/sxmo_vibrate

DOCS = \
	docs/sxmo.7

docs/%: docs/%.scd
	$(SCDOC) <$< >$@

all: $(PROGRAMS) $(DOCS)

test: shellcheck

shellcheck:
	find . -type f -name '*.sh' -print0 | xargs -0 shellcheck -x --shell=sh

programs/%: programs/%.c
	$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) -o $@ $<

clean:
	rm -f programs/sxmo_aligned_sleep programs/sxmo_vibrate

install: install-sway install-dwm install-scripts install-docs

install-docs: $(DOCS)
	cd docs && find . -type f -name '*.7' -exec install -D -m 0644 "{}" "$(DESTDIR)$(MANDIR)/man7/{}" \; && cd ..

install-sway:
	install -D -m 0644 -t $(DESTDIR)$(PREFIX)/share/wayland-sessions/ configs/applications/swmo.desktop

install-dwm:
	install -D -m 0644 -t $(DESTDIR)$(PREFIX)/share/xsessions/ configs/applications/sxmo.desktop

install-scripts: $(PROGRAMS)
	cd configs && find . -type f -not -name sxmo-setpermissions -exec install -D -m 0644 "{}" "$(DESTDIR)$(PREFIX)/share/sxmo/{}" \; && cd ..

	rm -rf "$(DESTDIR)$(PREFIX)/share/sxmo/default_hooks/"
	cd configs && find default_hooks -type f -exec install -D -m 0755 "{}" "$(DESTDIR)$(PREFIX)/share/sxmo/{}" \; && cd ..
	cd configs && find default_hooks -type l -exec cp -R "{}" "$(DESTDIR)$(PREFIX)/share/sxmo/{}" \; && cd ..

	[ -n "$(GITVERSION)" ] && echo "$(GITVERSION)" > "$(DESTDIR)$(PREFIX)/share/sxmo/version" || echo "$(VERSION)" > "$(DESTDIR)$(PREFIX)/share/sxmo/version"

	cd resources && find . -type f -exec install -D -m 0644 "{}" "$(DESTDIR)$(PREFIX)/share/sxmo/{}" \; && cd ..

	install -D -m 0644 -t $(DESTDIR)$(PREFIX)/lib/udev/rules.d/ configs/udev/*.rules

	install -D -m 0644 -t $(DESTDIR)$(PREFIX)/share/applications/ configs/xdg/mimeapps.list

	install -D -m 0640 -t $(DESTDIR)$(SYSCONFDIR)/doas.d/ configs/doas/sxmo.conf

	install -D -m 0644 -T configs/xorg/monitor.conf $(DESTDIR)$(PREFIX)/share/X11/xorg.conf.d/90-monitor.conf

	mkdir -p $(DESTDIR)$(SYSCONFDIR)/NetworkManager/dispatcher.d

	install -D -m 0644 -T configs/appcfg/mpv_input.conf $(DESTDIR)$(SYSCONFDIR)/mpv/input.conf

	install -D -m 0755 -T configs/profile.d/sxmo_init.sh $(DESTDIR)$(SYSCONFDIR)/profile.d/sxmo_init.sh

	# Migrations
	install -D -t $(DESTDIR)$(PREFIX)/share/sxmo/migrations migrations/*

	# Bin
	install -D -t $(DESTDIR)$(PREFIX)/bin scripts/*/*.sh

	install -D programs/sxmo_aligned_sleep $(DESTDIR)$(PREFIX)/bin/
	install -D programs/sxmo_vibrate $(DESTDIR)$(PREFIX)/bin/

	find $(DESTDIR)$(PREFIX)/share/sxmo/default_hooks/ -type f -exec ./setup_config_version.sh "{}" \;
	find $(DESTDIR)$(PREFIX)/share/sxmo/appcfg/ -type f -exec ./setup_config_version.sh "{}" \;

	# Appscripts
	mkdir -p "$(DESTDIR)$(PREFIX)/share/sxmo/appscripts"
	cd scripts/appscripts && find . -name 'sxmo_*.sh' | xargs -I{} ln -fs "$(PREFIX)/bin/{}" "$(DESTDIR)$(PREFIX)/share/sxmo/appscripts/{}" && cd ../..

	mkdir -p "$(DESTDIR)$(SERVICEDIR)"
	install -m 0644 -t "$(DESTDIR)$(SERVICEDIR)" configs/services/*
	if [ "$(EXTERNAL_SERVICES)" = "1" ]; then \
		install -m 0644 -t "$(DESTDIR)$(SERVICEDIR)" configs/external-services/*; \
	fi

	@echo "-------------------------------------------------------------------">&2
	@echo "NOTICE 1: Do not forget to add sxmo-setpermissions to your init system, e.g. for openrc: rc-update add sxmo-setpermissions default && rc-service sxmo-setpermissions start" >&2
	@echo "-------------------------------------------------------------------">&2
	@echo "NOTICE 2: After an upgrade, it is recommended you reboot and when prompted run sxmo_migrate.sh to check and upgrade your configuration files and custom hooks against the defaults (it will not make any changes unless explicitly told to)" >&2
	@echo "-------------------------------------------------------------------">&2

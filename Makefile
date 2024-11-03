DESTDIR=
PREFIX:=/usr
SYSCONFDIR:=/etc
SHAREDIR=$(PREFIX)/share
MANDIR=$(SHAREDIR)/man

CFLAGS := -Wall -std=c99 -D_POSIX_C_SOURCE=200809L $(CFLAGS)

# use $(PREFIX)/lib/systemd/user for systemd integration
SERVICEDIR:=$(PREFIX)/share/superd/services

# Install services for packages outside sxmo
EXTERNAL_SERVICES:=1

SCDOC=scdoc
SCD2HTML=scd2html
SCD2HTMLFLAGS =

.PHONY: install test shellcheck shellspec test_legacy_nerdfont docs html-docs \
	install-docs install-html-docs install-sway install-dwm install-scripts

VERSION ?= unknown

# git archive will expand $Format:true$ to just true, so we can use it to check
# if we should use the version from the tarball, or to generate it now.
ifeq "$Format:true$" "true"
	VERSION := $Format:%(describe:tags)$
else
	VERSION := $(shell git -c safe.directory="*" describe --tags)
endif

OPENRC:=1

CC ?= $(CROSS_COMPILE)gcc
PROGRAMS = \
	programs/sxmo_aligned_sleep \
	programs/sxmo_sleep \
	programs/sxmo_vibrate \
	programs/sxmo_status_led

DOCS = \
	docs/sxmo.7 \
	docs/sxmo_wakelock.sh.1 \
	docs/sxmo_migrate.sh.1 \
	docs/sxmo_files.sh.1 \
	docs/sxmo_contacts.sh.1 \

HTMLDOCS := $(DOCS:%=%.html)


all: $(PROGRAMS) $(DOCS)

# We convert from SCDOC to HTML , the HTML conversion
# we apply some postprocessing for better internal hyperlinks and styling.
docs/%.html: docs/%.scd
	$(SCD2HTML) $(SCD2HTMLFLAGS) < "$<" | \
		sed -E -e 's/Georgia/Sans/g' \
			-e 's/Menlo/FiraMono Nerd Font, Sxmo, Menlo/g' \
			-e 's/See ([A-Z ]+)\./See <a href="#\1">\1<\/a>./g' \
			-e 's/\(see ([A-Z ]+)\)/(see <a href="#\1">\1<\/a>)/g' \
			-e 's/<u>sxmo_([a-z_\.]+)<\/u>\(([1-9])\)/<a href="sxmo_\1.\2.html"><u>sxmo_\1<\/u><\/a>(\2)/g' | \
		sed -e ':loop' \
    		-e 's/\(href="[^" ]*\) \([^"]*"\)/\1_\2/' \
        	-e 't loop' > "$@" #this last sed statement replace spaces in href attributes with underscores

docs/%: docs/%.scd
	$(SCDOC) <$< >$@

docs: $(DOCS)

html-docs: $(HTMLDOCS)

test: shellcheck shellspec test_legacy_nerdfont test_status_led

shellcheck:
	find . -type f -name '*.sh' -print0 | xargs -0 shellcheck -x --shell=sh

shellspec: ${PROGRAMS}
	shellspec

test_status_led: programs/sxmo_status_led.test
	./programs/sxmo_status_led.test

test_legacy_nerdfont: programs/test_legacy_nerdfont
	programs/test_legacy_nerdfont < configs/default_hooks/sxmo_hook_icons.sh

programs/sxmo_status_led: LDLIBS := -lm
programs/sxmo_status_led.test: LDLIBS := -lm
programs/test_legacy_nerdfont: LDLIBS := $(shell pkg-config --cflags --libs icu-io)

programs/%: programs/%.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $< $(LOADLIBES) $(LDLIBS) -o $@ 

# only used for sxmo_status_led
programs/%.test: programs/%.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -DTEST $(LDFLAGS) $< $(LOADLIBES) $(LDLIBS) -o $@ 

clean:
	rm -f ${PROGRAMS} ${DOCS} ${HTMLDOCS} programs/test_legacy_nerdfont programs/sxmo_status_led.test

install: install-sway install-dwm install-scripts install-docs

install-docs: $(DOCS)
	cd docs && find . -type f -name '*.7' -exec install -D -m 0644 "{}" "$(DESTDIR)$(MANDIR)/man7/{}" \; && find . -type f -name '*.1' -exec install -D -m 0644 "{}" "$(DESTDIR)$(MANDIR)/man1/{}" \; && cd ..

install-html-docs: $(HTMLDOCS)
	cd docs && find . -type f -name '*.html' -exec install -D -m 0644 "{}" "$(DESTDIR)$(PREFIX)/share/doc/sxmo/html/{}" \; && cd ..

install-sway:
	install -D -m 0644 -t $(DESTDIR)$(PREFIX)/share/wayland-sessions/ configs/applications/swmo.desktop

install-dwm:
	install -D -m 0644 -t $(DESTDIR)$(PREFIX)/share/xsessions/ configs/applications/sxmo.desktop

install-scripts: $(PROGRAMS)
	cd configs && find . -type f -not -exec install -D -m 0644 "{}" "$(DESTDIR)$(PREFIX)/share/sxmo/{}" \; && cd ..

	rm -rf "$(DESTDIR)$(PREFIX)/share/sxmo/default_hooks/"
	cd configs && find default_hooks -type f -exec install -D -m 0755 "{}" "$(DESTDIR)$(PREFIX)/share/sxmo/{}" \; && cd ..
	cd configs && find default_hooks -type l -exec cp -R "{}" "$(DESTDIR)$(PREFIX)/share/sxmo/{}" \; && cd ..

	echo "$(VERSION)" > "$(DESTDIR)$(PREFIX)/share/sxmo/version"

	cd resources && find . -type f -exec install -D -m 0644 "{}" "$(DESTDIR)$(PREFIX)/share/sxmo/{}" \; && cd ..

	install -D -m 0644 -t $(DESTDIR)$(PREFIX)/lib/udev/rules.d/ configs/udev/*.rules

	install -D -m 0644 -t $(DESTDIR)$(PREFIX)/share/applications/ configs/xdg/mimeapps.list

	install -D -m 0644 -t $(DESTDIR)$(SYSCONFDIR)/polkit-1/rules.d/ configs/polkit/01-sensor-claim.rules

	install -D -m 0640 -t $(DESTDIR)$(SYSCONFDIR)/doas.d/ configs/doas/sxmo.conf

	install -D -m 0644 -T configs/xorg/monitor.conf $(DESTDIR)$(PREFIX)/share/X11/xorg.conf.d/90-monitor.conf

	mkdir -p $(DESTDIR)$(SYSCONFDIR)/NetworkManager/dispatcher.d

	install -D -m 0644 -T configs/appcfg/mpv_input.conf $(DESTDIR)$(SYSCONFDIR)/mpv/input.conf

	install -D -m 0755 -T configs/profile.d/sxmo_init.sh $(DESTDIR)$(SYSCONFDIR)/profile.d/sxmo_init.sh

	# Migrations
	install -D -t $(DESTDIR)$(PREFIX)/share/sxmo/migrations migrations/*

	# Bin
	install -D -t $(DESTDIR)$(PREFIX)/bin scripts/*/*.sh

	install -t $(DESTDIR)$(PREFIX)/bin/ ${PROGRAMS}
	setcap 'cap_wake_alarm=ep' $(DESTDIR)$(PREFIX)/bin/sxmo_sleep

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
	@echo "NOTICE: After an upgrade, it is recommended you reboot and when prompted run sxmo_migrate.sh to check and upgrade your configuration files and custom hooks against the defaults (it will not make any changes unless explicitly told to)" >&2
	@echo "-------------------------------------------------------------------">&2

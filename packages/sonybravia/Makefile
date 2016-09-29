PREFIX    ?= /usr/local
BINPREFIX ?= $(PREFIX)/bin
SHRPREFIX ?= $(PREFIX)/share/sonybravia
BUILDDIR  ?= build

CSCRIPT   := ../../compile.sh
CFLAGS    += -O -a /home/jaagr/.local/lib/sh -s "'/usr/bin/env bash'"

all: build

build:
	mkdir -p -v $(BUILDDIR)
	for f in sonybravia-*; do \
		$(CSCRIPT) $$f $(BUILDDIR)/$$f $(CFLAGS) ; \
	done
	sed -i "s|commands.json|$(DESTDIR)$(SHRPREFIX)/commands.json|g" $(BUILDDIR)/sonybravia-ctl

install:
	for f in sonybravia-*; do \
		install -Dvm755 $(BUILDDIR)/$$f $(DESTDIR)$(BINPREFIX)/$$f ; \
	done
	install -Dm755 commands.json $(DESTDIR)$(SHRPREFIX)/commands.json

uninstall:
	for f in sonybravia-*; do \
		rm -vf $(DESTDIR)$(BINPREFIX)/$$f ; \
	done
	rm -vf $(DESTDIR)$(SHRPREFIX)/commands.json

clean:
	rm -rf build

.PHONY: build install uninstall clean

# vim:ts=2 sw=2 noet nolist

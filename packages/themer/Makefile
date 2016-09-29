PREFIX    ?= /usr/local
BINPREFIX ?= $(PREFIX)/bin
ZSHCOMP   ?= $(PREFIX)/share/zsh/site-functions
BUILDDIR  ?= build

CSCRIPT   := ../../compile.sh
CFLAGS    += -O -a /home/jaagr/.local/lib/sh -s "'/usr/bin/env bash'"

all: build

build:
	mkdir -p -v $(BUILDDIR)
	for f in theme-*; do \
		$(CSCRIPT) $$f $(BUILDDIR)/$$f $(CFLAGS) ; \
	done

install:
	for f in theme-*; do \
		install -Dvm755 $(BUILDDIR)/$$f $(DESTDIR)$(BINPREFIX)/$$f ; \
	done
	install -Dm755 _themer $(DESTDIR)$(ZSHCOMP)/_themer

uninstall:
	for f in theme-*; do \
		rm -vf $(DESTDIR)$(BINPREFIX)/$$f ; \
	done
	rm -vf $(DESTDIR)$(ZSHCOMP)/_themer

clean:
	rm -rf build

.PHONY: build install uninstall clean

# vim:ts=2 sw=2 noet nolist

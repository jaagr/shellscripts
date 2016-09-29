PREFIX    ?= /usr/local
BINPREFIX ?= $(PREFIX)/bin
BUILDDIR  ?= build

CSCRIPT   := ../../compile.sh
CFLAGS    += -O -a /home/jaagr/.local/lib/sh -s "'/usr/bin/env bash'"

all: build

build:
	mkdir -p -v $(BUILDDIR)
	for f in gpu-*; do \
		$(CSCRIPT) $$f $(BUILDDIR)/$$f $(CFLAGS) ; \
	done

install:
	for f in gpu-*; do \
		install -Dvm755 $(BUILDDIR)/$$f $(DESTDIR)$(BINPREFIX)/$$f ; \
	done

uninstall:
	for f in gpu-*; do \
		rm -vf $(DESTDIR)$(BINPREFIX)/$$f ; \
	done

clean:
	rm -rf build

.PHONY: build install uninstall clean

# vim:ts=2 sw=2 noet nolist

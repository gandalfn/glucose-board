SUBDIRS = lib src data vapi po

glucoseboarddocdir = ${prefix}/doc/ssi-devices
glucoseboarddoc_DATA = \
    README \
    COPYING \
    AUTHORS \
    ChangeLog \
    INSTALL \
    NEWS

BUILD_FILES = \
    build/common.am \
    build/pkgconfig.am \
    build/vapi.am \
    build/glucose-board.am \
    build/ac-define-dir.m4

INTLTOOL_FILES = \
    intltool-extract.in \
    intltool-merge.in \
    intltool-update.in

EXTRA_DIST = \
    $(glucose_boarddoc_DATA) \
    $(BUILD_FILES) \
    $(INTLTOOL_FILES)

DISTCLEANFILES = \
    intltool-extract \
    intltool-merge \
    intltool-update \
    po/.intltool-merge-cache

ACLOCAL_AMFLAGS = -I build

uninstall-local:
	-rm -r $(glucose_boarddocdir)

dist-hook: gen-ChangeLog
	for specfile in *.spec; do \
        if test -f $$specfile; then \
            cp -p $$specfile $(distdir); \
        fi \
    done

.PHONY: gen-ChangeLog
gen-ChangeLog:
	if test -d .git; then                                    \
        $(top_srcdir)/gitlog-to-changelog > $(distdir)/cl-t; \
        rm -f $(distdir)/ChangeLog;                          \
        mv $(distdir)/cl-t $(distdir)/ChangeLog;             \
    fi

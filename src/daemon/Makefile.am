GLUCOSE_BOARD_INTERNAL_VAPIS = \
    $(top_srcdir)/lib/log/glucose-board-log.vapi

GLUCOSE_BOARD_VAPI_DEPS = \
    $(top_srcdir)/lib/glucose-board-$(GLUCOSE_BOARD_ABI).vapi

include $(top_srcdir)/build/glucose-board.am

bin_PROGRAMS = \
    glucose-board-daemon

glucose_board_daemon_SOURCES = \
    daemon.vala

glucose_board_daemon_VALAFLAGS = \
    --pkg=posix \
    --pkg=posix-custom

glucose_board_daemon_LDADD = \
    $(GLUCOSE_BOARD_LIBS) \
    ${top_builddir}/lib/libglucose-board.la

VALAFILES = \
    $(filter %.vala,$(glucose_board_daemon_SOURCES))

CLEANFILES += \
    glucose_board_daemon_vala.stamp \
    $(VALAFILES:.vala=.c) \
    *.xml

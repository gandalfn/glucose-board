include $(top_srcdir)/build/glucose-board.am

glucose-board-log.vapi: libglucose_board_log_la_vala.stamp

noinst_LTLIBRARIES = libglucose-board-log.la

glucose-board-log.h: libglucose_board_log_la_vala.stamp

libglucose_board_log_la_VALAFLAGS = \
    --header=glucose-board-log.h \
    --library=glucose-board-log \
    --pkg=posix

libglucose_board_log_la_SOURCES = \
    log.vala

libglucose_board_log_la_LIBADD = \
    $(GLUCOSE_BOARD_LIBS)

noinst_HEADERS = \
    glucose-board-log.h

EXTRA_DIST = \
    glucose-board-log.vapi

VALAFILES = \
    $(filter %.vala,$(libglucose_board_log_la_SOURCES))

CLEANFILES += \
    glucose-board-log.h \
    glucose-board-log.vapi \
    libglucose_board_log_la_vala.stamp \
    $(VALAFILES:.vala=.c) \
    $(pkgconfig_DATA)

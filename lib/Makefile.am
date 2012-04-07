GLUCOSE_BOARD_LIB_NAME = glucose-board

GLUCOSE_BOARD_INTERNAL_VAPIS = \
    $(top_srcdir)/lib/log/glucose-board-log.vapi

GLUCOSE_BOARD_VAPI_DEPS =

include $(top_srcdir)/build/glucose-board.am
include $(top_srcdir)/build/pkgconfig.am
include $(top_srcdir)/build/vapi.am

SUBDIRS = log . usb udev

glucose-board.h: libglucose_board_la_vala.stamp

lib_LTLIBRARIES = libglucose-board.la

include_HEADERS = \
    glucose-board.h

libglucose_board_la_VALAFLAGS = \
    --header=glucose-board.h \
    --library=glucose-board \
    --pkg=posix

libglucose_board_la_SOURCES = \
    config.vala \
    extension.vala \
    extension-loader.vala \
    module.vala \
    message.vala \
    stream.vala \
    device.vala \
    device-manager.vala

libglucose_board_la_LDFLAGS = \
    -version-number @GLUCOSE_BOARD_SO_VERSION@ \
    -no-undefined

libglucose_board_la_LIBADD = \
    $(GLUCOSE_BOARD_LIBS) \
    $(top_builddir)/lib/log/libglucose-board-log.la

VALAFILES = \
    $(filter %.vala,$(libglucose_board_log_la_SOURCES)) \
    $(filter %.vala,$(libglucose_board_la_SOURCES))

CLEANFILES += \
    glucose-board.h \
    glucose-board-log.h \
    glucose-board-log.vapi \
    libglucose_board_la_vala.stamp \
    libglucose_board_log_la_vala.stamp \
    $(VALAFILES:.vala=.c) \
    $(pkgconfig_DATA)

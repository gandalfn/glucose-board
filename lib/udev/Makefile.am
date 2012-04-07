GLUCOSE_BOARD_LIB_NAME = glucose-board-udev

GLUCOSE_BOARD_INTERNAL_VAPIS = \
    $(top_srcdir)/lib/log/glucose-board-log.vapi

GLUCOSE_BOARD_VAPI_DEPS = \
    $(top_srcdir)/lib/glucose-board-$(GLUCOSE_BOARD_ABI).vapi \
    $(top_srcdir)/lib/usb/glucose-board-usb-$(GLUCOSE_BOARD_ABI).vapi

include $(top_srcdir)/build/glucose-board.am
include $(top_srcdir)/build/pkgconfig.am
include $(top_srcdir)/build/vapi.am

glucose-board-udev.h: libglucose_board_udev_la_vala.stamp

lib_LTLIBRARIES = libglucose-board-udev.la

includeudevdir = $(includedir)/udev

includeudev_HEADERS = \
    glucose-board-udev.h

libglucose_board_udev_la_VALAFLAGS = \
    --header=glucose-board-udev.h \
    --library=glucose-board-udev \
    --pkg=dbus-glib-1 \
    --pkg=gudev-1.0

libglucose_board_udev_la_SOURCES = \
    udev-device-manager.vala

libglucose_board_udev_la_LDFLAGS = \
    -version-number @GLUCOSE_BOARD_SO_VERSION@ \
    -no-undefined

libglucose_board_udev_la_LIBADD = \
    $(GLUCOSE_BOARD_LIBS) \
    $(top_builddir)/lib/libglucose-board.la

VALAFILES = \
    $(filter %.vala,$(libglucose_board_udev_la_SOURCES))

CLEANFILES += \
    glucose-board-udev.h \
    libglucose_board_udev_la_vala.stamp \
    $(VALAFILES:.vala=.c) \
    $(pkgconfig_DATA)

GLUCOSE_BOARD_LIB_NAME = glucose-board-usb

GLUCOSE_BOARD_INTERNAL_VAPIS = \
    $(top_srcdir)/lib/log/glucose-board-log.vapi

GLUCOSE_BOARD_VAPI_DEPS = \
    $(top_builddir)/lib/glucose-board-$(GLUCOSE_BOARD_ABI).vapi

include $(top_srcdir)/build/glucose-board.am
include $(top_srcdir)/build/pkgconfig.am
include $(top_srcdir)/build/vapi.am

glucose-board-usb.h: libglucose_board_usb_la_vala.stamp

lib_LTLIBRARIES = libglucose-board-usb.la

includeusbdir = $(includedir)/usb

includeusb_HEADERS = \
    glucose-board-usb.h

libglucose_board_usb_la_VALAFLAGS = \
    --header=glucose-board-usb.h \
    --library=glucose-board-usb

libglucose_board_usb_la_SOURCES = \
    usb-device.vala \
    usb-stream.vala \
    usb-stream-serial.vala \
    ti-3410-stream.vala

libglucose_board_usb_la_LDFLAGS = \
    -version-number @GLUCOSE_BOARD_SO_VERSION@ \
    -no-undefined

libglucose_board_usb_la_LIBADD = \
    $(GLUCOSE_BOARD_LIBS) \
    $(top_builddir)/lib/libglucose-board.la

VALAFILES = \
    $(filter %.vala,$(libglucose_board_usb_la_SOURCES))

CLEANFILES += \
    glucose-board-usb.h \
    libglucose_board_usb_la_vala.stamp \
    $(VALAFILES:.vala=.c) \
    $(pkgconfig_DATA)

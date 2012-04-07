GLUCOSE_BOARD_MODULE = abbott

GLUCOSE_BOARD_VAPI_DEPS = \
    $(top_srcdir)/lib/glucose-board-$(GLUCOSE_BOARD_ABI).vapi \
    $(top_srcdir)/lib/usb/glucose-board-usb-$(GLUCOSE_BOARD_ABI).vapi \
    $(top_srcdir)/lib/udev/glucose-board-udev-$(GLUCOSE_BOARD_ABI).vapi

include $(top_srcdir)/build/module.am

config_DATA = \
    abbott.conf

module_LTLIBRARIES = libabbott.la

libabbott_la_SOURCES = \
    message.vala \
    device-manager.vala \
    device.vala \
    module.vala

libabbott_la_LIBADD = \
    $(GLUCOSE_BOARD_MODULE_LIBS)

VALAFILES = \
    $(filter %.vala,$(libabbott_la_SOURCES))

EXTRA_DIST += \
    $(config_DATA)

CLEANFILES += \
    libabbott_la_vala.stamp \
    $(VALAFILES:.vala=.c)

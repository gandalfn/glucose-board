m4_define(glucose_board_version_major, 0)
m4_define(glucose_board_version_minor, 1)
m4_define(glucose_board_version_micro, 0)
AC_INIT([glucose-board], [glucose_board_version_major.glucose_board_version_minor.glucose_board_version_micro], [nicolas.bruguier@supersonicimagine.fr])
AC_PREREQ(2.63)

dnl ****************************************************************************
dnl Define default build directory
dnl ****************************************************************************
AC_CONFIG_SRCDIR(lib/glucose-board.pc.in)
AC_CONFIG_AUX_DIR([build])
AC_CONFIG_MACRO_DIR([build])
AC_CONFIG_HEADERS(build/config.h)

dnl ****************************************************************************
dnl Init automake
dnl ****************************************************************************
AM_INIT_AUTOMAKE([1.11 tar-pax dist-bzip2 silent-rules -Wno-portability])
m4_ifdef([AM_SILENT_RULES],[AM_SILENT_RULES([yes])])
AC_ARG_VAR([ACLOCAL_FLAGS], [aclocal flags, e.g. -I <macro dir>])
AM_MAINTAINER_MODE

dnl ****************************************************************************
dnl Define version
dnl ****************************************************************************
GLUCOSE_BOARD_MAJOR_VERSION=glucose_board_version_major
GLUCOSE_BOARD_MINOR_VERSION=glucose_board_version_minor
GLUCOSE_BOARD_MICRO_VERSION=glucose_board_version_micro
GLUCOSE_BOARD_SO_VERSION="glucose_board_version_major:glucose_board_version_minor:glucose_board_version_micro"
GLUCOSE_BOARD_ABI=$GLUCOSE_BOARD_MAJOR_VERSION.$GLUCOSE_BOARD_MINOR_VERSION
GLUCOSE_BOARD_VERSION=$GLUCOSE_BOARD_MAJOR_VERSION.$GLUCOSE_BOARD_MINOR_VERSION.$GLUCOSE_BOARD_MICRO_VERSION

AC_DEFINE_UNQUOTED(GLUCOSE_BOARD_NAME, PACKAGE_NAME, [Package name])
AC_DEFINE_UNQUOTED(GLUCOSE_BOARD_MAJOR_VERSION, $GLUCOSE_BOARD_MAJOR_VERSION, [Major version])
AC_DEFINE_UNQUOTED(GLUCOSE_BOARD_MINOR_VERSION, $GLUCOSE_BOARD_MINOR_VERSION, [Minor version])
AC_DEFINE_UNQUOTED(GLUCOSE_BOARD_MICRO_VERSION, $GLUCOSE_BOARD_MICRO_VERSION, [Micro version])
AC_DEFINE_UNQUOTED(GLUCOSE_BOARD_ABI, $GLUCOSE_BOARD_VERSION, [Version])
AC_DEFINE_UNQUOTED(GLUCOSE_BOARD_VERSION, $GLUCOSE_BOARD_VERSION, [Version])
AC_SUBST(GLUCOSE_BOARD_VERSION)
AC_SUBST(GLUCOSE_BOARD_ABI)
AC_SUBST(GLUCOSE_BOARD_SO_VERSION)

dnl ****************************************************************************
dnl Define path
dnl ****************************************************************************
configdir=${sysconfdir}/glucose-board
statedir=${localstatedir}/lib/glucose-board
moduledir=${libdir}/glucose-board
uidir=${datadir}/glucose-board/ui
AC_DEFINE_DIR([GLUCOSE_BOARD_CONFIG_PATH], [configdir], [readonly configuration path])
AC_DEFINE_DIR([GLUCOSE_BOARD_STATE_PATH], [statedir], [modifiable configuration path])
AC_DEFINE_DIR([GLUCOSE_BOARD_MODULE_PATH], [moduledir], [modules path])
AC_DEFINE_DIR([GLUCOSE_BOARD_UI_PATH], [uidir], [ui path])
AC_SUBST(configdir)
AC_SUBST(statedir)
AC_SUBST(moduledir)
AC_SUBST(uidir)

dnl ****************************************************************************
dnl Internationalization
dnl ****************************************************************************
GETTEXT_PACKAGE=AC_PACKAGE_NAME
AC_SUBST(GETTEXT_PACKAGE)
AC_DEFINE_UNQUOTED(GETTEXT_PACKAGE, "$GETTEXT_PACKAGE", [The gettext translation domain])
IT_PROG_INTLTOOL([0.40.1])
AM_GNU_GETTEXT([external])
AM_GNU_GETTEXT_VERSION([0.17])

dnl ****************************************************************************
dnl Packages version required
dnl ****************************************************************************
GLIB_REQUIRED=2.20.0
GTK_REQUIRED=2.16.0
VALA_REQUIRED=0.14.0
GUDEV_REQUIRED=172
LIBUSB_REQUIRED=1.0.0

dnl ****************************************************************************
dnl Check for build
dnl ****************************************************************************
AC_LANG([C])
AM_PROG_CC_C_O
AC_SEARCH_LIBS([strerror],[cposix])

dnl ****************************************************************************
dnl Check for libtool
dnl ****************************************************************************
LT_PREREQ([2.2])
LT_INIT([disable-static])

dnl ****************************************************************************
dnl Check for packages
dnl ****************************************************************************
PKG_CHECK_MODULES(GLUCOSE_BOARD, [glib-2.0 >= $GLIB_REQUIRED
                                  gio-2.0 >= $GLIB_REQUIRED
                                  gobject-2.0 >= $GLIB_REQUIRED
                                  gmodule-2.0 >= $GLIB_REQUIRED
                                  gthread-2.0 >= $GLIB_REQUIRED
                                  gio-2.0 >= $GLIB_REQUIRED
                                  libusb-1.0 >= $LIBUSB_REQUIRED
                                  gudev-1.0 >= $GUDEV_REQUIRED])

dnl ****************************************************************************
dnl Check for vala
dnl ****************************************************************************
vala_0_14=$(which valac-0.14)
if test ! x"$vala_0_14" = x""; then
    VALAC=$vala_0_14
fi
AM_PROG_VALAC($VALA_REQUIRED)
VALA_VAPI_PATH=$($PKG_CONFIG --variable=vapidir libvala-0.14)
AC_SUBST(VALA_VAPI_PATH)

AC_ARG_ENABLE(valadoc,
  AS_HELP_STRING([--enable-valadoc[=@<:@no/auto/yes@:>@]], [Enable valadoc support]),,
    [enable_valadoc=auto])

dnl ****************************************************************************
dnl Generate outputs
dnl ****************************************************************************
AC_CONFIG_FILES([
Makefile
lib/log/Makefile
lib/glucose-board.pc
lib/Makefile
lib/usb/glucose-board-usb.pc
lib/usb/Makefile
lib/udev/glucose-board-udev.pc
lib/udev/Makefile
src/Makefile
src/daemon/Makefile
src/modules/Makefile
src/modules/abbott/Makefile
data/Makefile
data/glucose-board-daemon
vapi/Makefile
po/Makefile.in])

AC_OUTPUT

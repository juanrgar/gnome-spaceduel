bin_PROGRAMS = gnome-spaceduel

gnome_spaceduel_SOURCES = \
	config.vapi \
	application.vala \
	game.vala \
	sprites.vala \
	gnome-spaceduel-data.h \
	gnome-spaceduel-data.c

gnome_spaceduel_CFLAGS = \
	-DVERSION=\"$(VERSION)\" \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\" \
	-DDATA_DIRECTORY=\"$(datadir)/gnome-spaceduel\" \
	-DLOCALEDIR=\"$(datadir)/locale\" \
	$(GNOME_SPACEDUEL_CFLAGS) \
	-w

gnome_spaceduel_VALAFLAGS = \
	--pkg posix \
	--pkg gtk+-3.0 \
	--pkg pango \
	--pkg pangocairo \
	--pkg clutter-1.0 \
	--pkg clutter-gtk-1.0 \
	--pkg cogl-1.0 \
	--pkg gee-0.8

gnome_spaceduel_LDADD = \
	$(GNOME_SPACEDUEL_LIBS) \
	-lm

data_files = $(shell $(GLIB_COMPILE_RESOURCES)				\
		--sourcedir=$(top_srcdir)					\
		--generate-dependencies gnome-spaceduel.gresource.xml)

gnome-spaceduel-data.h: gnome-spaceduel.gresource.xml $(data_files)
	$(AM_V_GEN)							\
		$(GLIB_COMPILE_RESOURCES)				\
		--target=$@						\
		--sourcedir=$(top_srcdir)					\
		--generate						\
		--c-name gnome_spaceduel_data $<
gnome-spaceduel-data.c: gnome-spaceduel.gresource.xml $(data_files)
	$(AM_V_GEN)							\
		$(GLIB_COMPILE_RESOURCES)				\
		--target=$@						\
		--sourcedir=$(top_srcdir)					\
		--generate						\
		--c-name gnome_spaceduel_data $<

EXTRA_DIST = \
	gnome-spaceduel.gresource.xml \
	$(data_files)

CLEANFILES = \
	$(patsubst %.vala,%.c,$(filter %.vala, $(SOURCES))) \
	*_vala.stamp \
	gnome-spaceduel-data.h \
	gnome-spaceduel-data.c

-include $(top_srcdir)/git.mk

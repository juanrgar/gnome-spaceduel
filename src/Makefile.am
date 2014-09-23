bin_PROGRAMS = gspaceduel

gspaceduel_SOURCES = \
	config.vapi \
	application.vala \
	game.vala \
	sprites.vala \
	gspaceduel-data.h \
	gspaceduel-data.c

gspaceduel_CFLAGS = \
	-DVERSION=\"$(VERSION)\" \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\" \
	-DDATA_DIRECTORY=\"$(datadir)/gspaceduel\" \
	-DLOCALEDIR=\"$(datadir)/locale\" \
	$(GSPACEDUEL_CFLAGS) \
	-w

gspaceduel_VALAFLAGS = \
	--pkg posix \
	--pkg gtk+-3.0 \
	--pkg pango \
	--pkg pangocairo \
	--pkg clutter-1.0 \
	--pkg clutter-gtk-1.0 \
	--pkg cogl-1.0 \
	--pkg gee-0.8

gspaceduel_LDADD = \
	$(GSPACEDUEL_LIBS) \
	-lm

data_files = $(shell $(GLIB_COMPILE_RESOURCES)				\
		--sourcedir=$(top_srcdir)					\
		--generate-dependencies gspaceduel.gresource.xml)

gspaceduel-data.h: gspaceduel.gresource.xml $(data_files)
	$(AM_V_GEN)							\
		$(GLIB_COMPILE_RESOURCES)				\
		--target=$@						\
		--sourcedir=$(top_srcdir)					\
		--generate						\
		--c-name gspaceduel_data $<
gspaceduel-data.c: gspaceduel.gresource.xml $(data_files)
	$(AM_V_GEN)							\
		$(GLIB_COMPILE_RESOURCES)				\
		--target=$@						\
		--sourcedir=$(top_srcdir)					\
		--generate						\
		--c-name gspaceduel_data $<

CLEANFILES = \
	$(patsubst %.vala,%.c,$(filter %.vala, $(SOURCES))) \
	*_vala.stamp \
	gspaceduel-data.h \
	gspaceduel-data.c

-include $(top_srcdir)/git.mk

vapi_sources = [
    'config.vapi'
]

spaceduel_vala_sources = [
    'application.vala',
    'game.vala',
    'sprites.vala'
]

spaceduel_sources = [
    vapi_sources,
    spaceduel_vala_sources
]

spaceduel_dependencies = [
    gtk_dep,
    clutter_dep,
    clutter_gtk_dep,
    gee_dep
]

executable(
    'gnome-spaceduel',
    spaceduel_sources,
    dependencies: spaceduel_dependencies,
    install: true)

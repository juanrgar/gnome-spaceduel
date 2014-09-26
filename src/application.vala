/* gnome-spaceduel Copyright (C) 2014 Juan R. García Blanco
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

public class Application : Gtk.Application
{
  private GLib.Settings _settings;

  private Gtk.Window _window;
  private Gtk.HeaderBar _header_bar;
  private Gtk.ToggleButton _pause_button;
  private Gtk.AboutDialog _about_dialog;
  private Gtk.Dialog _preferences_dialog;

  private Game _game;

  private const GLib.ActionEntry[] action_entries =
  {
    { "new-game",      new_game_cb    },
    { "about",         about_cb       },
    { "preferences",   preferences_cb },
    { "quit",          quit_cb        },
    { "help",          help_cb        }
  };

  public Application ()
  {
    Object (application_id: "org.gnome.gnome-spaceduel", flags: ApplicationFlags.FLAGS_NONE);
  }

  protected override void startup ()
  {
    base.startup ();

    add_action_entries (action_entries, this);
    add_accelerator ("F1", "app.help", null);

    _settings = new Settings ("org.gnome.spaceduel");

    _init_style ();
    _init_app_menu ();
    _init_game ();
  }

  protected override void activate ()
  {
    base.activate ();

    var builder = new Gtk.Builder ();
    _create_window (builder);
    _create_about_dialog ();
    _create_preferences_dialog (builder);

    _game.new_game ();
    _connect_game_elements (builder);
  }

  protected override void shutdown ()
  {
    base.shutdown ();
  }

  private void _init_style ()
  {
    Gtk.Settings.get_default ().set ("gtk-application-prefer-dark-theme", true);

    var provider = new Gtk.CssProvider ();
    try
    {
      provider.load_from_file (GLib.File.new_for_uri ("resource://org/gnome/gnome-spaceduel/data/style.css"));
      Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
    catch (GLib.Error e)
    {
      stderr.printf ("%s\n", e.message);
    }
  }

  private void _init_app_menu ()
  {
    var builder = new Gtk.Builder ();
    try 
    {
      builder.add_from_resource ("/org/gnome/gnome-spaceduel/data/menus.ui");
      var menu = builder.get_object ("app-menu") as GLib.MenuModel;
      set_app_menu (menu);
    }
    catch (GLib.Error e)
    {
      stderr.printf ("%s\n", e.message);
    }
  }

  private void _init_game ()
  {
    _game = new Game (_settings);
    _game.notify["round"].connect ((s, p) => {
      string title = _("Round");
      title += " " + _game.round.to_string ();
      _header_bar.title = title;
    });
    _game.notify["status-message"].connect ((s, p) => {
      _header_bar.subtitle = _game.status_message;
    });

    _game.bind_property ("started", lookup_action ("preferences"), "enabled", GLib.BindingFlags.INVERT_BOOLEAN);
  }

  private void _create_window (Gtk.Builder builder)
  {
    try 
    {
      builder.add_from_resource ("/org/gnome/gnome-spaceduel/data/mainwindow.ui");
    }
    catch (GLib.Error e)
    {
      stderr.printf ("%s\n", e.message);
    }

    _window = builder.get_object ("applicationwindow") as Gtk.ApplicationWindow;
    add_window (_window);

    _create_header_bar ();
    _create_game_view (builder);

    _window.set_events (_window.get_events () | Gdk.EventMask.KEY_PRESS_MASK | Gdk.EventMask.KEY_RELEASE_MASK);
    _window.key_press_event.connect (key_press_event_cb);
    _window.key_release_event.connect (key_release_event_cb);

    _window.show_all ();
  }

  private void _create_header_bar ()
  {
    _header_bar = new Gtk.HeaderBar ();
    _header_bar.show_close_button = true;
    _header_bar.title = _("New game");
    _window.set_titlebar (_header_bar);

    _pause_button = new Gtk.ToggleButton.with_label (_("Pause"));
    _pause_button.name = "pausebutton";
    _pause_button.sensitive = false;
    _header_bar.pack_start (_pause_button);

    _game.bind_property ("started", _pause_button, "sensitive", GLib.BindingFlags.DEFAULT);
    _game.bind_property ("paused", _pause_button, "active", GLib.BindingFlags.DEFAULT);
    _pause_button.toggled.connect (() => {
      bool state = _pause_button.active;
      _pause_button.label = state ? _("Unpause") : _("Pause");
      _game.pause (state);
    });
  }

  private void _create_game_view (Gtk.Builder builder)
  {
    var embed = new GtkClutter.Embed ();
    var grid = builder.get_object ("grid") as Gtk.Grid;
    grid.attach (embed, 0, 0, 1, 1);
    _game.view = embed.get_stage ();
  }

  private void _connect_game_elements (Gtk.Builder builder)
  {
    var score1 = builder.get_object ("score1") as Gtk.Label;
    var score2 = builder.get_object ("score2") as Gtk.Label;

    _game.ships[0].notify["score"].connect ((s, p) => {
      score1.label = ((ShipSprite)s).score.to_string ();
    });
    _game.ships[1].notify["score"].connect ((s, p) => {
      score2.label = ((ShipSprite)s).score.to_string ();
    });

    var damage1 = builder.get_object ("damage1") as Gtk.LevelBar;
    var damage2 = builder.get_object ("damage2") as Gtk.LevelBar;
    _game.ships[0].bind_property ("health", damage1, "value", GLib.BindingFlags.DEFAULT);
    _game.ships[1].bind_property ("health", damage2, "value", GLib.BindingFlags.DEFAULT);

    var bullets1 = builder.get_object ("bullets1") as Gtk.LevelBar;
    var bullets2 = builder.get_object ("bullets2") as Gtk.LevelBar;
    _game.ships[0].bind_property ("available-bullets-level", bullets1, "value", GLib.BindingFlags.DEFAULT);
    _game.ships[1].bind_property ("available-bullets-level", bullets2, "value", GLib.BindingFlags.DEFAULT);
  }

  private void _create_about_dialog ()
  {
    _about_dialog = new Gtk.AboutDialog ();
    _about_dialog.set_transient_for (_window);
    _about_dialog.destroy_with_parent = true;
    _about_dialog.modal = true;

    _about_dialog.program_name = "Spaceduel";
    _about_dialog.logo_icon_name = "gnome-spaceduel";
    _about_dialog.comments = _("A clone of KSpaceduel for GNOME");

    _about_dialog.authors = {"Juan R. García Blanco"};
    _about_dialog.copyright = "Copyright © 2014 Juan R. García Blanco";
    _about_dialog.version = "0.1";
    _about_dialog.website = "http://www.gnome.org";
    _about_dialog.license_type = Gtk.License.GPL_3_0;
    _about_dialog.wrap_license = false;

    _about_dialog.response.connect ((response_id) => {
      _about_dialog.hide ();
    });
    _about_dialog.delete_event.connect ((response_id) => {
      return _about_dialog.hide_on_delete ();
    });
  }

  private void _create_preferences_dialog (Gtk.Builder builder)
  {
    try 
    {
      builder.add_from_resource ("/org/gnome/gnome-spaceduel/data/preferences.ui");
    }
    catch (GLib.Error e)
    {
      stderr.printf ("%s\n", e.message);
    }

    _preferences_dialog = builder.get_object ("preferencesdialog") as Gtk.Dialog;
    _preferences_dialog.set_transient_for (_window);

    var defaults_button = new Gtk.Button.with_label (_("Restore Defaults"));
    defaults_button.clicked.connect ((b) => {
      var keys = _settings.list_keys ();
      for (uint i = 0; i != keys.length; ++i)
      {
        _settings.reset (keys[i]);
      }
    });
    var header_bar = _preferences_dialog.get_header_bar () as Gtk.HeaderBar;
    header_bar.pack_start (defaults_button);
    defaults_button.get_style_context ().add_class ("destructive-action");
    defaults_button.show ();

    _preferences_dialog.response.connect ((response_id) => {
      _preferences_dialog.hide_on_delete ();
    });
    _preferences_dialog.delete_event.connect ((response_id) => {
      _game.reload_settings ();
      return _preferences_dialog.hide_on_delete ();
    });

    // Bindings
    _settings.bind ("game-speed", builder.get_object ("gamespeed"), "value", GLib.SettingsBindFlags.DEFAULT);
    _settings.bind ("sun-gravity", builder.get_object ("sungravity"), "value", GLib.SettingsBindFlags.DEFAULT);
    _settings.bind ("start-vel-x", builder.get_object ("startvelx"), "value", GLib.SettingsBindFlags.DEFAULT);
    _settings.bind ("start-vel-y", builder.get_object ("startvely"), "value", GLib.SettingsBindFlags.DEFAULT);
    _settings.bind ("bullet-damage", builder.get_object ("damage"), "value", GLib.SettingsBindFlags.DEFAULT);
    _settings.bind ("initial-bullets", builder.get_object ("bullets"), "value", GLib.SettingsBindFlags.DEFAULT);
  }

  private void new_game_cb ()
  {
    _game.new_game ();
  }

  private void about_cb ()
  {
    _about_dialog.present ();
  }

  private void preferences_cb ()
  {
    _preferences_dialog.present ();
  }

  private void quit_cb ()
  {
    _window.destroy ();
  }

  private void help_cb ()
  {
    try
    {
      Gtk.show_uri (_window.get_screen (), "help:gnome-spaceduel", Gtk.get_current_event_time ());
    }
    catch (GLib.Error e)
    {
      warning ("Failed to show help: %s", e.message);
    }
  }

  private bool key_press_event_cb (Gtk.Widget widget, Gdk.EventKey event)
  {
    return _game.key_press_event (event);
  }

  private bool key_release_event_cb (Gtk.Widget widget, Gdk.EventKey event)
  {
    return _game.key_release_event (event);
  }

  public static int main (string[] args)
  {
    Intl.setlocale (LocaleCategory.ALL, "");
    Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
    Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain (GETTEXT_PACKAGE);

    var context = new OptionContext ("");

    context.add_group (Gtk.get_option_group (true));
    context.add_group (Clutter.get_option_group_without_init ());

    try
    {
      context.parse (ref args);
    }
    catch (Error e)
    {
      stderr.printf ("%s\n", e.message);
      return Posix.EXIT_FAILURE;
    }

    Environment.set_application_name (_("Spaceduel"));

    try
    {
      GtkClutter.init_with_args (ref args, "", new OptionEntry[0], null);
    }
    catch (Error e)
    {
      var dialog = new Gtk.MessageDialog (null, Gtk.DialogFlags.MODAL, Gtk.MessageType.ERROR, Gtk.ButtonsType.NONE, "Unable to initialize Clutter:\n%s", e.message);
      dialog.set_title (Environment.get_application_name ());
      dialog.run ();
      dialog.destroy ();
      return Posix.EXIT_FAILURE;
    }

    var app = new Application ();
    return app.run (args);
  }
}

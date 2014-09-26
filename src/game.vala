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

public class Game : GLib.Object
{
  // Internal data types
  struct PlayerKeyPressed {
    bool accelerate;
    bool rotate_right;
    bool rotate_left;
    bool fire_bullet;
  }

  enum GameState {
    STATE_NEW_GAME,
    STATE_NEW_ROUND,
    STATE_FINISHED_ROUND,
    STATE_PLAYING
  }

  // Game view
  private Clutter.Actor _view;
  private bool _is_view_init;

  private GLib.Settings _settings;

  private GameState _game_state;
  private PlayerKeyPressed[] _player_key_pressed;
  private SimpleSprite _sun;
  private ShipSprite[] _ships;
  private Gdk.Pixbuf[] _ship_explosion_frames;
  private Gee.ArrayList<BulletSprite> _bullets;

  public Game (GLib.Settings settings)
  {
    Object (settings: settings);

    // Create arrays; objects are created when needed
    _player_key_pressed = new PlayerKeyPressed[2];
    _ships = new ShipSprite[2];
    _ship_explosion_frames = new Gdk.Pixbuf[31];

    _bullets = new Gee.ArrayList<BulletSprite> ();
  }

  public GLib.Settings settings {
    construct { _settings = value; }
  }

  public Clutter.Actor view {
    set
    {
      _view = value;
      _is_view_init = false;
    }
  }

  public bool started {
    get; set; default = false;
  }

  public bool paused {
    get; set; default = false;
  }

  public uint round {
    get; set; default = 0;
  }

  public ShipSprite[] ships {
    get { return _ships; }
  }

  public string status_message {
    get; set; default = "";
  }

  public void new_game ()
  {
    if (!_is_view_init)
    {
      _init_view ();
      _is_view_init = true;
    }

    _ships[0].score = 0;
    _ships[1].score = 0;
    _reset_sprites ();
    status_message = _("Press SPACE bar to start game");
    _game_state = GameState.STATE_NEW_GAME;
    round = 1;
    started = false;
    paused = false;
  }

  private void _init_view ()
  {
    _init_background ();
    _init_sun ();
    _init_ships ();
  }

  private void _init_background ()
  {
    try
    {
      var background_pixbuf = new Gdk.Pixbuf.from_resource ("/org/gnome/gnome-spaceduel/background");
      var background_image = new Clutter.Image ();
      background_image.set_data (background_pixbuf.get_pixels (),
        Cogl.PixelFormat.RGB_888,
        background_pixbuf.width,
        background_pixbuf.height,
        background_pixbuf.rowstride);

      _view.content = background_image;
      _view.content_repeat = Clutter.ContentRepeat.BOTH;
    }
    catch (GLib.Error e)
    {
      stderr.printf ("%s\n", e.message);
    }
  }

  private void _init_sun ()
  {
    _sun = new SimpleSprite ("sun");
    _sun.load ();
    _sun.x = _view.width/2.0f - _sun.width/2.0f;
    _sun.y = _view.height/2.0f - _sun.height/2.0f;
    _view.add_child (_sun);
  }

  private void _init_ships ()
  {
    _ships[0] = new ShipSprite ("ship1");
    _ships[0].load ();
    _ships[0].hide ();
    _ships[1] = new ShipSprite ("ship2");
    _ships[1].load ();
    _ships[1].hide ();

    _view.add_child (_ships[0]);
    _view.add_child (_ships[1]);

    try
    {
      for (int i = 0; i != _ship_explosion_frames.length; ++i)
      {
        var frame = new Gdk.Pixbuf.from_resource ("/org/gnome/gnome-spaceduel/explos" + i.to_string("%02i"));
        _ship_explosion_frames[i] = frame;
      }
    }
    catch (GLib.Error e)
    {
      stderr.printf ("%s\n", e.message);
    }
  }

  public void pause (bool state)
  {
    if (_started)
    {
      if (_paused != state)
      {
        paused = state;

        if (!_paused)
        {
          _setup_draw_timeout ();
        }
      }
    }
  }

  public bool key_press_event (Gdk.EventKey event)
  {
    uint keyval = upper_key (event.keyval);

    if (keyval == Gdk.Key.space)
    {
      if (_game_state == GameState.STATE_NEW_GAME)
      {
        _start_game ();
      }
      else if (_game_state == GameState.STATE_NEW_ROUND)
      {
        _start_round ();
      }
      return true;
    }
    else if (keyval == Gdk.Key.P)
    {
      pause (!_paused);
      return true;
    }
    else
    {
      return key_event (keyval, true);
    }
  }

  public bool key_release_event (Gdk.EventKey event)
  {
    uint keyval = upper_key (event.keyval);
    return key_event (keyval, false);
  }

  private uint upper_key (uint keyval)
  {
    return (keyval > 255) ? keyval : ((char) keyval).toupper ();
  }

  private bool key_event (uint keyval, bool state)
  {
    if (keyval == Gdk.Key.W)
    {
      _player_key_pressed[0].accelerate = state;
      return true;
    }
    else if (keyval == Gdk.Key.D)
    {
      _player_key_pressed[0].rotate_right = state;
      return true;
    }
    else if (keyval == Gdk.Key.A)
    {
      _player_key_pressed[0].rotate_left = state;
      return true;
    }
    else if (keyval == Gdk.Key.S)
    {
      _player_key_pressed[0].fire_bullet = state;
      return true;
    }
    else if (keyval == Gdk.Key.Up)
    {
      _player_key_pressed[1].accelerate = state;
      return true;
    }
    else if (keyval == Gdk.Key.Right)
    {
      _player_key_pressed[1].rotate_right = state;
      return true;
    }
    else if (keyval == Gdk.Key.Left)
    {
      _player_key_pressed[1].rotate_left = state;
      return true;
    }
    else if (keyval == Gdk.Key.Down)
    {
      _player_key_pressed[1].fire_bullet = state;
      return true;
    }
    else
    {
      return false;
    }
  }

  private void _start_game ()
  {
    status_message = "";
    _start_round ();
  }

  private void _start_round ()
  {
    status_message = "";

    _reset_player_key_pressed ();
    _setup_draw_timeout ();

    _game_state = GameState.STATE_PLAYING;
    started = true;
  }

  private void _reset_player_key_pressed ()
  {
    for (int i = 0; i != 2; ++i)
    {
      _player_key_pressed[i].accelerate = false;
      _player_key_pressed[i].rotate_right = false;
      _player_key_pressed[i].rotate_left = false;
      _player_key_pressed[i].fire_bullet = false;
    }
  }

  private void _setup_draw_timeout ()
  {
    GLib.Timeout.add (16, _draw_timeout_cb);
  }

  private bool _draw_timeout_cb ()
  {
    _move_ships ();
    _detect_collisions ();

    return (!_paused && _started);
  }

  private void _move_ships ()
  {
    float game_speed = (float)_settings.get_double ("game-speed");
    float sun_gravity = (float)_settings.get_double ("sun-gravity");

    for (uint i = 0; i != 2; ++i)
    {
      _ships[i].compute_gravity (game_speed, sun_gravity);

      if (_player_key_pressed[i].accelerate)
      {
        _ships[i].accelerate ();
      }
      if (_player_key_pressed[i].rotate_right)
      {
        _ships[i].rotate_right ();
      }
      if (_player_key_pressed[i].rotate_left)
      {
        _ships[i].rotate_left ();
      }
      if (_player_key_pressed[i].fire_bullet)
      {
        if (_ships[i].has_bullets ())
        {
          var bullet = new BulletSprite ("bullet");
          bullet.load ();
          _view.add_child (bullet);
          _bullets.add (bullet);
          _player_key_pressed[i].fire_bullet = false;

          _ships[i].fire_bullet (bullet);
        }
      }

      _ships[i].forward (game_speed);
    }

    foreach (var bullet in _bullets)
    {
      bullet.compute_gravity (game_speed, sun_gravity);
      bullet.forward (game_speed);
    }
  }

  private void _detect_collisions ()
  {
    // ships and sun
    for (uint i = 0; i != 2; ++i)
    {
      if (_sprites_collide (_sun, _ships[i]))
      {
        _ships[i].explode (_ship_explosion_frames);
        _finish_round ();
      }
    }

    // ships
    if (_sprites_collide (_ships[0], _ships[1]))
    {
      _ships[0].explode (_ship_explosion_frames);
      _ships[1].explode (_ship_explosion_frames);
      _finish_round ();
    }

    // ships and bullets
    float bullet_damage = (float)_settings.get_double ("bullet-damage");
    var bullets_to_remove = new Gee.ArrayList<BulletSprite> ();
    foreach (var bullet in _bullets)
    {
      for (uint i = 0; i < 2; ++i)
      {
        if (_sprites_collide (bullet, _ships[i]))
        {
          bullets_to_remove.add (bullet);

          if (_ships[i].hit (bullet_damage))
          {
            _ships[i].explode (_ship_explosion_frames);
            _finish_round ();
          }
        }
      }

      if (_sprites_collide (_sun, bullet))
      {
        bullets_to_remove.add (bullet);
      }
    }
    foreach (var bullet in bullets_to_remove)
    {
      _view.remove_child (bullet);
      _bullets.remove (bullet);
    }
  }

  private bool _sprites_collide (SimpleSprite sprite1, SimpleSprite sprite2)
  {
    var r1 = sprite1.radius;
    var r2 = sprite2.radius;
    var sumr = r1 + r2;

    var x1 = sprite1.center_x;
    var y1 = sprite1.center_y;
    var x2 = sprite2.center_x;
    var y2 = sprite2.center_y;
    var d = GLib.Math.sqrtf ((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2));

    return (d < sumr);
  }

  private void _finish_round ()
  {
    started = false;

    if (_ships[0].exploded && _ships[1].exploded)
    {
      // even
      status_message = _("Even");
    }
    else if (_ships[0].exploded)
    {
      status_message = _("Player 2 wins");
      _ships[1].score++;
    }
    else if (_ships[1].exploded)
    {
      status_message = _("Player 1 wins");
      _ships[0].score++;
    }

    _game_state = GameState.STATE_FINISHED_ROUND;
    GLib.Timeout.add (3000, _finish_round_timeout_cb);
  }

  private bool _finish_round_timeout_cb ()
  {
    status_message = "";
    _new_round ();

    return false;
  }

  private void _new_round ()
  {
    _reset_sprites ();
    status_message = "Press SPACE bar to start new round";

    round++;
    _game_state = GameState.STATE_NEW_ROUND;
  }

  private void _reset_sprites ()
  {
    float start_vel_x = (float)_settings.get_double ("start-vel-x");
    float start_vel_y = (float)_settings.get_double ("start-vel-y");

    float view_center_x = _view.width/2.0f;
    float view_fourth_y = _view.height/4.0f;

    uint available_bullets = _settings.get_uint ("initial-bullets");

    _ships[0].center_x = view_center_x;
    _ships[0].center_y = view_fourth_y;
    _ships[0].rotation_angle_z = 0.0f;
    _ships[0].velocity_x = start_vel_x;
    _ships[0].velocity_y = start_vel_y;
    _ships[0].available_bullets = available_bullets;
    _ships[0].reset ();
    _ships[0].show ();

    _ships[1].center_x = view_center_x;
    _ships[1].center_y = view_fourth_y*3.0f;
    _ships[1].rotation_angle_z = 180.0f;
    _ships[1].velocity_x = -start_vel_x;
    _ships[1].velocity_y = -start_vel_y;
    _ships[1].available_bullets = available_bullets;
    _ships[1].reset ();
    _ships[1].show ();

    foreach (var bullet in _bullets)
    {
      _view.remove_child (bullet);
    }

    _bullets.clear ();
  }

  public void reload_settings ()
  {
    _reload_ships_settings ();
  }

  private void _reload_ships_settings ()
  {
    float start_vel_x = (float)_settings.get_double ("start-vel-x");
    float start_vel_y = (float)_settings.get_double ("start-vel-y");
    _ships[0].velocity_x = start_vel_x;
    _ships[0].velocity_y = start_vel_y;
    _ships[1].velocity_x = -start_vel_x;
    _ships[1].velocity_y = -start_vel_y;

    uint available_bullets = _settings.get_uint ("initial-bullets");
    _ships[0].available_bullets = available_bullets;
    _ships[1].available_bullets = available_bullets;
  }
}

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

public class SimpleSprite : Clutter.Actor
{
  private string _element_id;

  public SimpleSprite (string element_id)
  {
    Object ();

    _element_id = element_id;
  }

  public virtual void load ()
  {
    try
    {
      var pixbuf = new Gdk.Pixbuf.from_resource ("/org/gnome/gnome-spaceduel/" + _element_id);
      var image = new Clutter.Image ();
      image.set_data (pixbuf.get_pixels (),
        Cogl.PixelFormat.RGBA_8888,
        pixbuf.width,
        pixbuf.height,
        pixbuf.rowstride);

      content = image;
      width = pixbuf.width;
      height = pixbuf.height;
    }
    catch (GLib.Error e)
    {
      stderr.printf ("%s\n", e.message);
    }
  }

  public string element_id
  {
    construct { _element_id = value; }
    get { return _element_id; }
  }

  public float center_x
  {
    get { return (x + width/2.0f); }
    set { x = value - width/2.0f; }
  }

  public float center_y
  {
    get { return (y + height/2.0f); }
    set { y = value - height/2.0f; }
  }

  public float radius
  {
    get { return height/2.0f; }
  }
}

public class MobileSprite : SimpleSprite
{
  public MobileSprite (string element_id)
  {
    Object (element_id: element_id);
  }

  public override void load ()
  {
    base.load ();
    set_pivot_point (0.5f, 0.5f);
  }

  public float velocity_x {
    get; set;
  }

  public float velocity_y {
    get; set;
  }

  public void compute_gravity (float game_speed, float sun_gravity)
  {
    float ex = center_x - get_parent().width/2.0f;
    float ey = center_y - get_parent().height/2.0f;

    float abs_2 = ex*ex + ey*ey;
    float sq = GLib.Math.sqrtf (abs_2);

    float nx = ex/sq;
    float ny = ey/sq;
    float eg = sun_gravity*game_speed;

    float dvx = eg*nx/abs_2;
    float dvy = eg*ny/abs_2;

    velocity_x -= dvx;
    velocity_y -= dvy;
  }

  public void forward (float game_speed)
  {
    move_by (_velocity_x*game_speed, _velocity_y*game_speed);
    _check_bounds ();
  }

  private void _check_bounds ()
  {
    float min_x = 0.0f;
    float max_x = get_parent ().width;
    float min_y = 0.0f;
    float max_y = get_parent ().height;

    if (center_x < min_x)
    {
      center_x = max_x;
    }
    if (center_x > max_x)
    {
      center_x = min_x;
    }
    if (center_y < min_y)
    {
      center_y = max_y;
    }
    if (center_y > max_y)
    {
      center_y = min_y;
    }
  }
}

public class ShipSprite : MobileSprite
{
  private bool _exploding;
  private ExplosionSprite _explosion;
  public uint _fired_bullets;

  public ShipSprite (string element_id)
  {
    Object (element_id: element_id);

    _exploding = false;
    _explosion = new ExplosionSprite ();
  }

  public bool exploded {
    get; set; default = false;
  }

  public uint score {
    get; set; default = 0;
  }

  public double health {
    get; set; default = 1.0;
  }

  public uint available_bullets {
    get; set; default = 10;
  }

  public uint fired_bullets {
    get { return _fired_bullets; }
    set
    {
      _fired_bullets = value;
      available_bullets_level = (double)(_available_bullets-_fired_bullets)/(double)_available_bullets;
    }
  }

  public double available_bullets_level {
    get; set; default = 1.0;
  }

  public void accelerate ()
  {
    double rotation = _degrees_to_rads (rotation_angle_z);
    double nx = GLib.Math.cos (rotation);
    double ny = GLib.Math.sin (rotation);
    velocity_x += (float)(nx*0.1);
    velocity_y += (float)(ny*0.1);
  }

  public void rotate_right ()
  {
    rotation_angle_z += 1.0;
  }

  public void rotate_left ()
  {
    rotation_angle_z -= 1.0;
  }

  public void explode (Gdk.Pixbuf[] frames)
  {
    _exploded = true;
    hide ();
    get_parent ().add_child (_explosion);

    _explosion.x = x;
    _explosion.y = y;
    _explosion.reset ();
    _explosion.frames = frames;
    _explosion.run ();
  }

  public bool hit (double bullet_damage)
  {
    health -= bullet_damage;
    return (health <= 0.0f);
  }

  public bool has_bullets ()
  {
    return (_fired_bullets < _available_bullets);
  }

  public void fire_bullet (MobileSprite bullet)
  {
    assert (has_bullets ());

    float rotation = (float)_degrees_to_rads (rotation_angle_z);
    float nx = GLib.Math.cosf (rotation);
    float ny = GLib.Math.sinf (rotation);

    bullet.center_x = center_x + nx*28.0f;
    bullet.center_y = center_y + ny*28.0f;
    bullet.velocity_x = velocity_x + nx*3.0f;
    bullet.velocity_y = velocity_y + ny*3.0f;

    fired_bullets++;
  }

  public void reset ()
  {
    _exploded = false;

    health = 1.0;
    fired_bullets = 0;
  }

  protected double _degrees_to_rads (double deg)
  {
    const double conv_factor = 2.0*GLib.Math.PI/360.0;
    return deg*conv_factor;
  }
}

public class ExplosionSprite : Clutter.Actor
{
  private Clutter.Image _frame_image;
  private Clutter.Timeline _timeline;
  private Gdk.Pixbuf[] _frames;
  private uint _frame_nb;

  public ExplosionSprite ()
  {
    Object ();

    _frame_image = new Clutter.Image ();

    _timeline = new Clutter.Timeline (1000); // 1 sec
    _timeline.new_frame.connect ((msecs) => {
      try
      {
        var frame = _frames[_frame_nb];
        _frame_image.set_data (frame.get_pixels (),
          Cogl.PixelFormat.RGBA_8888,
          frame.width,
          frame.height,
          frame.rowstride);

        content = _frame_image;
        width = frame.width;
        height = frame.height;

        _frame_nb++;

        if (_frame_nb == _frames.length)
        {
          _timeline.stop ();
          get_parent ().remove_child (this);
        }
      }
      catch (GLib.Error e)
      {
        stderr.printf ("%s\n", e.message);
      }
    });
  }

  public Gdk.Pixbuf[] frames
  {
    set { _frames = value; }
  }

  public void reset ()
  {
    _frame_nb = 0;
  }

  public void run ()
  {
    _timeline.start ();
  }
}

public class BulletSprite : MobileSprite
{
  public BulletSprite (string element_id)
  {
    Object (element_id: element_id);
  }
}

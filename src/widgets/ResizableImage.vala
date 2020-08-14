/*  This file is part of Cawbird, a Gtk+ linux Twitter client forked from Corebird.
 *  Copyright (C) 2020 IBBoard
 *
 *  Cawbird is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Cawbird is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with cawbird.  If not, see <http://www.gnu.org/licenses/>.
 */

 private class ResizableImage : Gtk.Image {
    /* We use MIN_ constants in case the media has not yet been loaded */
    private const int MIN_HEIGHT     = 40;
    private const int MIN_WIDTH      = 40;
    public Cairo.ImageSurface? image_surface = null;
    private Gdk.Window? event_window = null;
  
    public ResizableImage () {
        this.get_style_context ().add_class ("inline-media");
    }

    private void get_draw_size (int allocated_width, int allocated_height,
                                out int width, out int height, out double scale) {
        if (image_surface != null) {
            var w = image_surface.get_width () * 1.0;
            var h = image_surface.get_height () * 1.0;
            scale = double.min(1.0, double.min(allocated_width / w, allocated_height / h));
            width = (int) Math.floor(w * scale);
            height = (int) Math.floor(h * scale);
        }
        else {
            width = MIN_WIDTH;
            height = MIN_HEIGHT;
            scale = 1;
        }
    }
  
    public override bool draw (Cairo.Context ct) {
        if (image_surface != null) {
            int widget_width = get_allocated_width ();
            int widget_height = get_allocated_height ();
    
            int draw_width, draw_height;
            double scale;
            this.get_draw_size (widget_width, widget_height, out draw_width, out draw_height, out scale);
            //debug("Allocation: %d×%d; Media: %d×%d; Scaled: %d×%d (%f)", widget_width, widget_height, image_surface.get_width(), image_surface.get_height(), draw_width, draw_height, scale);

            double draw_x = (widget_width - draw_width) / 2;
            
            ct.save ();
            ct.rectangle (0, 0, widget_width, widget_height);
            ct.scale (scale, scale);
            double draw_y = (widget_height - draw_height) / 2;
            //debug("Draw x: %f; Draw y: %f", draw_x, draw_y);
            ct.set_source_surface (image_surface, draw_x / scale, draw_y / scale);
            ct.paint ();
            ct.restore ();

            var sc = this.get_style_context ();
            sc.render_background (ct, draw_x, 0, draw_width, draw_height);
            sc.render_frame      (ct, draw_x, 0, draw_width, draw_height);

            if (this.has_visible_focus ()) {
                sc.render_focus (ct, draw_x + 2, 2, draw_width - 4, draw_height - 4);
            }
        }
  
        return Gdk.EVENT_PROPAGATE;
    }
  
    public override Gtk.SizeRequestMode get_request_mode () {
      return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
    }
  
    public override void get_preferred_height (out int minimum,
                                               out int natural) {
        int media_height = image_surface != null ? image_surface.get_height() : MIN_HEIGHT; 
        minimum = int.max (media_height, MIN_HEIGHT);
        natural = media_height;
    }
  
    public override void get_preferred_height_for_width (int width,
                                                         out int minimum,
                                                         out int natural) {
      int media_width = image_surface != null ? image_surface.get_width() : MIN_WIDTH;
      int media_height = image_surface != null ? image_surface.get_height() : MIN_HEIGHT;
  
      double scale = width / (double) media_width;
      
      if (scale >= 1) {
        minimum = media_height;
      } else {
        minimum = (int) Math.floor (media_height * scale);
      }
  
      natural = media_height;
    }
  
    public override void get_preferred_width_for_height (int height,
                                                         out int minimum,
                                                         out int natural) {

        int media_width = image_surface != null ? image_surface.get_width() : MIN_WIDTH;
        int media_height = image_surface != null ? image_surface.get_height() : MIN_HEIGHT;

        double scale = height / (double) media_height;

        if (scale >= 1) {
            minimum = media_width;
        } else {
            minimum = (int) Math.floor (media_width * scale);
        }
    
        natural = media_width;
    }
  
    public override void get_preferred_width (out int minimum,
                                              out int natural) {
        int media_width = image_surface != null ? image_surface.get_width() : MIN_WIDTH;
    
        minimum = int.min (media_width, MIN_WIDTH);
        natural = media_width;
    }
  
    public override void realize () {
        this.set_realized (true);
        int widget_width = get_allocated_width ();
        int widget_height = get_allocated_height ();

        int draw_width, draw_height;
        double scale;
        this.get_draw_size (widget_width, widget_height, out draw_width, out draw_height, out scale);
    
        Gdk.WindowAttr attr = {};
        attr.x = 0;
        attr.y = 0;
        attr.width = draw_width;
        attr.height = draw_height;
        attr.window_type = Gdk.WindowType.CHILD;
        attr.visual = this.get_visual ();
        attr.wclass = Gdk.WindowWindowClass.INPUT_ONLY;
        attr.event_mask = this.get_events () |
                            Gdk.EventMask.BUTTON_PRESS_MASK |
                            Gdk.EventMask.BUTTON_RELEASE_MASK |
                            Gdk.EventMask.TOUCH_MASK |
                            Gdk.EventMask.ENTER_NOTIFY_MASK |
                            Gdk.EventMask.LEAVE_NOTIFY_MASK;
    
        Gdk.WindowAttributesType attr_mask = Gdk.WindowAttributesType.X |
                                            Gdk.WindowAttributesType.Y;
        Gdk.Window window = this.get_parent_window ();
        this.set_window (window);
        window.ref ();
    
        this.event_window = new Gdk.Window (window, attr, attr_mask);
        this.register_window (this.event_window);
    }
  
    public override void unrealize () {
        if (this.event_window != null) {
            this.unregister_window (this.event_window);
            this.event_window.destroy ();
            this.event_window = null;
        }

        base.unrealize ();
    }
  
    public override void map () {
        base.map ();
    
        if (this.event_window != null) {
            this.event_window.show ();
        }
    }
  
    public override void unmap () {
        if (this.event_window != null) {
            this.event_window.hide ();
        }
    
        base.unmap ();
    }
  
    public override void size_allocate (Gtk.Allocation alloc) {
        base.size_allocate (alloc);
    
        int draw_width;
        int draw_height;
        double scale;
    
        if (this.get_realized ()) {
            this.get_draw_size (alloc.width, alloc.height, out draw_width, out draw_height, out scale);
            int draw_x = (alloc.width / 2) - (draw_width / 2);
            this.event_window.move_resize (alloc.x + draw_x, alloc.y, draw_width, draw_height);
        }
    }
  
    public override bool enter_notify_event (Gdk.EventCrossing evt) {
        if (evt.window == this.event_window &&
            evt.detail != Gdk.NotifyType.INFERIOR) {
            this.set_state_flags (this.get_state_flags () | Gtk.StateFlags.PRELIGHT,
                                true);
        }
    
        return Gdk.EVENT_PROPAGATE;
    }
  
    public override bool leave_notify_event (Gdk.EventCrossing evt) {
        if (evt.window == this.event_window &&
            evt.detail != Gdk.NotifyType.INFERIOR) {
            this.set_state_flags (this.get_state_flags () & ~Gtk.StateFlags.PRELIGHT,
                                true);
        }
    
        return Gdk.EVENT_PROPAGATE;
    }
  }
  
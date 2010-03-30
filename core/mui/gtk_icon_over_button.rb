
miquire :mui, 'webicon'

require 'gtk2'

class Gtk::IconOverButton < Gtk::EventBox

  class Updater
    attr_reader :observable

    def initialize(observable, obj)
      @obj = obj.object_id
      @observable = observable
      observable.add_observer(self)
    end

    def update
      obj = self.obj
      obj.redraw() if(obj)
    end

    def remove
      @observable.delete_observer(self)
      @obj = nil
      @observable = nil
    end

    def obj
      begin
        ObjectSpace._id2ref(@obj)
      rescue
        self.remove
        nil
      end
    end

  end

  attr_accessor :visible_button

  def initialize(*args)
    Gtk::Lock.synchronize do
      super(*args)
      self.set_app_paintable(true)
      self.signal_connect('expose_event'){ |win, evt| redraw(evt); false }
      self.signal_connect('enter_notify_event'){
        Gtk::Lock.synchronize do
          self.visible_button = true
          self.redraw()
        end
        false
      }
      self.signal_connect('leave_notify_event'){
        Gtk::Lock.synchronize do
          self.visible_button = false
          self.redraw()
        end
        false
      }
      self.signal_connect('motion_notify_event'){ |widget, event|
        Gtk::Lock.synchronize do
          self.redraw(event, :focus => self.get_focused_button(event.x, event.y))
        end
        false
      }
      self.signal_connect('button_release_event'){ |widget, event|
        Gtk::Lock.synchronize do
          case(event.button)
          when 1:
              self.call_proc( self.get_focused_button(event.x, event.y) )
          when 3:
              @sub_button_proc.call if @sub_button_proc
          end
        end
        false
      }
      @background = nil
      @visible_button = false
      @children = Array.new
      @grid_size = [1, 1]
      @button_back = nil
      @button_back_over = nil
      @options = Array.new
      @sub_button_proc = nil
      self.bg_color = Gdk::Color.new(65535, 65535, 65535)
    end
  end

  def get_focused_button(x, y)
    w, h = *self.geometry
    return false if(x < 0) or (x >= w) or (y < 0) or (y >= h)
    gw, gh = *self.grid_geometry
    return (x/gw).to_i + (y/gh).to_i * grid_x
  end

  def call_proc(index)
    return false if not(index)
    proc = @options[index][:proc]
    if(proc) then
      Gtk::Lock.synchronize do
        result = proc.call(@children[index], @options[index])
        if(result.is_a?(Array)) then
          @options[index] = result[1]
          result = result[0]
        end
        if(result.is_a?(Gtk::Image)) then
          @children[index] = result
          self.redraw
        end
      end
      true
    end
  end

  def background=(val)
    @background.remove if @background
    @background = Updater.new(val, self)
  end

  def background
    @background.observable if @background
  end

  def bg_color=(color)
    Gtk::Lock.synchronize do
      Gdk::Colormap.system.alloc_color(color, false, true)
      @bgcolor = color
    end
  end

  def set_grid_size(x, y)
    @grid_size = [x, y]
  end

  def grid_x
    @grid_size[0]
  end

  def grid_y
    @grid_size[1]
  end

  def redraw(event = nil, options = {})
    return false if not(self.realized?)
    Gtk::Lock.synchronize do
      gc = Gdk::GC.new(self.window)
      width = self.width_request
      height = self.height_request
      gc.set_foreground(@bgcolor)
      self.window.draw_rectangle(gc, true, 0, 0, width, height)
      self.window.draw_pixbuf(gc, self.background.pixbuf, 0, 0, 0, 0, width, height, Gdk::RGB::DITHER_NONE, 0, 0)
      self.draw_buttons(gc, options[:focus])
    end
  end

  def draw_buttons(gc, focus=nil)
    self.grid_y.times{ |y|
      self.grid_x.times{ |x|
        index = x + y*grid_x
        widget = @children[index]
        if(widget) then
          Gtk::Lock.synchronize do
            gw, gh = *self.grid_geometry
            args = [0, 0, gw*x, gh*y, gw, gh, Gdk::RGB::DITHER_NONE, 0, 0]
            if(self.visible_button) then
              if(focus == index) then
                self.window.draw_pixbuf(gc, @button_back_over.pixbuf, *args) if @button_back_over
              else
                self.window.draw_pixbuf(gc, @button_back.pixbuf, *args) if @button_back
              end
              self.window.draw_pixbuf(gc, widget.pixbuf, *args)
            elsif(@options[index][:always_show])
              self.window.draw_pixbuf(gc, widget.pixbuf, *args)
            end
          end
        end
      }
    }
  end

  def geometry
    self.size_request
  end

  def grid_geometry
    w, h = *self.geometry
    [w/self.grid_x, h/self.grid_y]
  end

  def sub_button
    @sub_button_proc = lambda{ yield }
  end

  def add(widget, options={})
    Gtk::Lock.synchronize do
      w, h = *self.grid_geometry
      if(widget.is_a?(String)) then
        @children << Gtk::WebIcon.new(widget, w, h)
      else
        @children << widget
      end
      options[:proc] = lambda{ |*args| yield *args } if defined? yield
      @options << options
    end
    self
  end

  def set_buttonback(usual, over = nil)
    Gtk::Lock.synchronize do
      if(usual.is_a?(String)) then
        w, h = *self.grid_geometry
        @button_back = Gtk::WebIcon.new(usual, w, h)
      end
      if(over.is_a?(String)) then
        w, h = *self.grid_geometry
        @button_back_over = Gtk::WebIcon.new(over, w, h)
      end
    end
    self
  end

end
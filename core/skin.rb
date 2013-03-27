# -*- coding: utf-8 -*-

class Skin

  def self.get(filename)
    fn = File.join(*[path, filename].flatten)
    return Skin.get('notfound.png') if 'notfound.png' != filename and not FileTest.exist?(fn)
    fn
  end

  def self.path
    [File.dirname(__FILE__), "skin", "data"]
  end

end

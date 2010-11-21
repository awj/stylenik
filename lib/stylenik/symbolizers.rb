# base properties/methods for all symbolizers
class Node
  attr_accessor :style, :mapnik_attributes
  def initialize(attr)
    @mapnik_attributes = []
  end
  
  def is_cased?
    false
  end

  def attrs(map=nil)
    arr = {}
    @mapnik_attributes.each {|a| arr[a] = instance_variable_get("@#{a.to_s}") }
    return arr
  end

  def apply_style(map, name, bonus_attrs)
    raise "Someone forgot to provide a type tag for this symbolizer, #{self}" if @type.nil?
    res = map.styles[@type][name] || {}
    filtered_attrs = bonus_attrs.reject {|k,v| v.nil?}
    filtered_res   = res.reject {|k,v| v.nil?}
    return filtered_res.merge(filtered_attrs)
  end
end


class TextSymbolizer < Node
  attr_accessor :name, :fontset_name, :size, :fill, :halo_radius, :wrap_width
  def initialize(attr)
    @name = attr[:name]
    @fontset_name = attr[:fontset_name]
    @size = attr[:size]
    @fill = attr[:fill]
    @halo_radius = attr[:halo_radius]
    @wrap_width = attr[:wrap_width]
    @type = :text
    @style = attr[:style]
    @mapnik_attributes = [:name, :fontset_name, :size, :fill, :halo_radius, :wrap_width]
  end

  def attrs(map=nil)
    a = super

    res = apply_style(map, style, a)
    return res.reject {|k,v| v.nil?}
  end

  def generate(map, xml)
    xml.TextSymbolizer(attrs(map))
  end
end

class LineSymbolizer < Node
  attr_accessor :stroke, :stroke_width, :stroke_opacity, :stroke_linejoin, :stroke_linecap, :stroke_dasharray
  def initialize(attr)
    @type = :line

    @stroke = attr[:stroke]
    @stroke_width = attr[:stroke_width]
    @stroke_opacity = attr[:stroke_opacity]
    @stroke_linejoin = attr[:stroke_linejoin]
    @stroke_linecap = attr[:stroke_linecap]
    @stroke_dasharray = attr[:stroke_dasharray]
    
    @mapnik_attributes = [:stroke, :stroke_width, :stroke_opacity, :stroke_linejoin, :stroke_linecap, :stroke_dasharray]
  end

  def attrs(map=nil)
    a = super

    res = apply_style(map, style, a)
    return res.reject {|k,v| v.nil?}
  end

  def generate(map, xml)
    att = attrs(map)
    xml.LineSymbolizer do
      att.each do |k,v|
        n = k.to_s.gsub '_', '-'
        xml.CssParameter({:name => n}, v)
      end
    end
  end
end

class Node
  # pick the appropriate class for the given node type
  def self.from_attrs(attr)
    type = attr.delete :type
    case type
    when :text then TextSymbolizer.new attr
    when :line then LineSymbolizer.new attr
    else raise "Style type is not recognized: #{type}"
    end
  end
end

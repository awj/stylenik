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
    res = apply_style(map, style, arr)
    filtered = res.reject {|k,v| v.nil?}
    return map.replace_vars(filtered)
  end

  def generate_cssparams(map, xml)
    attrs(map).each do |k,v|
      n = k.to_s.gsub '_', '-'
      v = v.join ', ' if v.is_a? Array
      xml.CssParameter({:name => n}, v)
    end
  end

  def apply_style(map, name, bonus_attrs)
    raise "Someone forgot to provide a type tag for this symbolizer, #{self}" if @type.nil?
    res = map.styles[@type][name] || {}
    filtered_attrs = bonus_attrs.reject {|k,v| v.nil?}
    filtered_res   = res.reject {|k,v| v.nil?}
    return filtered_res.merge(filtered_attrs)
  end
end

class PolygonSymbolizer < Node
  attr_accessor :fill, :fill_opacity, :gamma

  def initialize(attr)
    @type = :polygon
    @mapnik_attributes = [:fill, :fill_opacity, :gamma]

    @fill = attr[:fill]
    @fill_opacity = attr[:fill_opacity]
    @gamma = attr[:gamma]
  end

  def generate(map, xml)
    xml.PolygonSymbolizer do
      generate_cssparams(map, xml)
    end
  end
end

class PointSymbolizer < Node
  attr_accessor :allow_overlap, :avoid_edges, :unlock_image, :opacity
  attr_accessor :character_spacing, :dx, :dy
  attr_accessor :face_name, :fontset_name, :fill, :force_odd_labels, :halo_fill
  attr_accessor :horizontal_alignment, :justify_alignment, :label_position_tolerance
  attr_accessor :line_spacing, :max_char_angle_delta, :min_distance, :name
  attr_accessor :placement, :size, :spacing, :text_convert, :text_ratio, :vertical_alignment
  attr_accessor :wrap_before, :wrap_character, :wrap_width

  def initialize(attrs)
    @type = :point
    @mapnik_attributes = [:allow_overlap, :avoid_edges, :unlock_image, :opacity,
                          :character_spacing, :dx, :dy,
                          :face_name, :fontset_name, :fill, :force_odd_labels, :halo_fill,
                          :horizontal_alignment, :justify_alignment, :label_position_tolerance,
                          :line_spacing, :max_char_angle_delta, :min_distance, :name,
                          :placement, :size, :spacing, :text_convert, :text_ratio, :vertical_alignment,
                          :wrap_before, :wrap_character, :wrap_width]

    @allow_overlap = attrs[:allow_overlap]
    @avoid_edges = attrs[:avoid_edges]
    @unlock_image = attrs[:unlock_image]
    @opacity = attrs[:opacity]
    @character_spacing = attrs[:character_spacing]
    @dx = attrs[:dx]
    @dy = attrs[:dy]
    @face_name = attrs[:face_name]
    @fontset_name = attrs[:fontset_name]
    @fill = attrs[:fill]
    @force_odd_labels = attrs[:force_odd_labels]
    @halo_fill = attrs[:halo_fill]
    @horizontal_alignment = attrs[:horizontal_alignment]
    @justify_alignment = attrs[:justify_alignment]
    @label_position_tolerance = attrs[:label_position_tolerance]
    @line_spacing = attrs[:line_spacing]
    @max_char_angle_delta = attrs[:max_char_angle_delta]
    @min_distance = attrs[:min_distance]
    @name = attrs[:name]
    @placement = attrs[:placement]
    @size = attrs[:size]
    @spacing = attrs[:spacing]
    @text_convert = attrs[:text_convert]
    @text_ratio = attrs[:text_ratio]
    @vertical_alignment = attrs[:vertical_alignment]
    @wrap_before = attrs[:wrap_before]
    @wrap_character = attrs[:wrap_character]
    @wrap_width = attrs[:wrap_width]
  end

  def generate(map, xml)
    xml.PointSymbolizer(attrs(map))
  end
end

class ShieldSymbolizer < Node
  # common attributes
  attr_accessor :allow_overlap, :avoid_edges, :unlock_image, :opacity
  # image attributes
  attr_accessor :base, :file, :height, :type, :width
  # text attributes
  attr_accessor :character_spacing, :dx, :dy
  attr_accessor :face_name, :fontset_name, :fill, :force_odd_labels, :halo_fill
  attr_accessor :horizontal_alignment, :justify_alignment, :label_position_tolerance
  attr_accessor :line_spacing, :max_char_angle_delta, :min_distance, :name
  attr_accessor :placement, :size, :spacing, :text_convert, :text_ratio, :vertical_alignment
  attr_accessor :wrap_before, :wrap_character, :wrap_width

  def initialize(attrs)
    @type = :shield
    @mapnik_attributes = [:allow_overlap, :avoid_edges, :unlock_image,
                          :opacity, :base, :file, :height, :type, :width,
                          :character_spacing, :dx, :dy, :face_name,
                          :fontset_name, :fill, :force_odd_labels, :halo_fill,
                          :horizontal_alignment, :justify_alignment,
                          :label_position_tolerance, :line_spacing,
                          :max_char_angle_delta, :min_distance, :name,
                          :placement, :size, :spacing, :text_convert,
                          :text_ratio, :vertical_alignment, :wrap_before,
                          :wrap_character, :wrap_width]

    @allow_overlap = attr[:allow_overlap]
    @avoid_edges = attr[:avoid_edges]
    @unlock_image = attr[:unlock_image]
    @opacity = attr[:opacity]
    @base = attr[:base]
    @file = attr[:file]
    @height = attr[:height]
    @type = attr[:type]
    @width = attr[:width]
    @character_spacing = attr[:character_spacing]
    @dx = attr[:dx]
    @dy = attr[:dy]
    @face_name = attr[:face_name]
    @fontset_name = attr[:fontset_name]
    @fill = attr[:fill]
    @force_odd_labels = attr[:force_odd_labels]
    @halo_fill = attr[:halo_fill]
    @horizontal_alignment = attr[:horizontal_alignment]
    @justify_alignment = attr[:justify_alignment]
    @label_position_tolerance = attr[:label_position_tolerance]
    @line_spacing = attr[:line_spacing]
    @max_char_angle_delta = attr[:max_char_angle_delta]
    @min_distance = attr[:min_distance]
    @name = attr[:name]
    @placement = attr[:placement]
    @size = attr[:size]
    @spacing = attr[:spacing]
    @text_convert = attr[:text_convert]
    @text_ratio = attr[:text_ratio]
    @vertical_alignment = attr[:vertical_alignment]
    @wrap_before = attr[:wrap_before]
    @wrap_character = attr[:wrap_character]
    @wrap_width = attr[:wrap_width]
  end

  def generate(map, xml)
    xml.ShieldSymbolizer(attrs(map))
  end
  
end

class TextSymbolizer < Node
  attr_accessor :avoid_edges, :allow_overlap, :character_spacing, :dx, :dy
  attr_accessor :face_name, :fontset_name, :fill, :force_odd_labels, :halo_fill
  attr_accessor :horizontal_alignment, :justify_alignment, :label_position_tolerance
  attr_accessor :line_spacing, :max_char_angle_delta, :min_distance, :name, :opacity
  attr_accessor :placement, :size, :spacing, :text_convert, :text_ratio, :vertical_alignment
  attr_accessor :wrap_before, :wrap_character, :wrap_width
  def initialize(attr)
    @type = :text
    @mapnik_attributes = [:avoid_edges, :allow_overlap, :character_spacing, :dx, :dy,
                          :face_name, :fontset_name, :fill, :force_odd_labels, :halo_fill,
                          :horizontal_alignment, :justify_alignment, :label_position_tolerance,
                          :line_spacing, :max_char_angle_delta, :min_distance, :name, :opacity,
                          :placement, :size, :spacing, :text_convert, :text_ratio, :vertical_alignment,
                          :wrap_before, :wrap_character, :wrap_width]

    @avoid_edges = attr[:avoid_edges]
    @allow_overlap = attr[:allow_overlap]
    @character_spacing = attr[:character_spacing]
    @dx = attr[:dx]
    @dy = attr[:dy]
    @face_name = attr[:face_name]
    @fontset_name = attr[:fontset_name]
    @fill = attr[:fill]
    @force_odd_labels = attr[:force_odd_labels]
    @halo_fill = attr[:halo_fill]
    @horizontal_alignment = attr[:horizontal_alignment]
    @justify_alignment = attr[:justify_alignment]
    @label_position_tolerance = attr[:label_position_tolerance]
    @line_spacing = attr[:line_spacing]
    @max_char_angle_delta = attr[:max_char_angle_delta]
    @min_distance = attr[:min_distance]
    @name = attr[:name]
    @opacity = attr[:opacity]
    @placement = attr[:placement]
    @size = attr[:size]
    @spacing = attr[:spacing]
    @text_convert = attr[:text_convert]
    @text_ratio = attr[:text_ratio]
    @vertical_alignment = attr[:vertical_alignment]
    @wrap_before = attr[:wrap_before]
    @wrap_character = attr[:wrap_character]
    @wrap_width = attr[:wrap_width]
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

  def generate(map, xml)
    att = attrs(map)
    xml.LineSymbolizer do
      generate_cssparams(map, xml)
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
    when :polygon then PolygonSymbolizer.new attr
    when :shield then ShieldSymbolizer.new attr
    else raise "Style type is not recognized: #{type}"
    end
  end
end

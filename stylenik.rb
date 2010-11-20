require 'rubygems'
require 'nokogiri'

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
  attr_accessor :stroke, :stroke_width, :stroke_opacity
  def initialize(attr)
    @type = :line

    @stroke = attr[:stroke]
    @stroke_width = attr[:stroke_width]
    @stroke_opacity = attr[:stroke_opacity]

    @mapnik_attributes = [:stroke, :stroke_width, :stroke_opacity]
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

class Rule
  attr_accessor :start, :stop, :filter, :nodes

  def initialize(settings)
    @start  = settings[:start]
    @stop   = settings[:stop]
    @filter = settings[:filter]
    @nodes  = []
  end

  # node definitions and shortcuts
  def node(attrs)
    n = Node.from_attrs attrs
    @nodes << n
  end

  def text(attrs)
    m = {:type => :text}.merge attrs
    node(m)
  end

  def line(attrs)
    m = {:type => :line}.merge attrs
    node(m)
  end

  def generate(map, xml)
    xml.Rule do
      xml.MaxScaleDenominator map.scales[start] unless start.nil?
      xml.MinScaleDenominator map.scales[stop]  unless stop.nil?
      xml.Filter filter unless filter.nil?

      nodes.each do |n|
        n.generate map, xml
      end
    end
  end
end

class RuleMaker
  attr_accessor :type, :layer
  def initialize(type, layer)
    @type  = type
    @layer = layer
  end

  # reuse their stop argument if given
  def zoom(num, args)
    ruleattr = {:start => num, :stop => args[:stop] || num + 1, :filter => args[:filter]}
    args.delete :stop
    args.delete :filter
    args[:type] ||= @type
    layer.rule(ruleattr) do |r|
      r.node(args)
    end
  end
end

class Layer
  attr_accessor :name, :status, :srs, :settings, :rules
  def initialize(name, the_settings)
    @name = name
    @settings = {}
    @settings = the_settings.delete :base unless the_settings[:base].nil?
    @status   = the_settings.delete(:status) || "on"
    @srs      = the_settings.delete :srs
    @settings = @settings.merge the_settings

    @rules = []
  end

  # rule definitions and shortcuts
  def gen_rule(filters, block)
    r = Rule.new filters

    block.call r

    @rules << r
  end
  
  def rule(filters, &block)
    gen_rule filters, block
  end

  def shortcut_rule(type, attrs, block)
    if attrs
      ruleset = {}
      ruleset[:start]  = attrs.delete :start
      ruleset[:stop]   = attrs.delete :stop
      ruleset[:filter] = attrs.delete :filter

      rule(ruleset) do |r|
          case type
          when :text then r.text(attrs)
          when :line then r.line(attrs)
          else raise "Style shortcut not implemented for #{type}"
          end
        end
    else
      r = RuleMaker.new type, self
      block.call r
    end
  end

  def text(attrs=nil, &block)
    shortcut_rule :text, attrs, block
  end

  def line(attrs=nil, &block)
    shortcut_rule :line, attrs, block
  end

  def attrs(map)
    {
      :name   => name,
      :status => status,
      :srs    => srs || map.srs
    }
  end

  def generate_styles(map, xml)
    # TODO, handle casings
    xml.Style(:name => name) do
      @rules.each do |r|
        r.generate(map, xml)
      end
    end
    return [name]
  end

  def generate(map, xml)
    raise "Layer type is not defined" if not settings.keys.include? :type
    att = attrs(map)
    # TODO generate styles
    stylenames = generate_styles(map, xml)
    xml.Layer(att) do
      stylenames.each do |n|
        xml.StyleName n
      end
      xml.Datasource do
        settings.each { |k,v| xml.Parameter({:name => k},v) }
      end
    end
  end
end

class Map
  attr_accessor :bgcolor, :srs, :buffer_size, :layers, :styles, :var, :scales, :fontsets

  def initialize(attr)
    @bgcolor     = attr[:bgcolor]
    @srs         = attr[:srs]
    @buffer_size = attr[:buffer_size].to_s
    @scales      = attr[:scales]
    @fontsets    = {}
    @styles      = {:text => {}, :polygon => {}, :line => {}, :point => {}, :shield => {}}
    @layers      = []
    @var         = {}
  end

  def scales_between(start, stop=1.0, step_div=2.0)
    scale_arr = []
    curr      = start
    while curr > stop
      scale_arr << curr.to_i
      curr = curr / step_div
    end
    @scales = scale_arr
  end

  def first_scale(fst)
    scales_between fst
  end

  def fontset(settings)
    @fontsets = fontsets.merge settings
  end

  # style templates
  def text(name, attrs)
    @styles[:text][name] = attrs
  end

  def line(name, attrs)
    @styles[:line][name] = attrs
  end

  # layer definitions and shortcuts
  def gen_layer(name, settings, block)
    l = Layer.new name, replace_vars(settings)

    block.call l

    @layers << l
  end

  def layer(name, settings, &block)
    gen_layer name, settings, block
  end

  def postgis(name, settings, &block)
    new_set = {:type => :postgis}.merge settings
    gen_layer(name, new_set, block)
  end

  def shape(name, settings, &block)
    new_set = {:type => :postgis}.merge settings
    gen_layer(name, new_set, block)
  end

  def replace_vars(settings)
    s = {}
    settings.each do |k,v|
      s[k] = var.has_key?(v) ? var[v] : v
    end
    s
  end

  def attrs
    {
      :bgcolor => bgcolor,
      :srs => srs,
      :buffer_size => buffer_size
    }
  end

  def generate
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.Map(attrs) do
        fontsets.each do |k,v|
          xml.FontSet(:name => k) do
            v.each do |name|
              xml.Font(:face_name => name)
            end
          end
        end
        layers.each { |l| l.generate(self, xml) }
      end
    end

    puts builder.to_xml
  end
end

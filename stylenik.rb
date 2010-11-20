require 'rubygems'
require 'nokogiri'

class Node
  def is_cased?
    false
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
  end

  def attrs
    a = {
      :name => name,
      :fontset_name => fontset_name,
      :size => size,
      :fill => fill,
      :halo_radius => halo_radius,
      :wrap_width => wrap_width,
    }

    a.reject {|k,v| v.nil?}
  end

  def generate(map, xml)
    xml.TextSymbolizer(attrs)
  end
  
end

class Node
  # pick the appropriate class for the given node type
  def self.from_attrs(attr)
    type = attr.delete :type
    case type
    when :text then TextSymbolizer.new attr
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

  def text(attrs=nil, &block)
    if attrs
      ruleset = {}
      ruleset[:start]  = attrs.delete :start
      ruleset[:stop]   = attrs.delete :stop
      ruleset[:filter] = attrs.delete :filter

      rule ruleset do |r|
        r.text attrs
      end
    else
      r = RuleMaker.new :text, self
      block.call r
    end
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
    @styles      = {}
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

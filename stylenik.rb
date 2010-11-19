require 'rubygems'
require 'nokogiri'

class TextSymbolizer
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
    {
      :name => name,
      :fontset_name => fontset_name,
      :size => size,
      :fill => fill,
      :halo_radius => halo_radius,
      :wrap_width => wrap_width,
    }
  end

  def generate(xml)
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

  def generate(map, xml)
    xml.Rule do
      xml.MaxScaleDenominator start unless start.nil?
      xml.MinScaleDenominator stop  unless stop.nil?
      xml.Filter filter unless filter.nil?

      nodes.each do |n|
        n.generate map, xml
      end
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

    # todo run block on rule

    @rules.append r
  end
  
  def rule(filters, &block)
    gen_rule filters, block
  end

  def attrs(map)
    {
      :name   => name,
      :status => status,
      :srs    => srs || map.srs
    }
  end

  def generate_styles(map, xml)
    # TODO handle casings
    xml.Style do
      @rules.each { |r| r.generate(map, xml) }
    end
  end

  def generate(map, xml)
    raise "Layer type is not defined" if not settings.keys.include? :type
    att = attrs(map)
    # TODO generate styles
    stylenames = generate_styles(map, xml)
    xml.Layer(att) do
      stylenames.each { |n| xml.StyleName n }
      xml.Datasource do
        settings.each { |k,v| xml.Parameter({:name => k},v) }
      end
    end
  end
end

class Map
  attr_accessor :bgcolor, :srs, :buffer_size, :layers, :styles, :var

  def initialize(attr)
    @bgcolor     = attr[:bgcolor]
    @srs         = attr[:srs]
    @buffer_size = attr[:buffer_size].to_s
    @styles      = {}
    @layers      = []
    @var         = {}
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
        layers.each { |l| l.generate(self, xml) }
      end
    end

    puts builder.to_xml
  end
end

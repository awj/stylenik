require 'rubygems'
require 'nokogiri'

class TextSymbolizer
  attr_accessor :name, :fontset_name, :size, :fill, :halo_radius, :wrap_width
  def initialize(attr)
    @name = name
    @fontset_name = fontset_name
    @size = size
    @fill = fill
    @halo_radius = halo_radius
    @wrap_width = wrap_width
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

  def attrs(map)
    {
      :name   => name,
      :status => status,
      :srs    => srs || map.srs
    }
  end

  def generate(map, xml)
    att = attrs(map)
    # TODO generate styles 
    xml.Layer(att) do
      #TODO reference styles
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

  def layer(name, settings, &block)
    l = Layer.new name, replace_vars(settings)
    # TODO run layer definition block

    @layers << l
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

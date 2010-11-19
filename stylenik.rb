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
  attr_accessor :name, :settings, :rules
  def initialize(name, the_settings)
    @name = name
    @settings = {}
    @settings = the_settings.delete :base unless the_settings[:base].nil?
    @settings = @settings.merge the_settings
  end

  def generate(xml)
    settings.each
  end
end

class Map
  attr_accessor :bgcolor, :srs, :buffer_size, :layers, :styles

  def initialize(attr)
    @bgcolor     = attr[:bgcolor]
    @srs         = attr[:srs]
    @buffer_size = attr[:buffer_size].to_s
    @styles      = {}
    @layers      = []
  end

  def layer(name, settings, &block)
    
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
        xml.example "test"
      end
    end

    puts builder.to_xml
  end
end

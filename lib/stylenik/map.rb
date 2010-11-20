require 'rubygems'
require 'nokogiri'

require 'layer'

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

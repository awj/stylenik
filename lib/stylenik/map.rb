# require 'rubygems'
require 'nokogiri'

require 'stylenik/layer'

class Map
  attr_accessor :bgcolor, :srs, :border_size, :layers, :styles, :var, :scales, :fontsets, :databases, :file_path

  def initialize(attr)
    @bgcolor     = attr[:bgcolor]
    @srs         = attr[:srs]
    @border_size = attr[:border_size]
    @scales      = attr[:scales]
    @fontsets    = {}
    @styles      = {:text => {}, :polygon => {}, :line => {}, :point => {}, :shield => {}}
    @layers      = []
    @var         = {}
    @databases   = {}
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

  # merge any non-root names with the defined file path
  def merge_path(name)
    return name if name.to_s.match(/^\/|([A-Za-z]:)/)

    if file_path.nil?
      $stderr.puts "File path is not defined, used for completion of #{name}"
      exit 1
    end
    
    return File.join(file_path, name.to_s)
  end

  def database(settings)
    @databases = databases.merge settings
  end

  def default_database
    if databases.size == 1
      return databases.values.first
    else
      return {}
    end
  end

  # style templates
  def text(name, attrs)
    @styles[:text][name] = attrs
  end

  def line(name, attrs)
    @styles[:line][name] = attrs
  end

  # layer definitions and shortcuts
  def gen_layer(name, settings, block=nil)
    l = Layer.new name, settings

    block.call l unless block.nil?

    @layers << l
    return l
  end

  def layer(name, settings={}, &block)
    return gen_layer(name, settings, block)
  end

  def postgis(name, settings={}, &block)
    new_set = {:type => :postgis}.merge settings
    new_set[:table => name] if new_set[:table].nil?
    return gen_layer(name, new_set, block)
  end

  def shape(name, settings={}, &block)
    new_set = {:type => :shape}.merge settings
    new_set[:file] = name if new_set[:file].nil?
    return gen_layer(name, new_set, block)
  end

  def replace_vars(settings)
    s = {}
    settings.each do |k,v|
      if (k != :type && k != :fontset_name) && v.is_a?(Symbol)
        if var.has_key? v
          s[k] = var[v]
        else
          $stderr.puts "Undefined variable #{v}"
          exit 1
        end
      elsif k == :fontset_name && !fontsets.keys.include?(v)
        $stderr.puts "Undefined fontset: #{v}"
        exit 1
      elsif k == :file
        sk[k] = merge_path(v.to_s)
      else
        s[k] = v
      end
    end
    s
  end

  def attrs
    {
      :bgcolor => bgcolor,
      :srs => srs,
      :border_size => border_size
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

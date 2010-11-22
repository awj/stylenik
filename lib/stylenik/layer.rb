require 'stylenik/rule'

class RuleMaker
  attr_accessor :type, :layer, :defaults
  def initialize(type, layer, defaults={})
    @type  = type
    @layer = layer
    @defaults = defaults
  end

  # reuse their stop argument if given
  def zoom(num, args={})
    ruleattr = {:start => num, :stop => args[:stop] || num, :filter => args[:filter] || @defaults[:filter]}
    args.delete :stop
    args.delete :filter
    d = @defaults.clone
    d.delete :filter
    d.delete :stop
    d.delete :start
    args[:type] ||= @type
    layer.rule(ruleattr) do |r|
      r.node d.merge(args)
    end
  end
end

class Layer
  attr_accessor :name, :status, :srs, :settings, :rules, :base_symbol
  def initialize(the_name, the_settings)
    @name = the_name
    @settings = Hash.new
    if the_settings[:base].is_a? Symbol
      @base_symbol = the_settings.delete :base
      @settings    = Hash.new
    else
      @settings = the_settings.delete :base unless the_settings[:base].nil?
    end
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

    if block.nil?
      ruleset = {}
      ruleset[:start]  = attrs.delete :start
      ruleset[:stop]   = attrs.delete :stop
      ruleset[:filter] = attrs.delete :filter
      rule(ruleset) do |r|
        case type
        when :text then r.text(attrs)
        when :line then r.line(attrs)
        when :polygon then r.polygon(attrs)
        when :shield then r.shield(attrs)
        else raise "Style shortcut not implemented for #{type}"
        end
      end
    else
      r = RuleMaker.new type, self, attrs
      block.call r
    end
  end

  def text(attrs={}, &block)
    shortcut_rule :text, attrs, block
  end

  def line(attrs={}, &block)
    shortcut_rule :line, attrs, block
  end

  def polygon(attrs={}, &block)
    shortcut_rule :polygon, attrs, block
  end

  def shield(attrs={}, &block)
    shortcut_rule :shield, attrs, block
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

  def merge_postgis(map)
    settings[:table] = name if settings[:table].nil?
      
    if base_symbol.nil?
      new_set = map.default_database.merge settings
      @settings = new_set
    else
      if map.databases[base_symbol].nil?
        $stderr.puts "No database settings defined at #{base_symbol}, used by layer #{name}"
        exit 1
      else
        new_settings = map.databases[base_symbol].merge settings
        @settings = new_settings
      end
    end
  end

  def generate(map, xml)
    raise "Layer type is not defined" if not settings.keys.include? :type
    # fix up settings by merging the file path with relative file names
    $stderr.puts "Layer #{name} has no defined style rules" if rules.size == 0
    settings[:file] = map.merge_path(settings[:file]) unless settings[:file].nil?

    merge_postgis(map) if settings[:type] == :postgis
    
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

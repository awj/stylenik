require 'rule'

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

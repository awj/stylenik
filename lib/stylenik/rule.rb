require 'symbolizers'

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

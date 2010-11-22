require 'stylenik/symbolizers'

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

  def polygon(attrs)
    node({:type => :polygon}.merge(attrs))
  end

  def shield(attrs)
    node({:type => :shield}.merge(attrs))
  end

  def generate(map, xml)
    xml.Rule do
      xml.MaxScaleDenominator map.scales[start] unless start.nil?
      xml.MinScaleDenominator map.scales[stop+1]  unless stop.nil?
      xml.Filter filter unless filter.nil?

      nodes.each do |n|
        n.generate map, xml
      end
    end
  end
end

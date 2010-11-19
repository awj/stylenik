require 'stylenik'

map = stylenik.map :bgcolor => "rgb(255,255,255)" :srs => "+proj=latlong +datum=WGS84", :buffer_size => 256

# defining fontsets
map.fontset :regular => ["Fontin Regular", "unifont Medium"]

map.scales [28000000, 14000000, ...]
# or provide first scale only (rest are sequence of 1/2)
# map.first_scale 28000000
# or provide first and last scale (fill in middle with sequence of 1/2
# map.scales 28000000, 1068

# can define variables as regular ruby.
water_color = "rgb(240, 240, 240)"

# or let the map object know about them so they can be updated. Just
# use the symbol and the map object will fill in the default or
# user-provided value.
map.var[:water_color] = "rgb(240, 240, 240)"

# defining style templates
map.text :water, :fontset_name => :italic, :size => 20, :fill => water_color
map.polygon :water => :fill => water_color

# using style templates
map.layer :oceans, :table => 'ocean_labels', :base => dbsettings do |l|
  # l.rule creates a style rule. acceptable forms are:
  l.rule :start => 2, :stop => 3, :filter => "filter expression" do |r|
    r.text :style => :water
  end
  # can override the style settings with
  l.rule :start => 3, :stop => 4, :filter => "filter expression" do |r|
    r.text :style => :water, :size => 24
  end
  # or a short version, when you're only creating one type of
  # symbolization
  l.text :start => 4, :stop => 5, :filter => "filter expression", :style => :water
  # shorthand once-per-zoom definitions
  l.text do |r|
    r.zoom 2, :filter => "filter expression", :style => :water
    r.zoom 3, :stop => 5, :filter => "filter expression", :style => :water, :size => 24
  end

  # short hand for road casings. Results in two layers, one with just
  # the outer portions of casings, the other with the inner portion
  # and any other stylings. casing styling is controlled through
  # prepending "casing_" to normal attributes

  l.casing :start => 4, :stop => 5, :filter => "filter expression", :style => :some_line, :casing_width => 15
  
end

map.generate

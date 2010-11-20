require 'stylenik'

m = Map.new :bgcolor => "rgb(255,255,255)", :srs=> "thesrs", :buffer_size => 256

m.first_scale 280000000

m.fontset :regular => ["Fontin Regular", "unifont Medium"]

water_color = "rgb(240, 240, 240)"
m.text :water, :fontset_name => :italic, :size => 20, :fill => water_color
m.line :water, :stroke => water_color

m.var[:postgres_user] = 'dummy'

m.postgis :test, :table => "gis", :user => :postgers_user do |l|
  l.text :start => 0, :stop => 3, :fill => :foo
  l.line :start => 0, :stop => 3, :stroke_width => 0.5
end

m.postgis :test2, :table => 'gis', :user => :postgres_user do |l|
  l.line do |r|
    r.zoom 2, :filter => "filter expression", :style => :water
    r.zoom 3, :stop => 5, :filter => "filter expression", :style => :water
  end
end

m.generate

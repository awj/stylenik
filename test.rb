require 'stylenik'

m = Map.new :bgcolor => "rgb(255,255,255)", :srs=> "thesrs", :buffer_size => 256

m.first_scale 280000000

m.var[:postgres_user] = 'dummy'

m.postgis :test, :table => "gis", :user => :postgers_user do |l|
  l.text :start => 0, :stop => 3, :fill => :foo
  l.text do |r|
    r.zoom 2, :filter => "filter expression", :style => :water
    r.zoom 3, :stop => 5, :filter => "filter expression", :style => :water, :size => 24
  end
end

m.generate

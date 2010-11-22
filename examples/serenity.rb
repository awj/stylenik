require 'rubygems'
require 'stylenik'

m = Map.new :bgcolor => "rgb(255,255,255)", :srs => "+proj=latlong +datum=WGS84", :border_size => 128

m.scales = [250000000000, 500000000, 200000000, 100000000, 50000000, 25000000, 12500000, 6500000, 3000000, 1500000, 750000, 400000, 200000, 100000, 50000, 25000, 12500, 5000, 2500]

m.database(:default => {
             :host => 'localhost',
             :user => 'gis',
             :password => 'gis',
             :dbname => 'gis',
             :srid => 4326,
             :estimate_extent => false,
             :extent => "-180,-90,180,90"
           })

m.file_path = "/data"

m.var[:landmass_color] = "rgb(235,231,225)"
m.var[:water_color] = "rgb(61,162,202)"
m.var[:urban_land] = "rgb(235,70,110)"
m.var[:highway_color] = "rgb(139,69,19)"
m.var[:text_color] = "rgb(240,240,240)"
m.var[:landmass_text] = "rgb(58, 37, 5)"

m.fontset :regular => ["Fontin Regular", "unifont Medium"]
m.fontset :italic  => ["Fontin Italic", "unifont Medium"]
m.fontset :bold    => ["Fontin Bold", "unifont Medium"]

bathymetry = [["Nat_earth/10m-bath-0", "rgb(66,172,217)"],
              ["Nat_earth/10m-bath-200", "rgb(65,170,214)"],
              ["Nat_earth/10m-bath-1000", "rgb(64,168,211)"],
              ["Nat_earth/10m-bath-2000", "rgb(63,166,208)"],
              ["Nat_earth/10m-bath-3000", "rgb(62,164,205)"],
              ["Nat_earth/10m-bath-4000", :water_color],
              ["Nat_earth/10m-bath-5000", :water_color],
              ["Nat_earth/10m-bath-6000", "rgb(60,160,199)"],
              ["Nat_earth/10m-bath-7000", "rgb(59,158,196)"],
              ["Nat_earth/10m-bath-8000", "rgb(58,156,193)"],
              ["Nat_earth/10m-bath-9000", "rgb(57,154,190)"],
              ["Nat_earth/10m-bath-10000", "rgb(56,152,187)"]]

bathymetry.each do |level|
  file  = level[0]
  color = level[1]
  m.shape(file, :file => file) { |l| l.polygon :fill => color }
end

m.shape(:landmass, :file => "Nat_earth/10m-land") do |l|
  l.polygon :start => 0, :stop => 6, :fill => :landmass_color
end

m.shape(:landmass_rest, :file => "4326/processed_p_4326_d") do |l|
  l.polygon :start => 6, :fill => :landmass_color
end

m.shape(:islands, :file => "Nat_earth/10m-islands") do |l|
  l.polygon :start => 5, :stop => 7, :fill => :landmass_color
end

m.postgis(:highways, :table =>
          "(select way, name from roads_line where highway = 'motorway') as highways") do |l|
  l.line(:start => 8, :stop => 10, :stroke => :highway_color,
         :stroke_width => 0.8, :stroke_opacity => 0.4,
         :stroke_linejoin => 'round', :stroke_linecap => 'round')
end

m.shape(:urban, :file => "Nat_earth/10m-urban") do |l|
  l.polygon :start => 8, :stop => 10, :fill => :urban_land, :fill_opacity => 0.5
end

# m.postgis(:health_ed, :table => "health_education_polygon") do |l|
# end

# m.postgis(:attractions, :table => "attractions_polygon") do |l|
# end

# m.postgis(:parks, :table => "parks_polygon") do |l|
# end

# m.postgis(:schools, :table => "schools_polygon") do |l|
# end

filter = "[COUNTRYNAM]='US' or [COUNTRYNAM]='Russia' or [COUNTRYNAM]='Australia' or [COUNTRYNAM]='Canada' or [COUNTRYNAM]='China' or [COUNTRYNAM]='Brazil'"
m.shape(:selected_states, :file => "Nat_earth/10m-admin1") do |l|
  l.line(:filter => filter, :stroke => "rgb(80,80,80)", :stroke_dasharray => [5,5]) do |r|
    r.zoom 3, :stroke_width => 0.25, :stroke_opacity => 0.5
    r.zoom 4, :stroke_width => 0.5, :stroke_opacity => 0.8
  end
end

# Will reuse the layer name as the table name if it is not provided
# directly.
m.postgis(:admin_boundaries_line) do |l|
  l.line(:start => 5, :stop => 7, :filter => "[admin_level] = 4",
         :stroke => "rgb(80,80,80)", :stroke_width => 0.25, :stroke_opacity => 0.5, :stroke_dasharray => [5,5])
  
  l.line(:filter => "[admin_level] = 2", :stroke_opacity => 0.5, :stroke => "rgb(80,80,80)") do |r|
    r.zoom 2, :stop => 4, :stroke_width => 0.3
    r.zoom 4, :stroke_width => 0.5
    r.zoom 5, :stroke_width => 0.7, :stroke_opacity => 0.4, :stroke_dasharray => [10,10]
  end
end

# m.shape(:lakes, :file => "Nat_earth/10m-lakes") do |l|
# end

# m.shape(:admin, :file => "Nat_earth/10m-admin0") do |l|
# end

# m.shape(:rivers_110, :file => "Nat_earth/110m-rivers") do |l|
# end

# m.shape(:rivers_50, :file => "Nat_earth/50m-rivers") do |l|
# end

# m.shape(:rivers_10, :file => "Nat_earth/10m-rivers") do |l|
# end

m.postgis(:ocean_labels, :table => 'ocean_labels') do |l|
  l.text(:name => 'name', :fontset_name => :italic, :opacity => 0.8, :fill => :text_color, :size => 20) do |r|
    r.zoom 2
    r.zoom 3
  end
end

# m.postgis(:water_areas, :table => "small_water_poly") do |l|
# end

# m.postgis(:water_lines, :table => "water_lines") do |l|
# end

# m.postgis(:all_roads, :table => "roads_line") do |l|
# end

# m.postgis(:aeroways, :table => "aeroway_line") do |l|
# end

# t = "(select way, name from roads_line where highway = 'motorway' or highway = 'trunk' or highway = 'motorway_link' or highway = 'trunk_link') as highways"
# m.postgis(:highways, :table => t) do |l|
# end

table = "(select way,name from location_labels where place = 'country' order by population desc, z_order desc) as continents"
m.postgis(:country_labels, :table => table) do |l|
  l.text(:fontset_name => :regular, :fill => :landmass_text, :name => 'name', :min_distance => 10) do |r|
    r.zoom 3, :size => 20, :min_distance => 64
    r.zoom 4, :size => 24, :opacity => 0.7
    r.zoom 5, :size => 28, :opacity => 0.7
  end
end

m.generate

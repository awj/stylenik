require 'rubygems'
require 'stylenik'

m = Map.new :bgcolor => "rgb(255,255,255)", :srs => "+proj=latlong +datum=WGS84", :border_size => 128

m.scales = [280000000, 140000000, 70000000, 35000000, 17500000, 8750000, 4375000, 2187500, 1093750, 546875, 273437, 136718, 68359, 34179, 17089, 8544, 4272, 2136, 1068, 534, 267, 133, 66, 33, 16, 8, 4, 2, 1]

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

bathymetry = [["Nat_earth/10m-bath-0",     "rgb(66,172,217)"],
              ["Nat_earth/10m-bath-200",   "rgb(65,170,214)"],
              ["Nat_earth/10m-bath-1000",  "rgb(64,168,211)"],
              ["Nat_earth/10m-bath-2000",  "rgb(63,166,208)"],
              ["Nat_earth/10m-bath-3000",  "rgb(62,164,205)"],
              ["Nat_earth/10m-bath-4000",  :water_color],
              ["Nat_earth/10m-bath-5000",  :water_color],
              ["Nat_earth/10m-bath-6000",  "rgb(60,160,199)"],
              ["Nat_earth/10m-bath-7000",  "rgb(59,158,196)"],
              ["Nat_earth/10m-bath-8000",  "rgb(58,156,193)"],
              ["Nat_earth/10m-bath-9000",  "rgb(57,154,190)"],
              ["Nat_earth/10m-bath-10000", "rgb(56,152,187)"]]

bathymetry.each do |level|
  file  = level[0]
  color = level[1]
  m.shape(file, :file => file) { |l| l.polygon :fill => color }
end

m.shape("Nat_earth/10m-land").polygon(:start => 0, :stop => 6, :fill => :landmass_color)
m.shape("Nat_earth/10m-land-uglytest")

m.shape("4326/processed_p_4326_d").polygon(:start => 6, :fill => :landmass_color)

m.shape("Nat_earth/10m-islands").polygon(:start => 5, :stop => 7, :fill => :landmass_color)

m.postgis(:highways, :table =>
          "(select way, name from roads_line where highway = 'motorway') as highways") do |l|
  l.line(:start => 8, :stop => 10, :stroke => :highway_color,
         :stroke_width => 0.8, :stroke_opacity => 0.4,
         :stroke_linejoin => 'round', :stroke_linecap => 'round')
end

m.shape("Nat_earth/10m-urban").polygon(:start => 8, :stop => 10, :fill => :urban_land, :fill_opacity => 0.5)

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

m.shape("Nat_earth/10m-lakes").polygon(:start => 0, :stop => 6, :fill => :water_color)

m.postgis(:ocean_labels, :table => 'ocean_labels') do |l|
  l.text(:name => 'name', :fontset_name => :italic, :opacity => 0.8, :fill => :text_color, :size => 20) do |r|
    r.zoom 2
    r.zoom 3
  end
end

table = "(select way,name from location_labels where place = 'country' order by population desc, z_order desc) as continents"
m.postgis(:country_labels, :table => table) do |l|
  l.text(:fontset_name => :regular, :fill => :landmass_text, :name => 'name', :min_distance => 10) do |r|
    r.zoom 3, :size => 20, :min_distance => 64
    r.zoom 4, :size => 24, :opacity => 0.7
    r.zoom 5, :size => 28, :opacity => 0.7
  end
end

m.generate

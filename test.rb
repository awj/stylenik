require 'stylenik'

m = Map.new :bgcolor => "rgb(255,255,255)", :srs=> "thesrs", :buffer_size => 256

m.var[:postgres_user] = 'dummy'

m.postgis :test, :table => "gis", :user => :postgers_user do |r|

end

m.generate

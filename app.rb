require 'cuba'
require 'cuba/render'
require 'yaml'
require 'json'
require 'open-uri'
require 'haml'

Cuba.plugin Cuba::Render
Cuba.settings[:render][:template_engine] = 'haml'

Cuba.use Rack::Session::Cookie, :secret => "$3cr3t$3ss|0n"

Cuba.use Rack::Static,
  root: "public",
  urls: ["/assets"]

Cuba.define do

  db = YAML::load_file '_db.yml'

  on ':id' do |id|
    #id = id.to_i
    db = db[id]
    render('poll/index', db: db)
  end

  on root do
    render('home/index')
  end

end

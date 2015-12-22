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

  on post do
    on ':id' do |id|

      #event = { 'title' => req.POST['title'] }
      #db.push(event)

      #File.open("_db.yml", 'w') do |file|
      #  file.write db.to_yaml
      #end

      res.write req.POST['title']
      puts req.POST['title']
      #res.redirect id
    end
  end

  on 'new' do
    id = Digest::MD5.hexdigest( 'asdasdasd' )
    render('poll/new', id: id)
  end

  on ':id/result' do |id|
    db = db[id]
    render('poll/result', db: db)
  end

  on ':id' do |id|
    db = db[id]
    render('poll/index', db: db)
  end

  on root do
    render('home/index', db: db)
  end

end

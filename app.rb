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
    on ':id' do
      # Categoria
      db[id]['categoria'] = req.POST['categoria']
      # Local
      db[id]['local']['nombre'] = req.POST['local_nombre']
      db[id]['local']['goles'] = req.POST['local_goles']
      # Visitante
      db[id]['visitante']['nombre'] = req.POST['visitante_nombre']
      db[id]['visitante']['goles'] = req.POST['visitante_goles']
      # Partido
      db[id]['partido'] = req.POST['partido']
      # Tiempo
      db[id]['tiempo'] = req.POST['tiempo']

      File.open("_db.yml", 'w') do |file|
        file.write db.to_yaml
      end

      res.redirect "#{id}"
    end
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

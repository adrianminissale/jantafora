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

    ## To submit a vote
    on 'vote/:id' do |id|

      vote = { 'name' => req.POST['name'],
               'mail' => req.POST['mail'],
               'date' => req.POST['date'],
               'time' => req.POST['time'],
               'zone' => req.POST['zone']}

      votes_array = db[id]['votes'].to_a

      # Validar que no se siga votando
      if is_event_finished id

      else
        db[id]['votes'].to_a.push(vote)
        File.open("_db.yml", 'w') do |file|
          file.write db.to_yaml
        end
      end

      # Chequear si votes.count == guests para disparar una notificacion

    end

    ## To submit an event
    on ':id' do |id|

      puts req.env['HTTP_MOBILE']

      db[id] =  { 'title' => req.POST['title'],
                  'name' => req.POST['name'],
                  'mail' => req.POST['mail'],
                  'date' => req.POST['date'],
                  'time' => req.POST['time'],
                  'zone' => req.POST['zone'],
                  'guests' => req.POST['guests'],
                  'visibility' => req.POST['visibility'],
                  'votes' => []}

      File.open("_db.yml", 'w') do |file|
        file.write db.to_yaml
      end

      res.write db[id].to_json
    end
  end

  ## Mobile view to create an event
  on 'new' do
    id = Digest::MD5.hexdigest( 'asdasdasd' )
    render('poll/new', id: id)
  end

  ## Returns the results of an event
  on 'result/:id' do |id|

    if is_event_finished id

    else
    # Si votes.count == guets => finalizo el evento y ver la fecha
    # Si visibility == true, parseo y devuelvo el resultado acutal
    # Si visibility == false, devuelvo la cantidad de votantes o los que votaron

    db = db[id]
    render('poll/result', db: db)
  end

  on 'myevents/:mail' do |mail|
    #Buscar los eventos en los que figura el :mail

  end

  ## Returns an event
  on ':id' do |id|
    db = db[id]
    render('poll/index', db: db)
  end

  ## Home
  on root do
    render('home/index', db: db)
  end


  def is_event_finished(id)
    return db[id]['votes'].to_a.count.to_s == db[id]['guests'].to_s
  end

end

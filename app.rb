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

  def is_event_finished(db, id)
    return db[id]['votes'].count.to_s == db[id]['guests'].to_s
  end

  def is_event_visible(db, id)
    return db[id]['visibility'].to_s == 'true'
  end

  def iterate_db(db, id, key)
    voters = Hash.new
    db[id][key].each do |value|
      voters[value] = 0
      db[id]['votes'].each do |voter|
        voter[key].each do |voter_value|
          if voter_value == value
            voters[value] = voters[value] + 1
          end
        end
      end
    end

    return voters
  end

  on post do

    ## To submit a vote
    on 'vote/:id' do |id|

      vote = { 'name' => req.POST['name'],
               'mail' => req.POST['mail'],
               'date' => req.POST['date'],
               #'time' => req.POST['time'],
               'zone' => req.POST['zone']}

      # Validar que no se siga votando
      if is_event_finished db, id

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

    voters = Hash.new
    if is_event_finished db, id

    else
      if  is_event_visible db, id
        voters['dates'] = iterate_db db, id, 'date'
        voters['zones'] = iterate_db db, id, 'zone'
        res.write voters

      else
        #Devuelvo los que votaron
        voters['voters'] = db[id]['guests']
        voters['names'] = Array.new

        db[id]['votes'].each do |voter|
          voters['names'].push(voter['name'])
        end
        res.write voters
      end

    end


  end

  ## Returns a event list
  on 'myevents/:mail' do |mail|

    events = Hash.new

    db.each do |key, value|
      if value['mail'] == mail
        events[key] = value['title']
      else
        value['votes'].each do |votes_value|
          if votes_value['mail'] == mail
            events[key] = value['title']
          end
        end
      end
    end

    res.write events
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
end

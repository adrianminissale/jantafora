require 'cuba'
require 'cuba/render'
require 'yaml'
require 'json'
require 'open-uri'
require 'haml'
require 'mail'
require 'net/http'

Cuba.plugin Cuba::Render
Cuba.settings[:render][:template_engine] = 'haml'

Cuba.use Rack::Session::Cookie, :secret => "$3cr3t$3ss|0n"

Cuba.use Rack::Static,
  root: "public",
  urls: ["/assets"]

Mail.defaults do
  delivery_method :smtp,
  { :address              => "smtp.sendgrid.net",
    :port                 => 587,
    :domain               => "jantafora.com",
    :user_name            => "adrianminissale",
    :password             => "j4nt4f0r4.c0m",
    :authentication       => 'plain',
    :enable_starttls_auto => true }
end

Cuba.define do

  db = YAML::load_file '_db.yml'

  def check_expired_date date
    return Date.parse date <= Date.today
  end

  def get_result_of_an_event(db, id)
    voters = Hash.new
    voters['dates'] = orderHash iterate_db db, id, 'date'
    voters['zones'] = orderHash iterate_db db, id, 'zone'
    return voters
  end

  def get_recommendations(zones, dates, guests)
    #Horario!!
    #yyyy-MM-dd
    basic_url = 'http://mapi.staging.restorando.com/restaurants.json?country=ar&region=buenos-aires&q='
    basic_url << zones + ","
    basic_url << "&diners="
    basic_url << guests.to_s
    basic_url << "&date="
    basic_url << dates

    url = URI.parse(basic_url)
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }

    return res.body
  end

  def send_mail(id, listOfMails)
    mail = Mail.deliver do
      to 'adrianminissale@gmail.com'
      from 'JantaFora <yay@jantafora.com>'
      subject ''
      text_part do
        body 'Hello world in text'
      end
      html_part do
        content_type 'text/html; charset=UTF-8'
        body '<a href="http://www.jantafora.com/result/id!!">Ir a los resultos</a>'
      end
    end
  end

  def orderHash(hash)
    hash.sort_by { |a, b| b }.reverse.to_h
  end

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

    on 'login' do
      on param('name') do |name|
        session['name'] = req.POST['name']
        session['mail'] = req.POST['mail']

        res.redirect "/poll/#{session['poll']}"
      end
    end

    ## To submit a vote
    on 'poll/:id' do |id|

      vote = { 'name' => session['name'],
               'mail' => session['mail'],
               'date' => req.POST['date'].values,
               'zone' => req.POST['zone'].values}

      # Validar que no se siga votando
      if is_event_finished db, id

      else
        db[id]['votes'].to_a.push(vote)
        File.open("_db.yml", 'w') do |file|
          file.write db.to_yaml
        end
      end

      # Chequear si votes.count == guests para disparar una notificacion
      res.redirect "/poll/#{id}"
    end

    ## To submit an event
    on 'poll' do

      puts req.env['HTTP_MOBILE']
      id = Digest::SHA1.hexdigest([Time.now, rand].join)

      db[id] =  { 'title' => req.POST['title'],
                  'name' => session['name'],
                  'mail' => session['mail'],
                  'date' => req.POST['date'].values,
                  'zone' => req.POST['zone'].values,
                  'time' => req.POST['time'],
                  'guests' => req.POST['guests'],
                  'expiration' => req.POST['expiration'],
                  'visibility' => req.POST['visibility'],
                  'votes' => []}

      File.open("_db.yml", 'w') do |file|
        file.write db.to_yaml
      end

      if req.env['HTTP_MOBILE'] == "true"
        res.write "OK".to_json
      else
        res.redirect "/poll/#{id}"
      end
    end

  end


  ############
  # end Post #
  ############


  ## Returns a event list
  # on 'myevents/:mail' do |mail|

  #   events = Hash.new

  #   db.each do |key, value|
  #     if value['mail'] == mail
  #       events[key] = value['title']
  #     else
  #       value['votes'].each do |votes_value|
  #         if votes_value['mail'] == mail
  #           events[key] = value['title']
  #         end
  #       end
  #     end
  #   end

  #   if req.env['HTTP_MOBILE'] == "true"
  #     res.write events.to_json
  #   else
  #     #ADRI VISTA
  #   end

  # end

  ## Share an event
  on 'share/:id' do |id|
    render('poll_share', id: id)
  end

  ## Returns an event to vote
  on 'poll/:id' do |id|

    #if session['user']
      #puts session['user']

      voters = Hash.new
      if is_event_finished db, id
        #Results
        voters = get_result_of_an_event db, id
        voters['recommendations'] = get_recommendations voters['zones'].first.first, voters['dates'].first.first, db[id]['guests']

        render('poll_result', db: db[id], voters: voters)
      else
        if is_event_visible db, id
          #Parcial Results
          voters = get_result_of_an_event db, id
        else
          #Devuelvo los que votaron
          voters['voters'] = db[id]['guests']
          voters['names'] = Array.new

          db[id]['votes'].each do |voter|
            voters['names'].push(voter['name'])
          end
        end

        render('poll_response', db: db[id])
      end
    #else
      #puts session['user']

      #session['poll'] = id
      #res.redirect '/login'
    #end

  end

  ## mobile
  on 'mobile' do
    render('installer')
  end

  ## 2nd Step
  on 'poll' do
    render('poll_create')
  end

  ## Login or 1st Step
  on 'login' do
    render('login')
  end

  ## Home
  on root do
    render('index')
  end
end

#Mandar un email

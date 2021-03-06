require_relative 'interactive'
require 'erb'
require 'pry'

class Racker
  GAMES_FILE_NAME = './lib/db/games.dat'

  def self.call(env)
    new(env).router.finish
  end

  def initialize(env)
    @request = Rack::Request.new(env)
    @help_string ||= 'Show'
    load_players_games
    @login = @request.params['id']
  end

  def web
    @games[@login]
  end

  def load_players_games
    @games = {}
    return unless File.exist? GAMES_FILE_NAME
    File.open(GAMES_FILE_NAME) do |file|
      @games = Marshal.load(file)
    end
  end

  def save_players_status
    File.open(GAMES_FILE_NAME, 'w+') do |file|
      Marshal.dump(@games, file)
    end
  end

  def router
    path = @request.path
    exception = ['/', '/show_help', '/new_game']
    path = 'error' if web == nil && !exception.include?(path)
    case path
      when '/' then render('index.html.erb')
      when '/new_game' then start_new_game
      when '/show_help' then show_help
      when '/show_hint' then show_hint
      when '/update_game' then update_game
      when '/save_res' then save_result
      when '/show_res' then show_result
      else Rack::Response.new('Not Found', 404)
    end
  end

  def start_new_game
    name = @request.params['name']
    level = @request.params['level']
    if name && level
      new_game = Interactive.new(name, level)
      @login = new_game.id
      @games[@login] = new_game
      web.start(web.level)
      web.status = :first_step
      save_players_status
      render('game.html.erb')
    else
      Rack::Response.new('Error in params. Name or level params not found!', 404)
    end
  end

  def show_help
    @help_string = @request.params['help_string'] == 'Show' ? 'Hide' : 'Show'
    render('index.html.erb')
  end

  def show_hint
    web.show_hint
    web.status = :hint
    save_players_status
    render('game.html.erb')
  end

  def update_game
    if @request.params['guess']
      web.set_offer(@request.params['guess'])
      web.status = :playing
    end
    save_players_status
    render('game.html.erb')
  end

  def save_result
    web.save_results
    show_result
  end

  def show_result
    web.load_scores_from_file
    render('show.html.erb')
  end

  def render(template)
    path = File.expand_path("../views/#{template}", __FILE__)
    page = ERB.new(File.read(path)).result(binding)
    Rack::Response.new(page)
  end

  def redirect_to(link)
    Rack::Response.new{|response| response.redirect(link + "?name=#{@login}")}
  end
end





require 'rav_codebreaker'


#module RavCodebreaker
#  def self.play(level)
#    begin
#      console = Console.new(level)
#      console.play
#    end while console.again?
#  end
#end

#RavCodebreaker.play(:beginner)
class Interactive
  EMPTY_NAME = 'Anonymous player'
  SCORES_FILE_NAME = './score.dat'

  attr_accessor :level, :status
  attr_reader :game, :name, :hints, :score

  def initialize
    @name = EMPTY_NAME
    @status = nil
    start
  end

  def start(level = :expert)
    @game = RavCodebreaker::Game.new(level)
    @game.start
    @game.offer = ''
    @hints = []
    @score = []
  end

  def set_offer(offer)
    @game.offer = offer
    @game.next_turn unless @game.format_error?
    puts "You result is \"#{@game.decode_offer}\"!"
  end

  def name=(name)
    @name = name 
    @name = EMPTY_NAME if name == '' 
  end

  def show_hint
    hint = @game.get_hint
    return unless hint
    @hints << "I exactly know that a number #{hint.first} is at position ##{hint.last + 1}"
  end

  def save_results
    load_scores_from_file
    player = {}
    player[:name] = @name
    player[:level] = @game.level
    player[:turns] = RavCodebreaker::Game::TURNS_COUNT[@game.level] - @game.turns_left
    player[:hints] = RavCodebreaker::Game::HINTS_COUNT[@game.level] - @game.hints_left
    player[:time] = Time.new
    @score << player
    File.open(SCORES_FILE_NAME, 'w+') do |file|
      Marshal.dump(@score, file)
    end
    #binding.pry
  end

  def load_scores_from_file
    return unless File.exist? SCORES_FILE_NAME
    File.open(SCORES_FILE_NAME) do |file|
      @score = Marshal.load(file)
    end
  end

  def show_hints_button?
     game.hints_left>0 && !game.win? && !game.game_over? 
  end

end
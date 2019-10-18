require 'json'
require 'curses'
include Curses

@allHotels = Hash.new
@goodHotels = []
@badHotels = []
@score = 0.0
@quit = false

def displayHotel(hotel)
  clear
  logo = `jp2a -b --size=90x30 #{hotel['image']}`

  setpos(3, 0); addstr(logo)
  setpos(95, 0); addstr("You arrive from your journey through #{hotel['city']}, #{hotel['country']}.\n")
  setpos(96, 0); addstr("You see the words: #{hotel['name']} - a #{hotel['category']} by #{hotel['brand']} on the door.\n")
  setpos(97, 0); addstr("Will you stay here tonight? (Y/N), or x to quit\n")
  setpos(98, 0); addstr("Your score is currently #{@score.to_i} - do you think this is a highly rated hotel?")
end

def getValue(hotel)
  if @goodHotels.include?(hotel['id']) then
    value = 3.0 * hotel['rating']
  else
    value = -3.0 * hotel['rating']
  end
  return value
end

def endGame()
  lines = `jp2a -b --size=90x30 https://i2.wp.com/www.wordsinspace.net/urban-media-archaeology/2011-fall/wp-content/uploads/2011/12/cowboy-sunset.jpg`
  setpos(3, 0); addstr(lines)
  setpos(97, (cols - 10) / 2); addstr("Your journey has ended... Your final score was #{@score.to_i}.")
  setpos(98, (cols - 10) / 2); addstr("press any key to exit")
  getch
  @quit = true
end

def promptToStay(hotel)
  answer = getch
  if answer.to_s.downcase == 'n' then
    @score -= getValue(hotel)
  elsif answer.to_s.downcase == 'x' then
    endGame()
  else
    @score += getValue(hotel)
  end
end

def loadContent(filename)
  File.readlines(filename).each do |line|
    hotel = Hash.new
    
    hotel_json = JSON.parse(line)

    if hotel_json['ratings'].nil? then
      # do nothing
    elsif hotel_json['ratings']['guest'].nil? then
      # do nothing
    elsif hotel_json['images'].nil? then
      # do nothing
    else
      hotel['id'] = hotel_json['property_id']
      hotel['name'] = hotel_json['name']
      hotel['city'] = hotel_json['address']['city'] || 'Unknown'
      hotel['country'] = hotel_json['address']['country_code'] || 'UKN'
      hotel['rating'] = hotel_json['ratings']['guest']['average'].to_f || 3.0
      if hotel['rating'] >= 4.3 then
        @goodHotels.push(hotel['id'])
      end
      if hotel['rating'] < 4.3 then
        @badHotels.push(hotel['id'])
      end
      hotel['brand'] = hotel_json['brand']['name'] || 'UKN'
      hotel['category'] = hotel_json['category']['name'] || 'UKN'
      featured_image = hotel_json['images'].select { | image | image['hero_image'] }
      url = featured_image[0]['links']['350px']['href'] || 'http://eventsontheedge.com/wordpress/wp-content/uploads/2010/07/IAM-red-logo.jpg'

      hotel['image'] = url
     
      displayHotel(hotel)
      refresh
      promptToStay(hotel)
      if(@quit) then
        return
      end
    end
  end
end

def main()
    loadContent(ARGV[0])
end

init_screen
begin
  crmode
  logo = `jp2a -b --size=90x20 crawl.jpg`
  setpos(3, 0); addstr(logo)
  setpos((lines - 5), 5)
  addstr("Travel the world and earn points by staying at highly-rated properties")
  setpos((lines - 4), 5)
  addstr("and avoiding less-highly rated properties.")
  setpos((lines - 3), 5)
  addstr("Press any key to start.")
  refresh
  getch
  main()
  refresh
ensure
  close_screen
end
require 'selenium-webdriver'
require 'nokogiri'
require 'open-uri'

base_url = "http://www.myscore.ru/football/usa/mls/standings/"
table_body_locator_css  = "tbody" 

driver = Selenium::WebDriver.for :firefox
driver.manage.timeouts.implicit_wait = 60

driver.get base_url

page = Nokogiri::HTML(driver.page_source) 

tr_list = page.css(table_body_locator_css)
              .css("tr")

team_ratio_hash = {}

tr_list.each do |tr|
	current_team = tr.css(".team_name_span a").text.strip 
	
	full_match_list = []

	tr.css(".matches-5 a").each do |element|
		full_match_list << element["title"]
	end

    previous_match_list = []
    full_match_list.delete_at(0)
    previous_match_list = full_match_list
    
    home_goals_scored 	 = 0
    guest_goals_scored   = 0
    home_goals_conceded  = 0
    guest_goals_conceded = 0
    
    scored_ratio   = 0
    conceded_ratio = 0

	previous_match_list.each do |element|
		element.gsub!(/\[.\]/, "")
		element.gsub!(/\[\/.\]/, "")
		element.gsub!(/&nbsp;/, "")
		element.gsub!(/\d{2}.\d{2}.\d{4}/,"")

        index_colon               = element.index(':')
		index_open_parenthesis    = element.index('(')
		index_dash                = element.index(' - ')
		index_closing_parenthesis = element.index(')') 

		first_number  = element[0, index_colon].to_i
		second_number = element[index_colon+1, index_open_parenthesis-2].to_i

		first_team  = element[index_open_parenthesis+1, index_dash-index_open_parenthesis-1]
		second_team = element[index_dash+3, index_closing_parenthesis-index_dash-3]

		if first_team.eql?(current_team)
			home_goals_scored += first_number
			home_goals_conceded += second_number
		else
			guest_goals_scored += second_number
			guest_goals_conceded += first_number
		end
	end
    
    scored_ratio   = (home_goals_scored*1.5 + guest_goals_scored*2)/5.0
	conceded_ratio = (home_goals_conceded*1.5 + guest_goals_conceded*1)/5.0

	#puts "scored_ratio - " + scored_ratio.to_s + " " + "conceded_ratio - " + conceded_ratio.to_s

    team_ratio_hash[current_team] = {team: current_team, scored_ratio: scored_ratio, conceded_ratio: conceded_ratio}
end 

tr_list.each do |tr|
	next_match = tr.at_css(".matches-5 a")["title"]

    puts "\n" + "next match" + "\n"

    next_match.gsub!(/\[.+\]/, "")    
    next_match.strip! 

    index_dash        = next_match.index(' - ')
	index_first_digit = next_match.index(/\d{2}.\d{2}.\d{4}/)     

	first_team  = next_match[0, index_dash]
	second_team = next_match[index_dash+3, index_first_digit-index_dash-4] 

	first_team_scored_second_team_conceded_ratio = 0
	first_team_conceded_second_team_scored_ratio = 0
	match_ratio                                  = 0

    first_team_scored_second_team_conceded_ratio = (team_ratio_hash[first_team][:scored_ratio] + 
		                                            team_ratio_hash[second_team][:conceded_ratio])/2
	first_team_conceded_second_team_scored_ratio = (team_ratio_hash[first_team][:conceded_ratio] + 
		                                            team_ratio_hash[second_team][:scored_ratio])/2	

	match_ratio = (first_team_scored_second_team_conceded_ratio + 
		           first_team_conceded_second_team_scored_ratio)/2 

	puts next_match

	puts match_ratio.to_s + 
	     " " + 
	     first_team_scored_second_team_conceded_ratio.to_s + 
	     " " + 
	     first_team_conceded_second_team_scored_ratio.to_s 
end 

driver.quit
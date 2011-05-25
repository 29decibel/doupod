#coding: utf-8
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'mechanize'
require 'fileutils'
require 'firewatir'

LOGIN_URL = "http://www.douban.com/accounts/login?source=radio"
LOVED_SONG_URL = "http://douban.fm/mine?&type=liked"

LOGIN_MAIL = "mike.d.1984@gmail.com"
LOGIN_PASSWORD = "618675"

def fetch_loved_songs
	agent = Mechanize.new
	agent.get(LOGIN_URL)
	if agent.page and agent.page.forms and agent.page.forms.count>0
		puts "i came to the login page..."
		agent.page.forms[0]["email"] = LOGIN_MAIL
		agent.page.forms[0]["password"] = LOGIN_PASSWORD
		agent.page.forms[0]["form_email"] = LOGIN_MAIL
		agent.page.forms[0]["form_password"] = LOGIN_PASSWORD

		puts "begin to submit the login page"
		agent.page.forms[0].submit

		agent.get(LOVED_SONG_URL)

		#get all pages numbers 
		max_page_number = agent.page.search("div.paginator a").map(&:inner_html).max {|num| num.to_i}
		puts max_page_number

		(0..max_page_number.to_i).each do |page_number|
			puts page_number
			url = "#{LOVED_SONG_URL}&start=#{9*page_number}"
			puts url
			get_song_info(agent,url).each do |song_info|
				get_download_address song_info
			end
		end
	else
		puts "can not redirect to login page"
	end
end

## given a agent and a url
# then grab the songs infomation
def get_song_info(agent,url)
	songs = []
	puts "now grabing the songs"
	page = agent.get(url)
	page.search("table.olts tr").map do |node|
		if node.search('td').count==3
			songs << {:name=>  "#{node.search('td')[0].inner_html}" ,:artist=>"#{node.search('td')[1].at('span').inner_html}",:id=>"#{node.search('td').last.at('a')[:id]}"}
		end
	end
	songs
end

GOOGLE_MUSIC_SEARCH = "http://www.google.cn/music/search?q="
D_L="http://www.google.cn/music/top100/musicdownload"
G_N="http://www.google.cn"

def get_download_address(song_info)
	song_name = song_info[:name]
	artist = song_info[:artist]
	id = song_info[:id]

	puts "name encoding is #{song_name.encoding} and force encoding result is #{song_name.force_encoding('GB2312')}"
	agent = Mechanize.new
	puts "begin finding the download link of #{song_name}......."
	agent.get("#{GOOGLE_MUSIC_SEARCH}#{song_name}")
	#find the first and then click
	download_links = agent.page.links.select {|link| link.node and link.node[:title]=="下载"}
	if download_links.count==0
		puts "_______song #{song_name} not found on google_________"
		return
	end
	raw_download_address = download_links.first.node[:onclick]
	download_address = raw_download_address[raw_download_address.index('x3d')+3..raw_download_address.index('x26resnum')-2]
	#find another download address
	song_search_para = download_address[download_address.index('?')..-1]
	puts "#{D_L}#{song_search_para}"
	agent.get("#{D_L}#{song_search_para}".sub('%3D','='))
	mp3_address = agent.page.search("div.download a").last[:href]

	#save audio file
	if File.exist? "#{id}.mp3"
		puts "mp3 file #{song_name} already exists  @@@@"
	else
		puts "begin save song #{song_name}......... which id is #{id}"
		open("#{id}.mp3",'wb') do |file|
			file<<open("#{G_N}#{mp3_address}").read
			puts "#{song_name} ===== saved ok ======="
		end
	end
	
end

fetch_loved_songs

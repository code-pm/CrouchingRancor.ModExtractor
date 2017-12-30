#
# Written by Jon Moter - https://github.com/jonmoter
#
# You are free to use this for personal use, in whatever way you see fit.
#
# Usage: bundle exec ruby get_mods.rb <username>
#

require 'nokogiri'
require 'open-uri'
require 'json'

def bail(msg, errcode: 1)
  STDERR.puts "ERROR: #{msg}"
  exit(errcode)
end

def info(msg)
  puts msg unless ENV['STDOUT']
end

class ModInfo
  SLOT_MAP = [nil, :square, :arrow, :diamond, :triangle, :circle, :cross]
  SLOT_REGEX =
  attr_reader :mod_elt

  def initialize(mod_elt)
    @mod_elt = mod_elt
  end

  def uid
    mod_elt.attributes['data-id'].value
  end

  def slot
    statmod_div = mod_elt.css('.pc-statmod').first
    id = /pc-statmod-slot(\d)/.match(statmod_div.attributes['class'])[1].to_i
    SLOT_MAP[id]
  end

  def primary_stat
    @primary_stat ||= stats_from(mod_elt.css('.statmod-stats-1 .statmod-stat').first)
  end

  def secondary_stats
    @secondary_stats ||= mod_elt.css('.statmod-stats-2 .statmod-stat').map do |elt|
      stats_from(elt)
    end
  end

  def modset
    @modset ||= begin
      alt_value = mod_elt.css('.statmod-img').first.attributes['alt']

      case alt_value
      when /Health/ ; then :health
      when /Offense/ ; then :offense
      when /Defense/ ; then :defense
      when /Speed/ ; then :speed
      when /Crit Chance/ ; then :critchance
      when /Crit Damage/ then :critdamage
      when /Potency/ ; then :potency
      when /Tenacity/ then :tenacity
      else
        bail "Unknown alt for modset: #{alt_value}"
      end
    end
  end

  def pipcount
    mod_elt.css('.statmod-pip').count
  end

  def level
    mod_elt.css('.statmod-level').first.content.to_i
  end

  def character_name
    mod_elt.css('.char-portrait-image img').first.attributes['alt'].value
  end

  def to_h
    h = {
      'mod_uid' => uid,
      'slot' => slot.to_s,
      'set' => modset.to_s,
      'level' => level.to_s,
      'pips' => pipcount.to_s,
      'primaryBonusType' => primary_stat[:stat],
      'primaryBonusValue' => primary_stat[:value],
      'characterName' => character_name
    }

    (1..4).each do |i|
      stat = secondary_stats[i-1] || {}
      h["secondaryType_#{i}"] = stat[:stat]
      h["secondaryValue_#{i}"] = stat[:value]
    end

    h
  end

  private

  def stats_from(elt)
    {
      stat: elt.css('.statmod-stat-label').first.content,
      value: elt.css('.statmod-stat-value').first.content
    }
  end
end

def download(username)
  all_mods = []
  idx = 1
  loop do
    doc = Nokogiri::HTML(open("https://swgoh.gg/u/#{username}/mods/?page=#{idx}"))
    mods = doc.css('.collection-mod').map {|elt| ModInfo.new(elt)}

    info "Downloaded page #{idx} for user #{username}, got #{mods.count} mods"
    all_mods += mods
    idx += 1
  end
rescue OpenURI::HTTPError
  bail "Could not find any mods for #{username}" if all_mods.empty?
  all_mods
end

username = ARGV[0]
bail("Username not specified") unless username

mods = download(username)
data = mods.map(&:to_h)
output = ENV['PRETTY'] ? JSON.pretty_generate(data) : data.to_json

if ENV['STDOUT']
  puts output
else
  outfile = ARGV[2] || "#{username}.json"
  File.write(outfile, output)
  info "Found #{mods.count} mods, wrote to #{outfile}"
end

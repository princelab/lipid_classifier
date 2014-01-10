require 'mechanize'
require 'pry'
require 'nokogiri'
LinkStruct = Struct.new(:name, :link) do 
  def to_s
    "#{@name}==>#{@link}"
  end
end

def putsv(thing)
  puts thing if $PERSONALVERBOSE
end
$PERSONALVERBOSE = false

def parse_link_for_struct(td)
   begin
     if td.nil? 
       resp = nil 
     elsif td.child.child.nil? 
       resp = nil
     else
       resp = LinkStruct.new(td.child.child.text, td.child.attributes['href'].value)
     end
   rescue => e
     binding.pry
   end
   resp
end

  Classification = Struct.new(:name, :category_code, :class_code, :subclass_code, :class_level4_code, :identifier)
def parse_classification_from_LMID(string) # add case fixing, and symbols where possible?
  classification = Classification.new(*[nil, string.scan(/LM(.{2})(.{2})(.{2})(.*)(.{4}$)/)].flatten)
  classification.name = CategoryCodeToNameMap[classification.category_code.to_sym]
  classification
end
TrainingSetNode = Struct.new(:lmid, :href, :classification) 
URLROOT = "http://www.lipidmaps.org"

OverviewEntry = Struct.new(:lmid_link, :name, :sysname, :cayman, :msms_link, :ion, :conditions_link)
DetailsEntry = Struct.new(:lmid, :ion_mode, :ion, :instrument, :ionization_type, :declustering_potential, :spray_V, :collision_energy, :protocol_link)

MasterEntry = Struct.new(:lmid, :lmid_link, :name, :sysname, :cayman, :msms_link, :ion, :ion_mode, :instrument, :ionization_type, :declustering_potential, :spray_V, :collision_energy, :protocol_name, :protocol_file) do 
  def join(separator: ",")
    self.map {|a| a.to_s}.to_a.join(separator)
  end
end


def wget_cmd(file)
  filename = file[/data\/(.*)$/,1]
  filename ||= ""
  binding.pry unless filename
  unless File.exist?(File.join('file_output', filename))
    system "wget -P file_output #{file}"
  end
  filename
end

class TableExtractor
  def self.extract_overview_table html
    doc = Nokogiri::HTML(html)
    resp = doc.xpath("//table/tr[@class='odd' or @class='even']").collect do |row|
      size = row.children.size
    begin
      lmid_link = parse_link_for_struct(row.at("td[1]"))
      name = row.at("td[3]").text.strip
      if row.at("td[10]").nil? # size < 9 and 
        putsv "td 10 is nil"
        if row.at("td[4]").nil? 
          sysname = row.at("td[5]").text.strip
          cayman = parse_link_for_struct(row.at("td[7]"))
          if row.at("td[8]").text.strip == "-"
            putsv "td8 is '-' which fouled it up"
            msms_link = parse_link_for_struct(row.at("td[9]"))
            ion = row.at("td[11]").text.strip
          else
            msms_link = parse_link_for_struct(row.at("td[8]"))
            ion = row.at("td[10]").text.strip
          end
          conditions_link = parse_link_for_struct(row.children.last)
        else
          sysname = row.at("td[4]").text.strip
          cayman = parse_link_for_struct(row.at("td[5]"))
          msms_link = parse_link_for_struct(row.at("td[6]"))
          ion = row.at("td[8]").text.strip
          conditions_link = parse_link_for_struct(row.children.last)
        end
      elsif row.at("td[11]").nil? # size < 10 and 
        putsv "td 10 isn't nil, but td 11 is"
        sysname = row.at("td[4]").text.strip
        cayman = parse_link_for_struct(row.at("td[5]"))
        msms_link = parse_link_for_struct(row.at("td[7]"))
        ion = row.at("td[9]").text.strip
        conditions_link = parse_link_for_struct(row.children.last)
      elsif row.at("td[4]").nil?
        putsv "td10 != nil, td11 != nil, but td4 == nil"
        sysname = row.at("td[5]").text.strip
        cayman = parse_link_for_struct(row.at("td[7]"))
        if row.at("td[8]").text.strip == "-"
          putsv "td8 is '-' which fouled it up"
          msms_link = parse_link_for_struct(row.at("td[9]"))
          ion = row.at("td[11]").text.strip
        end
        msms_link = parse_link_for_struct(row.at("td[8]"))
        ion = row.at("td[10]").text.strip
        conditions_link = parse_link_for_struct(row.children.last)
      else
        putsv "td10 != nil, td11 != nil, td4 != nil"
        sysname = row.at("td[4]").text.strip
        cayman = parse_link_for_struct(row.at("td[6]"))
        msms_link = parse_link_for_struct(row.at("td[7]"))
        ion = row.at("td[10]").text.strip
        conditions_link = parse_link_for_struct(row.children.last)
      end
    rescue NoMethodError => e
      oe = OverviewEntry.new(lmid_link, name, sysname, cayman, msms_link, ion, conditions_link)
      binding.pry
    end
      oe = OverviewEntry.new(lmid_link, name, sysname, cayman, msms_link, ion, conditions_link)
      binding.pry if conditions_link.nil?
      oe
    end
    resp
  end
  def self.extract_details_table html
    doc = Nokogiri::HTML(html)
    resp = doc.xpath("//table[@class='datatable']//td").map.to_a
    putsv "SIZE is wrong in details table" unless resp.size == 9
    if resp.size == 0
      DetailsEntry.new  # THERE ARE NO DETAILS!
    else
      arr = []
      8.times do |i|
        begin
          arr << resp[i].text
        rescue NoMethodError
          arr << nil
        end
      end
      protocol_link = parse_link_for_struct(resp[8])
      de = DetailsEntry.new(*arr, protocol_link)
      de
    end
  end
end




def run
  # Initialize Mechanize
  agent = Mechanize.new
  files_list = []
  parsed_links = {}

  root_page = agent.get("http://www.lipidmaps.org/data/standards/search.html")
  root_page.links_with(:href => /\/data\/standards\/standards.php\?lipidclass=LM/).map do |link|
    page = agent.get(link.href)
    resp = TableExtractor.extract_overview_table(page.body)
    details_resp = resp.map do |oe|
      oe.conditions_link ? TableExtractor.extract_details_table(agent.get(oe.conditions_link.link).body) : nil
    end
    [resp, details_resp].transpose.map do |oe, de|
# MasterEntry = Struct.new(:lmid, :lmid_link, :name, :sysname, :cayman, :msms_link, :ion, :ion_mode, :instrument, :ionization_type, :declustering_potential, :spray_V, :collision_energy, :protocol_name, :protocol_file)
      protocol_file = de.protocol_link ? wget_cmd(URLROOT + "/data/" + de.protocol_link.link) : nil
      protocol_name = de.protocol_link ? de.protocol_link.name : nil
      parsed_links[oe.lmid_link.name] = MasterEntry.new(de.lmid, oe.lmid_link.link, oe.name, oe.sysname, oe.cayman, oe.msms_link, oe.ion, de.ion_mode, de.instrument, de.ionization_type, de.declustering_potential, de.spray_V, de.collision_energy, protocol_name, protocol_file)
    end
    begin #page.forms.last.fields.map(&:name).include?("lipidclass")
      p page.forms.last.buttons
      break unless page.forms.last.buttons.size > 0
      page = page.forms.last.click_button
      resp = TableExtractor.extract_overview_table(page.body)
      details_resp = resp.map do |oe|
        oe.conditions_link ? TableExtractor.extract_details_table(agent.get(oe.conditions_link.link).body) : nil
      end
      [resp, details_resp].transpose.map do |oe, de|
        # MasterEntry = Struct.new(:lmid, :lmid_link, :name, :sysname, :cayman, :msms_link, :ion, :ion_mode, :instrument, :ionization_type, :declustering_potential, :spray_V, :collision_energy, :protocol_name, :protocol_file)
        protocol_file = de.protocol_link ? wget_cmd(URLROOT + "/data/" + de.protocol_link.link) : nil
        protocol_name = de.protocol_link ? de.protocol_link.name : nil
        parsed_links[oe.lmid_link.name] = MasterEntry.new(de.lmid, oe.lmid_link.link, oe.name, oe.sysname, oe.cayman, oe.msms_link, oe.ion, de.ion_mode, de.instrument, de.ionization_type, de.declustering_potential, de.spray_V, de.collision_energy, protocol_name, protocol_file)
      end
    end while page.forms.last.fields.map(&:name).include?("lipidclass")
  end
  parsed_links
end # run method


if $0 == __FILE__
  parsed_links = nil
  # Run the parsers on the whole website
  parsed_links = run
  
  # Testing
=begin
  agent = Mechanize.new
  TableExtractor.extract_overview_table(agent.get(URLROOT + "/data/standards/standards.php?lipidclass=LMFA").body)
  TableExtractor.extract_details_table(agent.get("http://www.lipidmaps.org/data/get_ms_params.php?LM_ID=LMFA01030381&ION=[M-H]-&TRACK_ID=393").body)
  p wget_cmd(URLROOT + "/data/" + "Eicos_MSMS_protocol.pdf")
=end

  #Write the output
  HEADERLINE = %w|lmid lmid_link name sysname cayman msms_link ion ion_mode instrument ionization_type declustering_potential spray_V collision_energy protocol_name protocol_file|
  if parsed_links
    unless parsed_links.empty?
      File.open("standards_set.tsv", "w") do |outputstream|
        outputstream.puts HEADERLINE.join("\t")
        output_links = parsed_links.values.map{|str| str.join(separator: "\t")}
        outputstream.puts output_links
      end
    end
  end
end

# ===================================================================
# ADIUM TOP WORDS v.02
# By Jason Ting (jzting@gmail.com)
# http://jzlabs.com
#
# Generates a static html file showing 
# your top 50 most used words
#
# Version History
# 0.2 - GUI interface, whoopdee-doo!
# 0.1 - Initial work with command line interface
# ===================================================================

require 'rexml/document'

# Get the log path
@@path = "/Users/#{File.expand_path("~").split("/")[2]}/Library/Application Support/Adium 2.0/Users/Default/Logs/"

# Create the Shoes app
Shoes.app(:title => "Adium Log Parser", :height => 640, :width => 480, :resizeable => false) do
  background "#548898".."#3d6976"
   
  stack :margin => 10 do
    para "Adium Top Words", :size => 26, :align => "center", :stroke => "#fff"
    para "Logs found in" + @@path, :stroke => "#a0b8be"  
    para "Select a log to parse:", :stroke => "#fff"
    
    # Show all accounts
    Dir.foreach(@@path) do |account|
      unless (account =~/\./ )==0
        button "#{account}" do
          parse_log(@@path+account)
        end
      end
    end
  end
  
  def parse_log(directory)

    # Set up the arrays
    directories = Array.new    
    files = Array.new
    counts = Array.new
    words = Array.new
        
    # Get all the valid chatlog directories (exclude hidden dot files)
    Dir.foreach(directory) { |dir| directories.push dir unless (dir =~/\./ )==0 }

    # Get all the files in the chatlog directories
    directories.each { |dir| Dir.entries(directory+"/"+dir.to_s).each {|entry| files.push directory+"/"+dir.to_s+"/"+entry if entry =~/\.chatlog/ } }
    
    # Get the chat username
    username = protocol = directory.split("/")[9]
    username = username.slice(username.index(".")+1,username.length)

    # Iterate over all the files
    files.each do |filename|

      # If the file turns out to be a directory, grab what's in the directory
      if File.directory?(filename) 

        # Only grab the xml file (cuz there's sometimes random files)
        Dir.entries(filename).each { |f| filename = filename + "/" + f if f =~ /\.xml/ }

      end

      # Setup the file for parsing
      file = File.new(filename)
      doc = REXML::Document.new(file)

      # Set the document root
      root = doc.root    
      
      # Parse out the text from each message  
      root.each_element do |r|
        message = r.elements["div"].elements[1].text if r.attributes['sender'] == username &&  r.name == "message" && r.elements["div"].elements[1]

        # Tokenize!
        message.to_s.split.each {|word| words.push word }
      end
    end

     # Count them up
     counts = words.inject(Hash.new(0)){|res, i| res[i]+=1; res}
     counts = counts.sort { |a,b| b[1]<=>a[1]}

     # Voila! Output the first fifty words
     counts = counts[2, 52]

     # Output to file
     filename_on_disk = File.expand_path("~") + "/Desktop/topwords_#{protocol}.html"
     header = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"><html xmlns="http://www.w3.org/1999/xhtml"><head><title>Adium Top Words</title><style>body { letter-spacing:-1px; font-family: helvetica, arial, san-serif; color: #555}</style></head>'
     footer = '</html>'

     # Setup sizing for cloud
     max_font = 144.0
     min_font = 12.0

     max = counts[0][1]
     min = counts[50][1]

     spread = max.to_f - min.to_f
     step = (max_font - min_font) / spread

     File.open(filename_on_disk, 'w') do |f|
       f.write(header)

       counts.each do |count| 
         count[1].to_i - min_font < 0 ? size = 0 : size = count[1].to_i - min_font
         f.write("<span style=\"font-size:#{(min_font + (size * step)).ceil}px\">#{count[0]} </span>")
       end
       
       f.write(footer)
     end

     # Output
    para "Done! Outputted results to #{filename_on_disk}", :stroke => "#FFF"
  end
end
$LOAD_PATH.unshift File.dirname(__FILE__) + "/vendor/rack-0.4.0/lib"
$LOAD_PATH.unshift File.dirname(__FILE__) + "/vendor/sinatra-0.3.3/lib"

require 'rubygems'
require 'sinatra'
require 'lib/configuration'
require 'lib/build_list'

ASSET_DIR = File.dirname(__FILE__) + "/public/"

helpers do
  def stylesheet(name)
    "<link href='#{versioned_asset(name + ".css")}' rel='stylesheet'/>"
  end

  def javascript(name)
    "<script type='text/javascript' src='#{versioned_asset(name + ".js")}'></script>"
  end

  def versioned_asset(filename)
    "#{filename}?#{File.mtime(ASSET_DIR + filename).to_i}"
  end

  def build_lists
    Dir[Configuration.build_data_dir + "/*"].map do |filename|
      BuildList.new filename
    end
  end

  def builds
    all_builds = []
    build_lists.each do |list|
      list.each {|b| all_builds << b}
    end
    all_builds.sort_by(&:status)
    failing, success = all_builds.partition{|b| b.status == "failure" }
    success_building, success_sleeping = success.partition {|b| b.activity == "building"  }
    (failing + success_building + success_sleeping)
  end

end

get "/" do
  @builds = builds
  erb :index
end

get "/XmlStatusReport.aspx" do
  document = REXML::Document.new
  document.add_element REXML::Element.new("Projects")

  build_lists.each {|l| l.insert_into document}

  output = ""
  REXML::Formatters::Pretty.new.write document, output
  output
end

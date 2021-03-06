class Starspan
  require 'csv'
  require 'json'

  STARSPAN = 'starspan'
  RASTER_PATH = 'raster/'
  INFO_PATH = 'info/'
  RESULTS_PATH= 'results/raster_'
  POLYGON_PATH = 'polygons/'
  STATS = "avg"
  PIXELS_PROCESSED = 2_300_000

  def initialize(options)
    @raster = options[:raster]
    @identifier = Time.now.getutc.to_i
    @polygon = JSON.parse(options[:polygon])
    @polygon_file = polygon_to_file(options[:polygon])
    @raster_path = choose_raster(@polygon["features"][0]["properties"]["AREA"])
  end

  def polygon_to_file polygon
    polygon_file = "#{POLYGON_PATH}#{@identifier}.geojson"
    File.open(polygon_file, 'w'){|f| f.write(polygon)}
    polygon_file
  end

  def choose_raster(area)
    raster_hash = JSON.parse(File.read(RASTER_PATH + INFO_PATH + @raster + '.json'))
    high_pixel_area = raster_hash["pixel_size"]*raster_hash["pixel_size"]
    medium_pixel_area=high_pixel_area*raster_hash["medium_res_value"]/100*raster_hash["medium_res_value"]/100
    if area/high_pixel_area < PIXELS_PROCESSED
      raster_hash["high_res_path"] + raster_hash["file_name"]
    elsif area/medium_pixel_area < PIXELS_PROCESSED
      raster_hash["medium_res_path"] + raster_hash["file_name"]
    else
      raster_hash["low_res_path"] + raster_hash["file_name"]
    end
  end

  def run_analysis
    if generate_stats
      results_to_hash
    else
      {:error => 'The application failed to run your analysis' }
    end
  end

  private

  def generate_stats
    call = "#{STARSPAN} --vector '#{@polygon_file}' --raster #{@raster_path} --stats #{STATS} --out-type table --out-prefix #{RESULTS_PATH} --summary-suffix #{@identifier}.csv"
    puts call
    system(call)
  end

  def results_to_hash
    if File.file?("#{RESULTS_PATH}#{@identifier}.csv")
      puts "File generated successfuly"
      csv_table = CSV.read("#{RESULTS_PATH}#{@identifier}.csv", {headers: true})
      list = []
      csv_table.each do |row|
        entry = {}
        csv_table.headers.each do |header|
          entry[header] = row[header]
        end
        list << entry
      end
      #result = JSON.pretty_generate(list)
      puts list
      list
    else
      {:error => 'The application failed to process the analysis stats.'}
    end
  end
end	

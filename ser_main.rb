# coding: utf-8
require 'sinatra'
require 'tilt/erb'
require_relative 'core/subspace_skyline_path'

nodes_path = 'salu-data/salu_node_830.txt'
edges_path = 'salu-data/salu_edge_830.txt'
label_path = 'salu-data/salu_label.txt'

EDGE_DATA = File.read(edges_path)
NODE_DATA = File.read(nodes_path)

labels = []
File.open(label_path, "r:UTF-8") do |f|
   f.each_line { |line| labels << line }
end

MAX_LABEL = [4, 6, 10 ,12, 16, 18]

get '/' do
  @title = '沙鹿地區淹水逃生路線模擬'
  @label = labels
  erb :index
end

post '/SkylinePathResult' do
  @title = "模擬結果"
  # Get Params
  src   = params[:source]
  dst   = params[:destination]
  limit = params[:limit]

  dim_times_array = get_dims(params)

  # Set Files' Name
  @filename     = "full_#{src}to#{dst}_#{limit.to_f}_limit_result.txt"
  @filename_5   = "top_5_#{src}to#{dst}_#{limit.to_f}_limit_result.txt"
  @filename_sum = "sum_best_#{src}to#{dst}_#{limit.to_f}_limit_result.txt"

  # Query
  puts "A new query from #{src} to #{dst} with #{limit} times is processing."
  @result = skyline_path_in_salu(dim_times_array, src.to_i, dst.to_i, limit.to_f)
  puts "Query from #{src} to #{dst} with #{limit} is done."
  erb :result
end

def get_dims(params)
  dim_times_array = []
  0.upto(18) do |dim|
    sym = "dim_#{dim}_input".to_sym
    dim_times_array << params[sym].to_f
  end
  dim_times_array
end

def skyline_path_in_salu(dim_times_array, source, destination, constrained_times)
  ssp = SubspaceSkylinePath.new(raw_nodes: NODE_DATA, raw_edges: EDGE_DATA, dim_times_array: dim_times_array)

  subspace = []
  dim_times_array.each_with_index {|d, i| subspace << i unless d == 0 }
  raise "No attributes selected! Please try again." if subspace.empty?

  puts "Subspace setting: #{subspace}"

  ssp.set_subspace_attrs(subspace)
  ssp = set_max_attr(subspace, ssp)

  result = ssp.query_skyline_path(src_id: source, dst_id: destination, limit: constrained_times, evaluate: true)
  ssp.output_to_txt(source, destination)

  result
end

def set_max_attr(subspace, ssp)

  max = []

  MAX_LABEL.each { |i| max << subspace.index(i) if subspace.include?(i) }

  puts "max Subspace setting: #{max}"
  ssp.set_max_attrs(max) unless max.empty?
  ssp
end

get '/download/:filename' do |filename|
  send_file "./output/#{filename}", filename: filename, type: 'Application/octet-stream'
end

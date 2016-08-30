# coding: utf-8
require 'sinatra'
require 'tilt/erb'
require_relative 'core/subspace_skyline_path'

nodes_path = 'salu-data/salu_node_160203.txt'
edges_path = 'salu-data/salu_edge_160203_450_z.txt'
label_path = 'salu-data/salu_label.txt'

EDGE_DATA = File.read(edges_path)
NODE_DATA = File.read(nodes_path)

labels = []
File.open(label_path, "r:UTF-8") do |f|
   f.each_line { |line| labels << line }
end

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
  # TODO more dims processing
  puts get_dims(params)

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
  1.upto(13) do |dim|
    sym = "dim_#{dim}".to_sym
    dim_times_array << params[sym].to_f
  end
  dim_times_array
end

def skyline_path_in_salu(dim_times_array, source, destination, constrained_times)
  ssp = SubspaceSkylinePath.new(raw_nodes: NODE_DATA, raw_edges: EDGE_DATA, dim_times_array: dim_times_array)

  subspace = []
  dim_times_array.each_with_index {|d, i| subspace << i unless d == 0 }

  ssp.set_subspace_attrs(subspace)
  ssp = set_max_attr(subspace, ssp)

  result = ssp.query_skyline_path(src_id: source, dst_id: destination, limit: constrained_times, evaluate: true)
  ssp.output_to_txt(source, destination)

  result
end

def set_max_attr(subspace, ssp)
  max = []
  max << subspace.index(4)  if subspace.include?(4)  # 易損機率(max)
  max << subspace.index(6)  if subspace.include?(6)  # 淹水深度(max)
  max << subspace.index(10) if subspace.include?(10) # Z易損機率(max)
  max << subspace.index(12) if subspace.include?(12) # Z淹水深度(max)
  ssp.set_max_attrs(max) unless max.empty?
  ssp
end

get '/download/:filename' do |filename|
  send_file "./output/#{filename}", filename: filename, type: 'Application/octet-stream'
end

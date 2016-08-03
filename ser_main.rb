# coding: utf-8
require 'sinatra'
require 'tilt/erb'
require_relative 'core/subspace_skyline_path'

nodes_path = 'salu-data/salu_node_160203.txt'
edges_path = 'salu-data/salu_edge_160203_450_z.txt'

EDGE_DATA = File.read(edges_path)
NODE_DATA = File.read(nodes_path)

get '/' do
  @title = '沙鹿地區淹水逃生路線模擬'

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
  1.upto(13) do |dim|
    sym = "dim_#{dim}".to_sym
    dim_times_array << params[sym].to_f
  end
  dim_times_array
end

def skyline_path_in_salu(dim_times_array, source, destination, constrained_times)
  ssp = SubspaceSkylinePath.new(raw_nodes: NODE_DATA, raw_edges: EDGE_DATA, dim_times_array: dim_times_array)

  subpace = []
  dim_times_array.each_with_index {|d, i| subpace << i unless d == 0 }

  ssp.set_subspace_attrs(subpace)

  result = ssp.query_skyline_path(src_id: source, dst_id: destination, limit: constrained_times)
  ssp.output_to_txt(source, destination)

  result
end

get '/download/:filename' do |filename|
  send_file "./output/#{filename}", filename: filename, type: 'Application/octet-stream'
end

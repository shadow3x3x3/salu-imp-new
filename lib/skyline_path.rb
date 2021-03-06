require 'benchmark'
include Benchmark

require_relative '../ext/array'
require_relative '../structure/graph'

require_relative 'dijkstra'

# for query skyline path
class SkylinePath < Graph
  include Dijkstra

  def initialize(params = {})
    super
    @skyline_path      = {}
    @part_skyline_path = {}
  end

  def query_skyline_path(src_id: nil, dst_id: nil, limit: 10, evaluate: false)
    query_check(src_id, dst_id)
    if evaluate
      Benchmark.benchmark(CAPTION, 22, FORMAT, 'total:') do |step|
        t1 = step.report('Shorest path') do
          shorest_path = shorest_path_query(src_id, dst_id)
          raise "Can't find any road between #{src_id} and #{dst_id}" if shorest_path.nil?
          @skyline_path[path_to_sym(shorest_path)] = attrs_in(shorest_path)
          @shorest_distance = @skyline_path[path_to_sym(shorest_path)].first
          @limit_times = limit
          @limit = @shorest_distance * limit
        end
        t2 = step.report('SkyPath') do
          sky_path(src_id, dst_id)
        end
        [t1 + t2]
      end
    else
      shorest_path = shorest_path_query(src_id, dst_id)
      raise "Can't find any road between #{src_id} and #{dst_id}" if shorest_path.nil?
      @skyline_path[path_to_sym(shorest_path)] = attrs_in(shorest_path)
      @shorest_distance = @skyline_path[path_to_sym(shorest_path)].first
      @limit = @shorest_distance * limit
      sky_path(src_id, dst_id)
    end

    # puts "Found #{@skyline_path.size} Skyline paths"
    @skyline_path
  end

  def find_paths(src, dst)
    path_recursive(src, dst, {}, [])
  end

  def path_recursive(cur, dst, paths, path)
    path << cur
    if cur == dst
      path = get_dst(cur, paths, path)
      return
    end
    find_neighbors_at(cur).each do |n|
      path_recursive(n, dst, paths, path) unless path.include?(n)
    end
    path.delete(cur)
    paths
  end

  def get_dst(cur, paths, path)
    paths[path_to_sym(path)] = attrs_in(path)
    path.delete(cur)
  end

  protected

  def attrs_in(path)
    if path.size > 2
      edges_of_path = partition(path)
      attr_full = edges_of_path.inject(Array.new(@dim, 0)) do |attrs, edges|
        attrs.aggregate(attr_between(edges[0], edges[1]))
      end
    else
      attr_full = attr_between(path.first, path.last)
    end
    attr_full
  end

  def attr_between(src, dst)
    @edges_hash[[src, dst]].attrs
  end

  def sky_path(cur, dst, pass = [], cur_attrs = Array.new(@dim, 0))
    pass << cur
    if cur == dst
      pass = arrived(cur, pass, cur_attrs) unless full_dominance?(cur_attrs)
      return
    end
    find_neighbors_at(cur).each do |n|
      next_path_attrs = cur_attrs.aggregate(attr_between(cur, n))
      sky_path(n, dst, pass, next_path_attrs) if next_hop?(n, pass, next_path_attrs)
    end
    pass.delete(cur)
  end

  def arrived(cur, pass, attrs)
    new_skyline_check(pass, attrs)
    pass.delete(cur)
  end

  def new_skyline_check(pass, attrs)
    non_skyline = []
    new_skyline_flag = true

    @skyline_path.each do |key, s_attrs|
      flag = s_attrs.dominate?(attrs)
      new_skyline_flag = false if flag
      non_skyline << key if flag == false
    end

    non_skyline.each { |key| @skyline_path.delete(key) }
    @skyline_path[path_to_sym(pass)] = attrs if new_skyline_flag
  end

  private

  def next_hop?(n, pass, next_path_attrs)
    unless @distance_limit.nil?
      return false if out_of_limit?(next_path_attrs.first)
    end
    return false if pass.include?(n)
    partial_result = partial_dominance?(n, next_path_attrs)
    return false if partial_result
    add_part_skyline(n, next_path_attrs)
    return false if full_dominance?(next_path_attrs)
    true
  end

  def out_of_limit?(distance)
    distance > @LIMIT ? true : false
  end

  def partial_dominance?(target, path_attrs)
    unless @part_skyline_path[target].nil?
      result = @part_skyline_path[target].dominate?(path_attrs)
    end
    result
  end

  def full_dominance?(path_attrs)
    @skyline_path.each do |_path, attrs|
      return true if attrs.dominate?(path_attrs)
    end
    false # not be dominance
  end

  def add_part_skyline(target, path_attrs)
    return unless @part_skyline_path[target].nil?
    @part_skyline_path[target] = path_attrs
  end

  def query_check(src_id, dst_id)
    if src_id.nil? || dst_id.nil?
      raise ArgumentError, 'have to set src and dst both'
    end
    raise ArgumentError, 'src and dst have to different' if src_id == dst_id
    unless @nodes.include?(src_id)
      raise ArgumentError, 'src id needs to exist Node'
    end
    unless @nodes.include?(dst_id)
      raise ArgumentError, 'dst id needs to exist Node'
    end
  end

  def path_to_sym(path)
    raise ArgumentError, 'path must be Array' unless path.class == Array
    "p#{path.join('_')}".to_sym
  end
end

# Reading raw file module
module ReadUtil
  def initialize_edges(raw_edges, dim_times_array)
    raw_edges.each_line do |edge|
      edge = edge.split.map!(&:to_f)
      add_edge(edge, dim_times_array)
    end
  end

  def initialize_nodes(raw_nodes)
    raw_nodes.each_line do |node|
      node = node.split.map!(&:to_f)
      add_node(node.first.to_i)
    end
  end
end

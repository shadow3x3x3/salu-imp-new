module OutputUtil
  def output_to_txt(src, dst)

  end

  def path_to_id(path)
    path_id = []

    path.each_with_index do |v, i|
      next if i == path.size - 1
      next_v = path[i + 1]
      @edges.each do |edge|
        path_id << edge.id if edge.src == v && edge.dst == next_v
        path_id << edge.id if edge.src == next_v && edge.dst == v
      end
    end
    path_id
  end
end

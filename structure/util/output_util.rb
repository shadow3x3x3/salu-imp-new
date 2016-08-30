module OutputUtil
  def output_to_txt(src, dst)
    filter_skyline_path = if @skyline_path.size > 5
                              split_path_ids(filter_skyline(@skyline_path))
                            else
                              split_path_ids(@skyline_path)
                            end

    write(src, dst, filter_skyline_path, 'full')
    sum_best_skyline_path = sum_best_path(filter_skyline_path)

    write(src, dst, filter_skyline_path,   'top_5')
    write(src, dst, sum_best_skyline_path, 'sum_best')
  end

  def write(src, dst, content, type)
    File.open("./output/#{type}_#{src}to#{dst}_#{@distance_limit}_limit_result.txt", "w") do |f|
      if type == 'sum_best'
        sp_id_array = path_to_id(content)

        sp_id_array.each_with_index do |id, index|
          f.write("\"id\" = #{id}")
          index == sp_id_array.size - 1 ? f.write("\n") : f.write(' OR ')
        end
      else
        content.each do |sp|
          sp_id_array = path_to_id(sp)

          sp_id_array.each_with_index do |id, index|
            f.write("\"id\" = #{id}")
            index == sp_id_array.size - 1 ? f.write("\n") : f.write(' OR ')
          end
        end
      end
    end
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

  def filter_skyline(skyline_path)
    sort_result = sort_by_dim(skyline_path)

    skyline_path_set = get_skyline_path_ids(sort_result)
    reslut = filter_array_top_k(skyline_path_set, 5) # Top 5 skyline paths
    reslut
  end

  def sort_by_dim(ori_hash)
    result_array = []
    index = 0
    dim   = @dim
    dim.times do
      result_array << ori_hash.sort_by { |_key, value| value[index] }
      index += 1
    end
    result_array
  end

  def get_skyline_path_ids(skyline_array)
    skyline_path_set = []
    skyline_array.each do |skyline_set|
      temp_set = []
      skyline_set.each do |skyline|
        temp_set << skyline[0].to_s
      end
      skyline_path_set << temp_set
    end
    skyline_path_set
  end

  def filter_array_top_k(target_array, top_k)
    result_array = []
    search_range = 0
    find_k       = 0
    until (find_k >= top_k) # || (search_range == @skyline_path.size)
      search_range += 1
      result_array = target_array.inject { |top_k, next_array| top_k & next_array[0..search_range] }
      find_k = result_array.size
    end
    result_array
  end

  def split_path_ids(target_paths)
    skyline_paths = target_paths.map {|path_ids, _path_values| path_ids.to_s.split("_")}
    skyline_paths.map! do |skyline_path|
      skyline_path.shift # shift the "path"
      skyline_path.map(&:to_i)
    end
  end

  def sum_best_path(paths)
    result_path = []
    paths.each do |path|
      result_path << attrs_in(path).inject(&:+)
    end

    paths[result_path.index(result_path.min)]
  end

end

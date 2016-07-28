require_relative 'spec_helper'
require_relative '../structure/graph'

EDGE_PATH = './salu-data/salu_edge_160203_450mm_z.txt'
NODE_PATH = './salu-data/salu_node_160203.txt'

test_edges = File.read(EDGE_PATH)
test_nodes = File.read(NODE_PATH)

describe Graph do
  let(:g) { Graph.new(raw_edges: test_edges, raw_nodes: test_nodes) }

  describe '#path_to_id' do
    context '([1, 5, 6, 11])' do
      it 'should be get[4, 3, 30]' do
        expect(g.path_to_id([1, 5, 6, 11])).to eq([4, 3, 30])
      end
    end
  end
end
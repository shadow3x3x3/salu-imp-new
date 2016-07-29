require_relative 'spec_helper'
require_relative '../structure/graph'

test_edges = File.read('./salu-data/salu_edge_160203_450mm_z.txt')
test_nodes = File.read('./salu-data/salu_node_160203.txt')

TEST_SKYLINE_ATTR_HASH = {
  a: [2, 6, 7, 8],
  b: [1, 9, 3, 5],
  c: [3, 4, 8, 7],
  d: [8, 3, 2, 1],
  e: [4, 2, 9, 3]
}

describe Graph do
  let(:g) { Graph.new(raw_edges: test_edges, raw_nodes: test_nodes) }

  describe '#path_to_id' do
    context '([1, 5, 6, 11])' do
      it 'should be get[4, 3, 30]' do
        expect(g.path_to_id([1, 5, 6, 11])).to eq([4, 3, 30])
      end
    end
  end

  describe '#sort_by_dim' do
    context '(TEST_SKYLINE_ATTR_HASH)' do
      it "result must be sorted" do
        result = g.sort_by_dim(TEST_SKYLINE_ATTR_HASH)
        expect(result[0]).to eq([
          [:b, [1, 9, 3, 5]],
          [:a, [2, 6, 7, 8]],
          [:c, [3, 4, 8, 7]],
          [:e, [4, 2, 9, 3]],
          [:d, [8, 3, 2, 1]],
          ])
          # b a c d e
        expect(result[1]).to eq([
          [:e, [4, 2, 9, 3]],
          [:d, [8, 3, 2, 1]],
          [:c, [3, 4, 8, 7]],
          [:a, [2, 6, 7, 8]],
          [:b, [1, 9, 3, 5]],
          ])
          # e d c a b
        expect(result[2]).to eq([
          [:d, [8, 3, 2, 1]],
          [:b, [1, 9, 3, 5]],
          [:a, [2, 6, 7, 8]],
          [:c, [3, 4, 8, 7]],
          [:e, [4, 2, 9, 3]],
          ])
          # d b a c e
        expect(result[3]).to eq([
          [:d, [8, 3, 2, 1]],
          [:e, [4, 2, 9, 3]],
          [:b, [1, 9, 3, 5]],
          [:c, [3, 4, 8, 7]],
          [:a, [2, 6, 7, 8]],
          ])
          # d e b c  a
      end
    end
  end
end

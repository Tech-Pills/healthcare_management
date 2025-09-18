class ShardRecord < ApplicationRecord
  self.abstract_class = true

  connects_to shards: {
    shard_one: { writing: :primary_shard_one, reading: :primary_shard_one },
    shard_two: { writing: :primary_shard_two, reading: :primary_shard_two }
  }
end

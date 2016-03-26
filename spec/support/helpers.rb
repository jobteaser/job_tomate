# A set of general-use helpers
module Helpers

  def expect_hash_match(hash, expected_hash)
    expected_hash.each do |key, value|
      expect(hash[key]).to eq(value)
    end
  end
end

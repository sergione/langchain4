require "securerandom"

module IdHelpers
  def self.generate_unique_id
    SecureRandom.uuid
  end
end

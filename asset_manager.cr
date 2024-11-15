require "digest"
require "file_utils"

require "./asset_manager/*"

module AssetManager
  Log = ::Log.for self

  def self.prehash_assets
    Log.info { "Prehashing assets" }

    ImportMap.each_import do |import|
      next unless import.local?
      Log.info { Config.output_path / import.hash_entry.digest_path }
    end
  end
end

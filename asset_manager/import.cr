module AssetManager
  struct Import
    def self.from_glob(prefix : Path, glob : Path) : Array(Import)
      Dir.glob(Config.source_path / glob).map do |path|
        relative_path = Path[path].relative_to(Config.source_path)
        alias_name = relative_path.parent.relative_to(prefix) / relative_path.stem
        Import.new alias_name, relative_path, preload: true, local: true
      end
    end

    getter name : Path | String
    getter path : Path | String
    getter preload : Bool
    getter? local : Bool

    def initialize(@name, @path, @preload = true, @local = false)
    end

    def hash_entry : FileHasher::HashEntry
      FileHasher.hashed_path_for(@path)
    end

    def public_asset_path
      if local?
        Config.rendered_path / hash_entry.digest_path
      else
        @path
      end
    end
  end
end

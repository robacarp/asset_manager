# File hasher maintains a list of files, their mtimes, and their hashes.
#
# In a runtime-computed environment, the file hashes will be computed on the fly and files are served directly
# without being copied to the output directory.
#
# In a precomputed environment, the file hashes will be computed once and files with the hash embedded will be
# emitted to the output directory.
#
# Assumes that source_path, output_path, and rendered_path are all going to be
# mirrored structurally.
#
# For example, given these initial paths:
#   source_path: "src"
#   output_path: "public/assets"
#   rendered_path: "assets"
#
# Calling #hash_and_copy_file("javascript/application.js") will:
#   calculate a hash of src/javascript/application.js
#   copy the file to: public/assets/javascript/application-<hash>.js
#   return the rendered path: assets/javascript/application-<hash>.js
class AssetManager::FileHasher
  record HashEntry, mtime : Time, digest_path : Path

  def self.instance : self
    @@instance ||= new
  end

  def self.hashed_path_for(path : String | Path) : HashEntry
    instance.hashed_path_for path
  end

  getter? warn_on_hash : Bool = false

  def initialize
    @file_hashes = {} of Path => HashEntry
  end

  def warn_on_hash!
    @warn_on_hash = true
  end

  # Computes a hashed path for a source path. If the file has already been hashed, it won't be recomputed unless the
  # mtime shows that the file has changed.  Paths are relative to the asset_root.
  def hashed_path_for(path : Path) : HashEntry
    return @file_hashes[path] unless file_has_changed? path

    if warn_on_hash?
      Log.warn { "Runtime computing hash for #{path}" }
    end

    source_path = Config.source_path / path
    digest = Digest::SHA256.new.file(source_path).hexfinal
    digest_path = path.parent / (path.stem + "-#{digest}" + path.extension)

    copy_file_to_output source_path, digest_path

    @file_hashes[path] = HashEntry.new(
      mtime: File.info(source_path).modification_time,
      digest_path: digest_path
    )
  end

  def copy_file_to_output(source_path : Path, digest_path : Path) : Nil
    destination_file_path = Config.output_path / digest_path
    destination_folder = destination_file_path.parent

    previous_renderings = Dir.glob(destination_folder / "#{digest_path.stem}-*#{digest_path.extension}")
    previous_renderings.each do |previous_rendering|
      File.delete? previous_rendering
    end

    FileUtils.mkdir_p destination_folder
    FileUtils.cp source_path, destination_file_path
  end

  # :ditto:
  def hashed_path_for(path : String) : HashEntry
    hashed_path_for Path[path]
  end

  def file_has_changed?(path : Path) : Bool
    return true unless @file_hashes.has_key? path
    current_mtime = File.info(Config.source_path / path).modification_time
    @file_hashes[path].mtime != current_mtime
  end
end

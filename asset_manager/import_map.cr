class AssetManager::ImportMap
  def self.instance : self
    @@instance ||= new
  end

  def self.build : Nil
    with instance yield
  end

  def self.render_script_tags : String
    instance.render_script_tags
  end

  def self.each_import(&block : Import ->)
    instance.each_import &block
  end

  getter imports = [] of Import
  getter glob_paths = [] of Path
  getter source_path : Path
  getter relative_path : Path
  getter? compiled : Bool = false
  getter! compiled_importmap : String?

  def initialize
    @source_path = Config.source_path
    @relative_path = Path["."]
  end

  def javascript_path_prefix(path : String) : Nil
    @source_path = Config.source_path / Path[path]
    @relative_path = Path[path]
  end

  # Adds a remote file to the import map.  Useful for packages from jsdeliver.net, unpkg, etc.
  #
  # Eg.
  # ```crystal
  # ImportMap.config do
  #   import_remote("stimulus", path: "https://cdn.jsdelivr.net/npm/stimulus@3.2.2/+esm", preload: true)
  # end
  # ```
  #
  def remote(name : String, path : String, preload : Bool = false)
    @imports << Import.new name, path, preload
  end

  # Adds a static local file to the import map.
  #
  # Eg:
  #
  # ```crystal
  # ImportMap.config do
  #   import_local "application", "assets/application.js"
  # end
  # ```
  #
  # Directories with an index.js file can be imported with the name of the directory:
  #
  # ```crystal
  # ImportMap.config do
  #   # assuming src/assets/controllers/index.js exists
  #   import_local "controllers", "assets/controllers"
  # ```
  def local(name : String, path : String, preload : Bool = false)
    local name, Path.new(path), preload
  end

  # :ditto:
  def local(name : String, path : Path, preload : Bool = false)
    asset_path = source_path / path

    if File.directory? asset_path
      import_index name, path, preload
    elsif File.file? asset_path
      import_file name, path, preload
    else
      raise "Asset not found: #{asset_path}"
    end
  end

  private def import_index(name : String, path : Path, preload : Bool)
    candidate_index_file = source_path / path / "index.js"
    if File.file? candidate_index_file
      import_file(name, path / "index.js", preload)
    else
      raise "Index file not found in directory import: #{candidate_index_file}"
    end
  end

  private def import_file(name : String, path : Path, preload : Bool)
    @imports << Import.new name, relative_path / path, preload, local: true
  end


  # Adds a dynamic file glob to the import map.
  # Each time the import map is rendered, the files matching the pattern
  # will be added to the map. Files are hashed and the stem is used as the
  # import name.
  #
  # Eg:
  #
  # ```crystal
  # ImportMap.config do
  #   javascript_path "src/javascript"
  #   import_glob("controllers/**/*.js")
  # end
  # ```
  def glob(glob : String) : Nil
    @glob_paths << relative_path / glob
  end

  # Executes a block for each import in the map, both static imports
  # and imports from globs.
  def each_import(&block : Import ->)
    imports.each &block

    glob_paths
      .flat_map{|glob| Import.from_glob relative_path, glob }
      .each(&block)
  end

  # Renders the import map as a JSON string.
  def to_importmap_json : String
    return compiled_importmap if compiled?
    JSON.build do |json|
      json.object do
        json.field "imports" do
          json.object do
            each_import do |import|
              json.field import.name, import.public_asset_path
            end
          end
        end
      end
    end
  end

  def compile_importmap
    @compiled_importmap = to_importmap_json
    @compiled = true
  end
end

module AssetManager
  Config = Configuration.new

  def self.configure
    yield Config
  end

  struct Configuration
    property source_path : Path
    property output_path : Path
    property rendered_path : Path

    def initialize
      @source_path = Path.new("./src")
      @output_path = Path.new("public/h/")
      @rendered_path = Path.new("/h/")
    end
  end
end

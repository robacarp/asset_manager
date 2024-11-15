module AssetManager
  module HTMLHelpers
    def render_javascript_import_map(map : ImportMap = ImportMap.instance) : String
      tags = [] of String

      # render the import map script tag
      tags << String.build do |s|
        s << %|<script type="importmap">|
        s << map.to_importmap_json
        s << %|</script>|
      end

      # render the preload tags
      map.imports.select { |import| true || import.preload }.each do |import|
        tags << %|<link rel="modulepreload" href="#{import.public_asset_path}">|
      end

      tags.join("\n")
    end

    def script_tag_for(path : String, module is_module : Bool = true) : String
      String.build do |s|
        s << "<script "
        s << %|type="module" | if is_module
          s << %|src="#{public_path_for(path)}">|
        s << "</script>"
      end
    end

    def stylesheet_tag_for(path : String) : String
      %|<link href="#{public_path_for(path)}" rel="stylesheet">|
    end

    private def public_path_for(path : String) : Path
      Config.rendered_path / FileHasher.hashed_path_for(path).digest_path
    end
  end
end

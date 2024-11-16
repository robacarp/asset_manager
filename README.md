# asset_manager

Asset Manager is a Crystal shard that helps you manage and deliver front-end assets in a Crystal web application.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
 asset_manager:
   github: robacarp/asset_manager
```

2. Run `shards install`

## Getting started

Asset manager needs to be configured before it can be used. Here is an example configuration:

```crystal
require "asset_manager"

AssetManager.configure do |c|
  # The path to the directory containing your source files
  c.source_path = Path.new("src/")

  # The path to the directory where you want the hashed files to be written
  c.output_path = Path.new("public/assets/")

  # The path prefix which is rendered by html helpers
  c.rendered_path = Path.new("/assets")
end
```

Once you have configured asset manager, you can use the `AssetManager::HTMLHelpers` module in your views to render links to assets:

```erb
<%= stylesheet_tag_for "stylesheets/app.css" %>
<%= script_tag_for "javascript/analytics.js", module: true %>
<%= script_tag_for "javascript/index.js", module: true %>
```

Each of these will render a link to the hashed file, which will be created in the output path, with a name like: `stylesheets/builds/tailwind-averyveryveryveryveryveryVERYlonghashstring.css`.

## Rendering an import map

An [Import Map](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script/type/importmap) is a way of tersely specifying the dependencies in a javascript project without using URLs in the JS `import` statement. This technology is [widely available in modern browsers](https://caniuse.com/import-maps) and makes it substantially easier to manage a javascript-heavy web application.

To build an import map, AssetManager provides an ImportMap class:

```crystal
# local paths are relative to Config.source_path
AssetManager::ImportMap.build do
  # Subfolder of source_path where javascript files are located.
  javascript_path_prefix "javascript"

  # Add remote dependencies to the map. These can be imported into javascript now like this: `import posthog from "posthog-js"`
  remote "posthog-js", path: "https://cdn.jsdelivr.net/npm/posthog-js@1.126.0/+esm"
  remote "stimulus", path: "https://cdn.jsdelivr.net/npm/stimulus@3.2.2/+esm"

  # Add local depencies to the map:
  # Don't put the javascript path prefix in the path, it's assumed.
  local "application", path: "application.js"

  # import checkout from "checkout.js"
  # preload: false means the browser will wait for an `import` statement to load this file.
  local "checkout", path: "checkout.js", preload: false

  # Add an entire tree of files to the map.
  # For a file at:
  #  - src/javascript/controllers/checkout.js
  # It will be checksummed and copied to the output path:
  #  - public/assets/controllers/checkout-11234abcdefghi.js
  # this will add an entry so that it can be imported like this:
  #  - import checkout from "controllers/checkout"
  glob "controllers/**/*.js"
end
```

Then you can render the import map in your layout:

```erb
<%= render_javascript_import_map %>
```

This will render:

- `<script type="importmap">` tag with the import map JSON
- a `<link rel="modulepreload" href="...">` tag for each mapped file with `preload: true`

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

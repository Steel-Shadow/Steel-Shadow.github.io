# [Full User Manual](_doc/Manual.md)

# [另见中文文档](_doc/README.zh.md)

模板来自 [huxpro.github.io](https://github.com/Huxpro/huxpro.github.io)

本地运行网页 (默认 `localhost:4000` ):

```sh
bundle exec jekyll serve #包管理器运行
jekyll serve #直接本地运行
```

## Development (Build From Source)

modify the theme, you will need [Grunt](https://gruntjs.com/). There are numbers of tasks you can find in the `Gruntfile.js`, includes minifing JavaScript, compiling `.less` to `.css`, adding banners to keep the Apache 2.0 license intact, watching for changes, etc. 

Yes, they were inherited and are extremely old-fashioned. There is no modularization and transpilation, etc.

Critical Jekyll-related code are located in `_include/` and `_layouts/`. Most of them are [Liquid](https://github.com/Shopify/liquid/wiki) templates.

This theme uses the default code syntax highlighter of jekyll, [Rouge](http://rouge.jneen.net/), which is compatible with Pygments theme so just pick any pygments theme css (e.g. from [here](http://jwarby.github.io/jekyll-pygments-themes/languages/javascript.html) and replace the content of `highlight.less`.

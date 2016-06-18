hunt
=======

A high performance web framework based on [collie](https://github.com/putao-dev/collie/) using [dlang](http://dlang.org/) development.

## Suggest

- view files save [./resources/views], custom view directory config in dub.json "stringImportPaths":  [ "./resources/views"]
- format code command: dfmt --inplace --tab_width=4 --brace_style=allman *.d

## Router

config/routes.conf
```conf
#
# [GET,POST,PUT...]    path    controller.method
#
#{domain}
#[path]

GET / front/module.controller.action
GET / admin/module.controller.action
GET / api/module.controller.action
```

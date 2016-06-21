hunt
=======
Hunt is a high-level [dlang](http://dlang.org/) Web framework that encourages rapid development and clean, pragmatic design. It lets you build high-performance Web applications quickly and easily.

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

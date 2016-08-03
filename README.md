Hunt framework
=======
Hunt is a high-level [dlang](http://dlang.org/) Web framework that encourages rapid development and clean, pragmatic design. It lets you build high-performance Web applications quickly and easily.

## Create project
```bash
git clone https://github.com/putaolabs/hunt-skeleton.git myproject
cd myproject
dub run
```
Open the URL with the browser:
```html
http://localhost:8080/
```

## Router config
config/routes.conf
```conf
#
# [GET,POST,PUT...]    path    controller.action
#

GET / index.index
```

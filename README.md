[![Build Status](https://travis-ci.org/huntlabs/hunt-framework.svg?branch=master)](https://travis-ci.org/huntlabs/hunt-framework)

## Hunt framework
[Hunt](http://www.huntframework.com/) is a high-level [D Programming Language](http://dlang.org/) Web framework that encourages rapid development and clean, pragmatic design. It lets you build high-performance Web applications quickly and easily.
![Framework](framework.png)


## Getting Started
- [Installation](https://github.com/huntlabs/hunt-framework-docs/blob/master/installation.md)
- [Server Configuration](https://github.com/huntlabs/hunt-framework-docs/blob/master/configuration.md)

### Create a project
```bash
git clone https://github.com/huntlabs/hunt-skeleton.git myproject
cd myproject
dub run -v
```

Open the URL with the browser:
```bash
http://localhost:8080/
```

### Router config
config/routes
```conf
#
# [GET,POST,PUT...]    path    controller.action
#

GET     /               index.index
GET     /users          user.list
POST    /user/login     user.login
*       /images         staticDir:public/images

```

### Add Controller
```D
module app.controller.index;

import hunt.framework;

class IndexController : Controller
{
    mixin MakeController;

    @Action
    string index()
    {
        return "Hello world!";
    }
}
```

For more, see [hunt-skeleton](https://github.com/huntlabs/hunt-skeleton) or [hunt-examples](https://github.com/huntlabs/hunt-examples).

## Components

### Basics
- [Routing](https://github.com/huntlabs/hunt-framework-docs/blob/master/routing.md)
- [Middleware](https://github.com/huntlabs/hunt-framework-docs/blob/master/middleware.md)
- [Controller](https://github.com/huntlabs/hunt-framework-docs/blob/master/controllers.md)
- [Request](https://github.com/huntlabs/hunt-framework-docs/blob/master/requests.md)
- [Response](https://github.com/huntlabs/hunt-framework-docs/blob/master/responses.md)
- [Session](https://github.com/huntlabs/hunt-framework-docs/blob/master/session.md)
- [Validation](https://github.com/huntlabs/hunt-framework-docs/blob/master/validation.md)
- [Logging](https://github.com/huntlabs/hunt-framework-docs/blob/master/logging.md)

### Security
- [Authorization](https://github.com/huntlabs/hunt-framework-docs/blob/master/authorization.md)

### Database
- [Database ORM](https://github.com/huntlabs/hunt-framework-docs/blob/master/entity.md)
- [Redis](https://github.com/huntlabs/hunt-framework-docs/blob/master/redis.md)
- [Pagination](https://github.com/huntlabs/hunt-framework-docs/blob/master/pagination.md)

### Frontend
- [View Templates](https://github.com/huntlabs/hunt-framework-docs/blob/master/views.md)
- [Localization](https://github.com/huntlabs/hunt-framework-docs/blob/master/localization.md)

### Digging Deeper
- [HTTP Client](https://github.com/huntlabs/hunt-framework-docs/blob/master/http-client.md)
- [Cache](https://github.com/huntlabs/hunt-framework-docs/blob/master/cache.md)
- [Message Queue](https://github.com/huntlabs/hunt-framework-docs/blob/master/queues.md)
- [Scheduling](https://github.com/huntlabs/hunt-framework-docs/blob/master/scheduling.md)


## Resources
- [Documentation](https://github.com/huntlabs/hunt-framework-docs)
- [Articles](https://github.com/huntlabs/hunt-framework-articles)

## Community
- [Issues](https://github.com/huntlabs/hunt-framework/issues)
- QQ Group: 184183224 
- [D语言中文社区](https://forums.dlangchina.com/)


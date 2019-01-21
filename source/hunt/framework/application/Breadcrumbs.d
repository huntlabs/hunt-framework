module hunt.framework.application.Breadcrumbs;

import hunt.framework.application.BreadcrumbsManager;
import hunt.framework.application.BreadcrumbItem;

alias Handler(T) = void delegate(Breadcrumbs crumb, T[]...);

class Breadcrumbs
{
    Breadcrumbs parent;
    BreadcrumbItem[] items;

    void parent(T)(string name, ...params)
    {
        //
    }

    void push(string name, string link)
    {
        BreadcrumbItem item = new BreadcrumbItem;
        item.name = name;
        item.link = link;

        items.push(item);
    }

    static void register(T)(string name, Handler!T handle)
    {
        breadcrumbsManager().register!T(name, handle);
    }
    
    // return BreadcrumbItem array
    static BreadcrumbItem[] generate(string name, ...params)
    {
        return breadcrumbsManager().generate(name, params);
    }

    // return Breadcrumbs html
    static string render(T)(string name, ...params)
    {
        return breadcrumbsManager().render!T(name, params);
    }
}

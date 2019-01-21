module hunt.framework.application.BreadcrumbsGenerator;

// import hunt.framework.application.BreadcrumbsManager;
import hunt.framework.application.BreadcrumbItem;

alias Handler = void delegate(BreadcrumbsGenerator crumb, Object[]...);

class BreadcrumbsGenerator {
    // BreadcrumbsGenerator parent;
    private BreadcrumbItem[] items;
    private Handler[string] callbacks;

    BreadcrumbItem[] generate(Handler[string] callbacks, string name, Object[] params...) {
        this.callbacks = callbacks;
        this.call(name, params);
        return items;
    }

    protected void call(string name, Object[] params...) {
        auto itemPtr = name in callbacks;
        if (itemPtr is null)
            throw new Exception("Breadcrumb not found with name " ~ name);
        (*itemPtr)(this, params);
    }

    void parent(string name, Object[] params...) {
        this.call(name, params);
    }

    void push(string name, string[string] params) {
        BreadcrumbItem item = new BreadcrumbItem();
        item.name = name;
        item.link = createUrl(name, params);

        items ~= item;
    }

    // static void register(T)(string name, Handler!T handle)
    // {
    //     breadcrumbsManager().register!T(name, handle);
    // }

    // // return BreadcrumbItem array
    // static BreadcrumbItem[] generate(string name, ...params)
    // {
    //     return breadcrumbsManager().generate(name, params);
    // }

    // // return BreadcrumbsGenerator html
    // static string render(T)(string name, ...params)
    // {
    //     return breadcrumbsManager().render!T(name, params);
    // }
}

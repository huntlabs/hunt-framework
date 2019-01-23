module hunt.framework.application.Breadcrumbs;

// import hunt.framework.Simplify;
import hunt.framework.application.BreadcrumbItem;
import std.container.array;
import std.array;

alias Handler = void delegate(Breadcrumbs crumb, Object[]...);

class Breadcrumbs {
    private Array!BreadcrumbItem items;
    private Handler[string] callbacks;

    BreadcrumbItem[] generate(Handler[string] callbacks, string name, Object[] params...) {
        items.clear();
        this.callbacks = callbacks;
        this.call(name, params);
        return items.array;
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

    // void push(string mca, string[string] params) {
    //     push(mca, createUrl(mca, params));
    // }

    void push(string title, string url) {
        BreadcrumbItem item = new BreadcrumbItem();
        item.title = title;
        item.link = url;

        items.insertBack(item);
    }

}

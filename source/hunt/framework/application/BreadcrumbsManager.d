module hunt.framework.application.BreadcrumbsManager;

import hunt.framework.application.BreadcrumbItem;
import hunt.framework.application.BreadcrumbsGenerator;

import std.array;

class BreadcrumbsManager {
    private BreadcrumbsGenerator generator;
    private Handler[string] callbacks;

    this() {
        generator = new BreadcrumbsGenerator();
    }

    void register(string name, Handler handler) {
        if (name in callbacks)
            throw new Exception("Breadcrumb name " ~ name ~ " has already been registered");
        callbacks[name] = handler;
    }

    bool exists(string name) {
        if (name.empty) {
            // TODO: Tasks pending completion -@zxp at 1/21/2019, 3:44:11 PM            
            // 
        }
        auto itemPtr = name in callbacks;
        return itemPtr !is null;
    }

    BreadcrumbItem[] generate(string name, Object[] params...) {
        string origName = name;

        if (name.empty) {
            return [];
        }

        try {
            return this.generator.generate(this.callbacks, name, params);
        } catch (Exception ex) {
            return [];
        }
    }

    string render(string name, Object[] params...) {
        BreadcrumbItem[] breadcrumbs = generate(name, params);
        string r;
        foreach(BreadcrumbItem item; breadcrumbs) {
            r ~= " | " ~ item.name ~ "[url=\"" ~ item.link ~ "\"]";
        }
        return r;
    }


}

private __gshared BreadcrumbsManager _breadcrumbsManager;

BreadcrumbsManager breadcrumbsManager() {
    if (_breadcrumbsManager is null) {
        _breadcrumbsManager = new BreadcrumbsManager;
    }

    return _breadcrumbsManager;
}

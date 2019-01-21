module hunt.framework.application.BreadcrumbsManager;

import hunt.framework.application.Breadcrumbs;
import hunt.framework.application.BreadcrumbItem;

class BreadcrumbsManager
{
    private Handler[string] callbacks;
}

private __gshared _breadcrumbsManager;

public BreadcrumbsManager breadcrumbsManager()
{
    if (_breadcrumbsManager is null)
    {
        _breadcrumbsManager = new BreadcrumbsManager;
    }

    return _breadcrumbsManager;
}

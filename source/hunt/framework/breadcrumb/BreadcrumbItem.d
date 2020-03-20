module hunt.framework.breadcrumb.BreadcrumbItem;

/**
 * 
 */
class BreadcrumbItem {
    string title;
    string link;

    override string toString() {
        return "title: " ~ title ~ ", link: " ~ link;
    }
}
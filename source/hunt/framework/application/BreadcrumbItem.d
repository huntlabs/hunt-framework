module hunt.framework.application.BreadcrumbItem;

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
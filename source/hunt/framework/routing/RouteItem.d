module hunt.framework.routing.RouteItem;


/**
 * 
 */
class RouteItem {
    string[] methods;

    string path;
    string urlTemplate;
    string pattern;
    string[int] paramKeys;

    bool isRegex = false;

}

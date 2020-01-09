/*
 * Hunt - A high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design.
 *
 * Copyright (C) 2015-2019, HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.framework.routing.Route;

// import hunt.framework.routing.Define;
// import hunt.http.routing.RoutingContext;

// class Route {
//     this() {
//         // Constructor code
//     }

//     Route copy() {
//         Route route = new Route;
//         // dfmt off
//         route.setGroup(_group)
//             .setUrlTemplate(_urlTemplate)
//             .setRoute(_route)
//             .setParamKeys(_paramKeys)
//             .setPattern(_pattern)
//             .setRegular(_regular)
//             .setModule(_module)
//             .setController(_controller)
//             .setAction(_action)
//             .setMethods(_methods)
//             .handle(_handle);
//         // dfmt on
//         return route;
//     }

//     Route setGroup(string groupValue) {
//         this._group = groupValue;
//         return this;
//     }

//     string getGroup() {
//         return this._group;
//     }

//     Route setUrlTemplate(string urlTemplate) {
//         this._urlTemplate = urlTemplate;
//         return this;
//     }

//     string getUrlTemplate() {
//         return this._urlTemplate;
//     }

//     Route setRoute(string routeValue) {
//         this._route = routeValue;
//         return this;
//     }

//     string getRoute() {
//         return this._route;
//     }

//     Route setParamKeys(string[int] paramKeys) {
//         this._paramKeys = paramKeys;
//         return this;
//     }

//     string[int] getParamKeys() {
//         return this._paramKeys;
//     }

//     Route setParams(string[string] params) {
//         this._params = params;
//         return this;
//     }

//     string[string] getParams() {
//         return this._params;
//     }

//     string getParameter(string key) {
//         return _params.get(key, "");
//     }

//     bool hasParameter(string key) {
//         string* p = (key in _params);
//         return p !is null;
//     }

//     Route setPattern(string patternValue) {
//         this._pattern = patternValue;
//         return this;
//     }

//     string getPattern() {
//         return this._pattern;
//     }

//     Route setRegular(bool regularValue) {
//         this._regular = regularValue;
//         return this;
//     }

//     bool getRegular() {
//         return this._regular;
//     }

//     Route setModule(string moduleValue) {
//         this._module = moduleValue;
//         return this;
//     }

//     string getModule() {
//         return this._module;
//     }

//     Route setController(string value) {
//         this._controller = value;
//         return this;
//     }

//     string getController() {
//         return this._controller;
//     }

//     Route setAction(string actionValue) {
//         this._action = actionValue;
//         return this;
//     }

//     string getAction() {
//         return this._action;
//     }

//     Route setMethods(HTTP_METHODS[] methods) {
//         this._methods = methods;
//         return this;
//     }

//     HTTP_METHODS[] getMethods() {
//         return this._methods;
//     }

//     @property RoutingHandler handle() {
//         return this._handle;
//     }

//     @property Route handle(RoutingHandler handle) {
//         this._handle = handle;
//         return this;
//     }

//     @property staticFilePath() {
//         return this._staticFilePath;
//     }

//     @property void staticFilePath(string path) {
//         this._staticFilePath = path;
//     }

//     string path;

//     override string toString() {
//         import std.format;
//         string str = format("group=%s, regular=%s, path=%s, methods=%s, route=%s", 
//             _group, _regular, path, _methods, _route);
//         return str;
//     }

//     private {
//         // Route group name
//         string _group;

//         // Regex template
//         string _urlTemplate;

//         // http uri params
//         string[int] _paramKeys;

//         string[string] _params;

//         // like uri path
//         string _pattern;

//         // path to module.controller.action
//         string _route;

//         // use regex?
//         bool _regular;

//         // hunt module
//         string _module;

//         // hunt controller
//         string _controller;

//         // hunt action
//         string _action;

//         // handle function
//         RoutingHandler _handle;

//         // allowd http methods
//         HTTP_METHODS[] _methods = [
//             HTTP_METHODS.GET, HTTP_METHODS.POST, HTTP_METHODS.PUT,
//             HTTP_METHODS.DELETE
//         ];

//         // staticDir:path
//         string _staticFilePath;
//     }
// }

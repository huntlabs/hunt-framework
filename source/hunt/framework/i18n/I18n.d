module hunt.framework.i18n.I18n;

import std.path;
import std.file;
import std.algorithm;
import std.array;
import std.stdio;
import std.string;
import std.json;

import hunt.logging;

alias StrStrStr = string[string][string];

enum I18N_DEFAULT_LOCALE = "en-us";

/**
*/
class I18n {
    private {
        StrStrStr _res;
        __gshared I18n _instance;
        string _default;
    }

    this() {
        _default = I18N_DEFAULT_LOCALE;
    }

    static I18n instance() {
        if (_instance is null) {
            _instance = new I18n();
        }
        return _instance;
    }

    bool loadLangResources(string path, lazy string ext = "ini") {
        _isResLoaded = false;
        auto resfiles = std.file.dirEntries(path, "*.{" ~ ext ~ "}", SpanMode.depth).filter!(a => a.isFile)
            .map!(a => std.path.absolutePath(a.name))
            .array;
        if (resfiles.length == 0) {
            logDebug("The lang resource file is empty");
            return false;
        }

        foreach (r; resfiles) {
            parseResFile(r);
        }
        _isResLoaded = true;
        return true;
    }

    @property bool isResLoaded() {
        return _isResLoaded;
    }

    private bool _isResLoaded = false;

    @property StrStrStr resources() {
        return this._res;
    }

    @property defaultLocale(string loc) {
        this._default = loc;
    }

    @property string defaultLocale() {
        return this._default;
    }

    private bool parseResFile(string fileName) {
        auto f = File(fileName, "r");
        scope (exit) {
            f.close();
        }

        if (!f.isOpen())
            return false;

        string _res_file_name = baseName(fileName, extension(fileName));
        string _loc = baseName(dirName(fileName));

        int line = 1;
        while (!f.eof()) {
            scope (exit)
                line += 1;
            string str = f.readln();
            str = strip(str);
            if (str.length == 0)
                continue;
            if (str[0] == '#' || str[0] == ';')
                continue;
            auto len = str.length - 1;

            auto site = str.indexOf("=");
            if (site == -1) {
                import std.format;

                throw new Exception(format("the format is erro in file %s, in line %d : string: %s",
                        fileName, line, str));
            }
            string key = str[0 .. site].strip;
            if (key.length == 0) {
                import std.format;

                throw new Exception(format("the Key is empty in file %s, in line %d",
                        fileName, line));
            }
            string value = str[site + 1 .. $].strip;

            this._res[_loc][_res_file_name ~ "." ~ key] = value;
        }
        return true;
    }

}

private string _local /* = I18N_DEFAULT_LOCALE */ ;

@property string getLocale() {
    if (_local)
        return _local;
    return I18n.instance().defaultLocale;
}

@property setLocale(string _l) {
    _local = toLower(_l);
}

deprecated("Using trans instead.")
alias getText = trans;

string transf(A...)(string key, lazy A args) {
    import std.format;
    Appender!string buffer;
    string text = trans(key);
    formattedWrite(buffer, text, args);

    return buffer.data;
}

string transfWithLocale(A...)(string locale, string key, lazy A args) {
    import std.format;
    Appender!string buffer;
    string text = trans(locale, key);
    formattedWrite(buffer, text, args);

    return buffer.data;
}

string transfWithLocale(string locale, string key, JSONValue args) {
    import hunt.framework.util.Formatter;
    string text = trans(locale, key);
    return StrFormat(text, args);
}

///key is [filename.key]
string trans(string key) {
    string defaultValue = key;
    I18n i18n = I18n.instance();
    if (!i18n.isResLoaded) {
        logWarning("The lang resources has't loaded yet!");
        return key;
    }

    auto p = getLocale in i18n.resources;
    if (p !is null) {
        return p.get(key, defaultValue);
    }
    logWarning("unsupported local: ", getLocale, ", use default now: ", i18n.defaultLocale);

    p = i18n.defaultLocale in i18n.resources;

    if (p !is null) {
        return p.get(key, defaultValue);
    }

    logWarning("unsupported locale: ", i18n.defaultLocale);

    return defaultValue;
}

///key is [filename.key]
string trans(string locale, string key) {
    string defaultValue = key;
    I18n i18n = I18n.instance();
    if (!i18n.isResLoaded) {
        logWarning("The lang resources has't loaded yet!");
        return key;
    }

    auto p = locale in i18n.resources;
    if (p !is null) {
        return p.get(key, defaultValue);
    }
    logWarning("unsupported locale: ", locale, ", use default now: ", i18n.defaultLocale);

    p = i18n.defaultLocale in i18n.resources;

    if (p !is null) {
        return p.get(key, defaultValue);
    }

    logDebug("unsupported locale: ", i18n.defaultLocale);

    return defaultValue;
}

// unittest{

//     I18n i18n = I18n.instance();
//     i18n.loadLangResources("./resources/translations");
//     i18n.defaultLocale = "en-us";
//     writeln(i18n.resources);

//     ///
//     setLocale("en-br");
//     assert( trans("message.hello-world") == "Hello, world");

//     ///
//     setLocale("zh-cn");
//     assert( trans("email.subject") == "收件人");

//     setLocale("en-us");
//     assert( trans("email.subject") == "email.subject");

//     assert(trans("message.title") == "%s Demo");
//     assert(transf("message.title", "Hunt") == "Hunt Demo");

//     assert(transfWithLocale("zh-cn", "message.title", "Hunt") == "Hunt 示例");
// }


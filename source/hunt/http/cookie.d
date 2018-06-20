/*
 * Hunt - Hunt is a high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design. It lets you build high-performance Web applications quickly and easily.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Website: www.huntframework.com
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
module hunt.http.cookie;

import hunt.exception;;
import std.regex : regex, Regex;
import std.string;
import std.conv;

static import std.algorithm;
import core.stdc.stdlib;
import std.stdio;

// XXX VOLVER A PROBAR, HE CAMBIADO TODO LO DE REGEX!

// Inspired by Python's Cookie.py but Cookie objects are a little different; this 
// class only stores one cookie per object, not several like the Python version.
// Use parse_cookie_header to get a Cookie[] with all the cookies found in a 
// string

class CookieException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}

// Used for encoded cookie values matching
Regex!char _OctalPatt;
Regex!char _QuotePatt;
string[string] RESERVED_PARAMS = null;

static this()
{
    _OctalPatt = regex(r"\\[0-3][0-7][0-7]");
    _QuotePatt = regex(r"[\\].");

    RESERVED_PARAMS = ["expires" : "expires", "path" : "Path",
        "comment" : "Comment", "domain" : "Domain", "max-age" : "Max-Age",
        "secure" : "secure", "httponly" : "httponly", "version" : "Version",
        "raw" : "raw","samesite" : "samesite"];
}

// Chars not needing quotation (fake set for fast lookup)
enum _legalchars = ['a' : 0, 'b' : 0, 'c' : 0, 'd' : 0, 'e' : 0, 'f' : 0, 'g' : 0,
        'h' : 0, 'i' : 0, 'j' : 0, 'k' : 0, 'l' : 0, 'm' : 0, 'n' : 0, 'o' : 0,
        'p' : 0, 'q' : 0, 'r' : 0, 's' : 0, 't' : 0, 'u' : 0, 'v' : 0, 'w' : 0,
        'x' : 0, 'y' : 0, 'z' : 0, 'A' : 0, 'B' : 0, 'C' : 0, 'D' : 0, 'E' : 0,
        'F' : 0, 'G' : 0, 'H' : 0, 'I' : 0, 'J' : 0, 'K' : 0, 'L' : 0, 'M' : 0,
        'N' : 0, 'O' : 0, 'P' : 0, 'Q' : 0, 'R' : 0, 'S' : 0, 'T' : 0, 'U' : 0,
        'V' : 0, 'W' : 0, 'X' : 0, 'Y' : 0, 'Z' : 0, '0' : 0, '1' : 0, '2' : 0,
        '3' : 0, '4' : 0, '5' : 0, '6' : 0, '7' : 0, '8' : 0, '9' : 0, '!' : 0,
        '#' : 0, '$' : 0, '%' : 0, '&' : 0, '\'' : 0, '*' : 0, '+' : 0, '-' : 0,
        '.' : 0, '^' : 0, '_' : 0, '`' : 0, '|' : 0, '~' : 0];

// Hash for quickly translating chars not in _legalchars
// The "," and ";" are encoded for compatibility with some 
// Safari & Explorer versions
enum _cookiechars = [
        std.conv.octal!0 : "\\000", std.conv.octal!1 : "\\001",
        std.conv.octal!2 : "\\002", std.conv.octal!3 : "\\003",
        std.conv.octal!4 : "\\004", std.conv.octal!5 : "\\005",
        std.conv.octal!6 : "\\006", std.conv.octal!7 : "\\007",
        std.conv.octal!10 : "\\010", std.conv.octal!11 : "\\011",
        std.conv.octal!12 : "\\012", std.conv.octal!13 : "\\013",
        std.conv.octal!14 : "\\014", std.conv.octal!15 : "\\015",
        std.conv.octal!16 : "\\016", std.conv.octal!17 : "\\017",
        std.conv.octal!20 : "\\020", std.conv.octal!21 : "\\021",
        std.conv.octal!22 : "\\022", std.conv.octal!23 : "\\023",
        std.conv.octal!24 : "\\024", std.conv.octal!25 : "\\025",
        std.conv.octal!26 : "\\026", std.conv.octal!27 : "\\027",
        std.conv.octal!30 : "\\030", std.conv.octal!31 : "\\031",
        std.conv.octal!32 : "\\032", std.conv.octal!33 : "\\033",
        std.conv.octal!34 : "\\034", std.conv.octal!35 : "\\035",
        std.conv.octal!36 : "\\036", std.conv.octal!37 : "\\037",

        std.conv.octal!54 : "\\054", std.conv.octal!73 : "\\073",

        std.conv.octal!177 : "\\177", std.conv.octal!200 : "\\200",
        std.conv.octal!201 : "\\201", std.conv.octal!202 : "\\202",
        std.conv.octal!203 : "\\203", std.conv.octal!204 : "\\204",
        std.conv.octal!205 : "\\205", std.conv.octal!206 : "\\206",
        std.conv.octal!207 : "\\207", std.conv.octal!210 : "\\210",
        std.conv.octal!211 : "\\211", std.conv.octal!212 : "\\212",
        std.conv.octal!213 : "\\213", std.conv.octal!214 : "\\214",
        std.conv.octal!215 : "\\215", std.conv.octal!216 : "\\216",
        std.conv.octal!217 : "\\217", std.conv.octal!220 : "\\220",
        std.conv.octal!221 : "\\221", std.conv.octal!222 : "\\222",
        std.conv.octal!223 : "\\223", std.conv.octal!224 : "\\224",
        std.conv.octal!225 : "\\225", std.conv.octal!226 : "\\226",
        std.conv.octal!227 : "\\227", std.conv.octal!230 : "\\230",
        std.conv.octal!231 : "\\231", std.conv.octal!232 : "\\232",
        std.conv.octal!233 : "\\233", std.conv.octal!234 : "\\234",
        std.conv.octal!235 : "\\235", std.conv.octal!236 : "\\236",
        std.conv.octal!237 : "\\237", std.conv.octal!240 : "\\240",
        std.conv.octal!241 : "\\241", std.conv.octal!242 : "\\242",
        std.conv.octal!243 : "\\243", std.conv.octal!244 : "\\244",
        std.conv.octal!245 : "\\245", std.conv.octal!246 : "\\246",
        std.conv.octal!247 : "\\247", std.conv.octal!250 : "\\250",
        std.conv.octal!251 : "\\251", std.conv.octal!252 : "\\252",
        std.conv.octal!253 : "\\253", std.conv.octal!254 : "\\254",
        std.conv.octal!255 : "\\255", std.conv.octal!256 : "\\256",
        std.conv.octal!257 : "\\257", std.conv.octal!260 : "\\260",
        std.conv.octal!261 : "\\261", std.conv.octal!262 : "\\262",
        std.conv.octal!263 : "\\263", std.conv.octal!264 : "\\264",
        std.conv.octal!265 : "\\265", std.conv.octal!266 : "\\266",
        std.conv.octal!267 : "\\267", std.conv.octal!270 : "\\270",
        std.conv.octal!271 : "\\271", std.conv.octal!272 : "\\272",
        std.conv.octal!273 : "\\273", std.conv.octal!274 : "\\274",
        std.conv.octal!275 : "\\275", std.conv.octal!276 : "\\276",
        std.conv.octal!277 : "\\277", std.conv.octal!300 : "\\300",
        std.conv.octal!301 : "\\301", std.conv.octal!302 : "\\302",
        std.conv.octal!303 : "\\303", std.conv.octal!304 : "\\304",
        std.conv.octal!305 : "\\305", std.conv.octal!306 : "\\306",
        std.conv.octal!307 : "\\307", std.conv.octal!310 : "\\310",
        std.conv.octal!311 : "\\311", std.conv.octal!312 : "\\312",
        std.conv.octal!313 : "\\313", std.conv.octal!314 : "\\314",
        std.conv.octal!315 : "\\315", std.conv.octal!316 : "\\316",
        std.conv.octal!317 : "\\317", std.conv.octal!320 : "\\320",
        std.conv.octal!321 : "\\321", std.conv.octal!322 : "\\322",
        std.conv.octal!323 : "\\323", std.conv.octal!324 : "\\324",
        std.conv.octal!325 : "\\325", std.conv.octal!326 : "\\326",
        std.conv.octal!327 : "\\327", std.conv.octal!330 : "\\330",
        std.conv.octal!331 : "\\331", std.conv.octal!332 : "\\332",
        std.conv.octal!333 : "\\333", std.conv.octal!334 : "\\334",
        std.conv.octal!335 : "\\335", std.conv.octal!336 : "\\336",
        std.conv.octal!337 : "\\337", std.conv.octal!340 : "\\340",
        std.conv.octal!341 : "\\341", std.conv.octal!342 : "\\342",
        std.conv.octal!343 : "\\343", std.conv.octal!344 : "\\344",
        std.conv.octal!345 : "\\345", std.conv.octal!346 : "\\346",
        std.conv.octal!347 : "\\347", std.conv.octal!350 : "\\350",
        std.conv.octal!351 : "\\351", std.conv.octal!352 : "\\352",
        std.conv.octal!353 : "\\353", std.conv.octal!354 : "\\354",
        std.conv.octal!355 : "\\355", std.conv.octal!356 : "\\356",
        std.conv.octal!357 : "\\357", std.conv.octal!360 : "\\360",
        std.conv.octal!361 : "\\361", std.conv.octal!362 : "\\362",
        std.conv.octal!363 : "\\363", std.conv.octal!364 : "\\364",
        std.conv.octal!365 : "\\365", std.conv.octal!366 : "\\366",
        std.conv.octal!367 : "\\367", std.conv.octal!370 : "\\370",
        std.conv.octal!371 : "\\371", std.conv.octal!372 : "\\372",
        std.conv.octal!373 : "\\373", std.conv.octal!374 : "\\374",
        std.conv.octal!375 : "\\375", std.conv.octal!376 : "\\376",
        std.conv.octal!377 : "\\377",
    ];

bool has_legal_chars(string s)
{
    foreach (c; s)
    {
        if (c !in _legalchars)
            return false;
    }

    return true;
}

string cookie_quote(string input)
{
    char[] result = new char[input.length * 4];
    uint lastid = 0;
    bool usedspecial = false;

    foreach (c; input)
    {

        if (c !in _legalchars)
        {
            // Not legal char
            usedspecial = true;

            if (cast(uint) c in _cookiechars)
            {
                // We got encoding for it
                result[lastid .. lastid + 4] = _cookiechars[cast(uint) c];
                lastid += 4;
            }
            else
            {
                // Not in legalchars, not in the cookiechars either... just append it, 
                // but the string is already marked as "special" so it will be quoted
                result[lastid] = c;
                ++lastid;
            }

        }
        else
        {
            result[lastid] = c;
            ++lastid;
        }
    }

    result.length = lastid;

    // Put quotes around the string if we used some encoded character
    return usedspecial ? '"' ~ to!string(result) ~ '"' : to!string(result);
}

// XXX Optimize this, use a string Appender or a char[], etc...
string cookie_unquote(string quoted_value)
{
    string result = "";

    // If there aren't any doublequotes, then there can't special chars. See RFC 2109
    if (quoted_value.length < 2)
        return quoted_value;

    //if (quoted_value[0] != '"' || quoted_value[$-1] != '"')
    //return quoted_value;

    // Remove the "..."
    string unquoted = quoted_value; //[1..$-1];

    // Check for special chars \012 => \n, \" => "
    size_t i = 0;
    auto n = unquoted.length;
    size_t Omatch, Qmatch;
    size_t j, k;

    while (i >= 0 && i < n)
    {
        import std.regex;

        auto ocaptures = match(unquoted[i .. $], _OctalPatt).captures;
        if (ocaptures.length == 0)
            Omatch = -1;
        else
            Omatch = std.string.indexOf(unquoted[i .. $], ocaptures[0]);

        auto qcaptures = match(unquoted[i .. $], _QuotePatt).captures;
        if (qcaptures.length == 0)
            Qmatch = -1;
        else
            Qmatch = std.string.indexOf(unquoted[i .. $], qcaptures[0]);

        if (Omatch == -1 && Qmatch == -1)
        { // Neither matched
            result ~= unquoted[i .. $];
            break;
        }

        j = -1;
        k = -1;
        if (Omatch != -1)
            j = Omatch + i;
        if (Qmatch != -1)
            k = Qmatch + i;

        if (Qmatch != -1 && ((Omatch == -1) || (k < j))) // QuotePatt matched
        {
            result ~= unquoted[i .. k] ~ unquoted[k + 1];
            i = k + 2;
        }
        else // OctalPatt matched
        {
            result ~= unquoted[i .. j];
            result ~= cast(char) strtoul(toStringz(unquoted[j + 1 .. j + 4]), null,
                8);
            i = j + 4;
        }
    }

    return result;
}

// XXX: Capture possible exceptions
// Convert a (possibly encoded) client "Cookie: " HTTP header into an
// list of Cookie objects. This function expects the "Cookie: " or 
// "Set-Cookie: " header name to be already removed
Cookie[string] parseCookie(string header)
{
    /// if cookie string is not null
    if (header is null)
        return null;

    /// parse the cookies
    Cookie[string] result;

    string[] cookie_parts = header.split(";");

    foreach (idx, part; cookie_parts)
    {
        auto cookie = new Cookie();
        string[] keyvalue = part.split("=");
        if (keyvalue.length != 2) // WTF!?
            continue;

        string key = keyvalue[0].strip;

        if (key[0] == '$')
            continue;

        string quoted_value = keyvalue[1];

        string lkey = toLower(key);

        if (lkey in RESERVED_PARAMS)
        {
            // Ignore if we've not set the name yet
            if (!cookie.is_name_set)
                continue;

            cookie.set(lkey, cookie_unquote(quoted_value));

            // Add the cookie if this is the last token
            if (idx == cookie_parts.length - 1)
            {
                result[lkey] = cookie;
            }
        }

        // It is a name-value, not a reserved param
        else
        {
            cookie.set(key, cookie_unquote(quoted_value));
            result[key] = cookie;
        }
    }

    return result;
}

// =================================
// Cookie class
// =================================
class Cookie
{
    enum DEFAULT_HEADER = "Set-Cookie: ";

    enum SAMESITE_LAX = "lax";
    enum SAMESITE_STRICT = "strict";

    static bool is_reserved_key(string key)
    {
        return (toLower(key) in RESERVED_PARAMS) != null;
    }

    this(string cname, string cvalue, string[string] cparams)
    {
        this(cname, cvalue);
        params(cparams);

    }

    this(string cname, string cvalue)
    {
        set(cname, cvalue);
        this();
    }

    this()
    {
        initialize_cookieparams();
    }

    void set(string name, string value)
    in
    {
        assert(name != null);
        //assert(value != null);
    }
    body
    {
        string lname = toLower(name);
        if (lname in RESERVED_PARAMS)
        {
            _cookieparams[lname] = value;
        }
        else
        {
            // Check that all the chars in the name are legal
            if (!has_legal_chars(name))
                throw new CookieException("Illegal name '" ~ name ~ "' has ilegal chars");

            _name = name;
            _value = value;
            _quoted_value = cookie_quote(value);
        }
    }

    @property string name()
    {
        if (_name is null)
            throw new CookieException("Cookie name not set");
        return _name;
    }

    @property void name(string newname)
    {
        if (!has_legal_chars(name))
            throw new CookieException("The name '" ~ name ~ "' has ilegal chars");

        _name = newname;
    }

    @property string value()
    {
        if (_value is null)
            throw new CookieException("Cookie value not set");
        return _value;
    }

    @property void value(string newvalue)
    {
        _value = newvalue;
        _quoted_value = cookie_quote(_value);
    }

    @property string quoted_value()
    {
        if (_quoted_value is null)
            throw new CookieException("Cookie quoted_value not set");
        return _quoted_value;
    }

    @property void quoted_value(string newvalue)
    {
        _quoted_value = newvalue;
        _value = cookie_unquote(_quoted_value);
    }

    @property string[string] params()
    {
        return _cookieparams;
    }

    @property void params(string[string] newparams)
    {
        // Join the dicts
        foreach (key, value; newparams)
        {
            if (!has_legal_chars(key))
                throw new CookieException("The key '" ~ key ~ "' has ilegal chars");

            string lkey = toLower(key);
            if (lkey in RESERVED_PARAMS)
                _cookieparams[lkey] = value;
            else
                throw new CookieException("Wrong cookie parameter '" ~ key ~ "'");
        }
    }

    @property bool is_name_set()
    {
        return !(_name is null);
    }

    @property bool is_value_set()
    {
        return !(_value is null);
    }

    string get(const string key)
    {
        auto res = get(key, null);

        return res;
    }

    string get(const string key, const string _default)
    {
        if (key == _name)
            return _value;

        string lkey = toLower(key);
        if (lkey in _cookieparams)
            return _cookieparams[lkey];

        return _default;
    }

    void setkey(string key, string _value)
    {
        string lkey = toLower(key);
        if (lkey !in RESERVED_PARAMS && key != _name)
            throw new CookieException(
                "Wrong cookie index '" ~ key ~ "'. Use 'name', 'value', 'quoted_value' or valid cookie parameter (see RFC 2109)");

        if (key == _name)
            name(_value);
        else
            _cookieparams[lkey] = _value;
    }

    string output(string[] attrs, string header)
    {
        string result = header ~ _name ~ "=" ~ _quoted_value;
        auto paramkeys = _cookieparams.keys;

        foreach (param, value; _cookieparams)
        {
            // Add the cooieparam only if is in the user specified attrs and is not empty
            if (std.algorithm.countUntil(attrs, param) != -1 && value.length > 0)
                result ~= ";" ~ param ~ "=" ~ value;
        }
        return result;
    }

    string output(string header)
    {
        return output(_cookieparams.keys, header);
    }

    string output()
    {
        return output(_cookieparams.keys, DEFAULT_HEADER);
    }

    override string toString()
    {
        return output();
    }

    /**
     * Gets the name of the cookie.
     *
     * @return string
     */
    public string getName()
    {
        return name();
    }
    /**
     * Gets the value of the cookie.
     *
     * @return string|null
     */
    public string getValue()
    {
        return value();
    }
    /**
     * Gets the domain that the cookie is available to.
     *
     * @return string|null
     */
    public string getDomain()
    {
        return get("domain");
    }
    /**
     * Gets the time the cookie expires.
     *
     * @return string
     */
    public string getExpiresTime()
    {
        return get("expires");
    }
    /**
     * Gets the max-age attribute.
     *
     * @return string
     */
    public string getMaxAge()
    {
        return get("max-age");
    }
    /**
     * Gets the path on the server in which the cookie will be available on.
     *
     * @return string
     */
    public string getPath()
    {
        return get("path");
    }
    /**
     * Checks whether the cookie should only be transmitted over a secure HTTPS connection from the client.
     *
     * @return bool
     */
    public bool isSecure()
    {
        return get("secure") == "true" ? true : false;
    }
    /**
     * Checks whether the cookie will be made accessible only through the HTTP protocol.
     *
     * @return bool
     */
    public bool isHttpOnly()
    {
        return get("httponly") == "true" ? true : false;
    }
    /**
     * Whether this cookie is about to be cleared.
     *
     * @return bool
     */
    public bool isCleared()
    {
        throw new NotImplementedException("isCleared");
    }
    /**
     * Checks if the cookie value should be sent with no url encoding.
     *
     * @return bool
     */
    public bool isRaw()
    {
        return get("raw") == "true" ? true : false;
    }
    /**
     * Gets the SameSite attribute.
     *
     * @return string|null
     */
    public string getSameSite()
    {
        return get("samesite");
    }

private:
    string _name = null;
    string _quoted_value = null;
    string _value = null;
    string _decodedvalue = null;
    string[string] _cookieparams = null;

protected:
    void initialize_cookieparams()
    {
        /*foreach (key, value; RESERVED_PARAMS)
        {
            if(key == "expires")
                _cookieparams[key] = "0";
            else if(key == "path")
                _cookieparams[key] = "/";
            else if(key == "secure")
                _cookieparams[key] = "false";
            else if(key == "httponly")
                _cookieparams[key] = "false";

            else if(key == "raw")
                _cookieparams[key] = "true";
            else
                 _cookieparams[key] = "";

        }*/
    }

}

unittest
{
    auto cookies = parseCookie("PHPSESSID=dh5vvosj68hv1raprertnku6s7; LBN=node2; Hm_lvt_9e6c6312b8b64e7e38b0b84c12642b96=1461739077,1461897406,1462760128,1462760222; Hm_lpvt_9e6c6312b8b64e7e38b0b84c12642b96=1463122691; __utmt=1; __utma=233165215.1997191855.1458546658.1463106445.1463122691.5; __utmb=233165215.1.10.1463122691; __utmc=233165215; __utmz=233165215.1458546658.1.1.utmcsr=account.start.wang|utmccn=(referral)|utmcmd=referral|utmcct=/register");
    
    assert(cookies.get("PHPSESSID", null).value == "dh5vvosj68hv1raprertnku6s7");
    assert(cookies["LBN"].value == "node2");
}

unittest
{
    //generate cookie
    auto cookie = new Cookie("PHPSESSID", "dh5vvosj68hv1raprertnku6s7");
    //assert();
    import kiss.logger;

    logDebug(cookie.output);
    assert(cookie.output == "Set-Cookie: PHPSESSID=dh5vvosj68hv1raprertnku6s7");
    /*cookie.params = ["expires" : "Fri, 13 May 2016 17:44:17 GMT", "path" : "/",
        "domain" : "putao.com", "secure" : "true", "httponly" : "false"];

    logDebug(cookie.output);
    assert( cookie.output == "Set-Cookie: PHPSESSID=dh5vvosj68hv1raprertnku6s7;expires=Fri, 13 May 2016 17:44:17 GMT;domain=putao.com;path=/;secure=true;httponly=false;raw=true");
    */
}

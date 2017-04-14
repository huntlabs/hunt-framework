/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2017  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs
 *
 * Licensed under the Apache-2.0 License.
 *
 */

module hunt.utils.url;
/**
	* A URL handling library.
	*
	* URLs are Unique Resource Locators. They consist of a scheme and a host, with some optional
	* elements like port, path, username, and password.
	*
	* This module aims to make it simple to muck about with them.
	*
	* Example usage:
	* ---
	* auto url = "ssh://me:password@192.168.0.8/".parseURL;
	* auto files = system("ssh", url.toString, "ls").splitLines;
	* foreach (file; files) {
	*		system("scp", url ~ file, ".");
	* }
	* ---
	*
	* License: The MIT license.
	*/

import std.conv;
import std.string;
import std.exception;

pure:
@safe:

/// An exception thrown when something bad happens with URLs.
class URLException : Exception
{
	mixin basicExceptionCtors;
}

/**
	* A mapping from schemes to their default ports.
	*
  * This is not exhaustive. Not all schemes use ports. Not all schemes uniquely identify a port to
	* use even if they use ports. Entries here should be treated as best guesses.
  */
enum ushort[string] schemeToDefaultPort = [
	"aaa": 3868,
	"aaas": 5658,
	"acap": 674,
	"amqp": 5672,
	"cap": 1026,
	"coap": 5683,
	"coaps": 5684,
	"dav": 443,
	"dict": 2628,
	"ftp": 21,
	"git": 9418,
	"go": 1096,
	"gopher": 70,
	"http": 80,
	"https": 443,
	"ws": 80,
	"wss": 443,
	"iac": 4569,
	"icap": 1344,
	"imap": 143,
	"ipp": 631,
	"ipps": 631,  // yes, they're both mapped to port 631
	"irc": 6667,  // De facto default port, not the IANA reserved port.
	"ircs": 6697,
	"iris": 702,  // defaults to iris.beep
	"iris.beep": 702,
	"iris.lwz": 715,
	"iris.xpc": 713,
	"iris.xpcs": 714,
	"jabber": 5222,  // client-to-server
	"ldap": 389,
	"ldaps": 636,
	"msrp": 2855,
	"msrps": 2855,
	"mtqp": 1038,
	"mupdate": 3905,
	"news": 119,
	"nfs": 2049,
	"pop": 110,
	"redis": 6379,
	"reload": 6084,
	"rsync": 873,
	"rtmfp": 1935,
	"rtsp": 554,
	"shttp": 80,
	"sieve": 4190,
	"sip": 5060,
	"sips": 5061,
	"smb": 445,
	"smtp": 25,
	"snews": 563,
	"snmp": 161,
	"soap.beep": 605,
	"ssh": 22,
	"stun": 3478,
	"stuns": 5349,
	"svn": 3690,
	"teamspeak": 9987,
	"telnet": 23,
	"tftp": 69,
	"tip": 3372,
	"mysql": 3306,
	"postgresql": 5432,
];

/**
	* A Unique Resource Locator.
	*
	* URLs can be parsed (see parseURL) and implicitly convert to strings.
	*/
struct URL
{
	hash_t toHash() const @safe nothrow
	{
		return asTuple().toHash();
	}
	
pure:
	/// The URL scheme. For instance, ssh, ftp, or https.
	string scheme;
	
	/// The username in this URL. Usually absent. If present, there will also be a password.
	string user;
	
	/// The password in this URL. Usually absent.
	string pass;
	
	/// The hostname.
	string host;

	string[string] queryArr;
	
	/**
	  * The port.
		*
	  * This is inferred from the scheme if it isn't present in the URL itself.
	  * If the scheme is not known and the port is not present, the port will be given as 0.
	  * For some schemes, port will not be sensible -- for instance, file or chrome-extension.
	  *
	  * If you explicitly need to detect whether the user provided a port, check the providedPort
	  * field.
	  */
	@property ushort port() const nothrow
	{
		if (providedPort != 0) {
			return providedPort;
		}
		if (auto p = scheme in schemeToDefaultPort) {
			return *p;
		}
		return 0;
	}
	
	/**
	  * Set the port.
		*
		* This sets the providedPort field and is provided for convenience.
		*/
	@property ushort port(ushort value) nothrow
	{
		return providedPort = value;
	}
	
	/// The port that was explicitly provided in the URL.
	ushort providedPort;
	
	/**
	  * The path.
	  *
	  * For instance, in the URL https://cnn.com/news/story/17774?visited=false, the path is
	  * "/news/story/17774".
	  */
	string path;
	
	/**
		* The query parameters associated with this URL.
		*/
	string query;
	
	/**
	  * The fragment. In web documents, this typically refers to an anchor element.
	  * For instance, in the URL https://cnn.com/news/story/17774#header2, the fragment is "header2".
	  */
	string fragment;
	
	/**
	  * Convert this URL to a string.
	  * The string is properly formatted and usable for, eg, a web request.
	  */
	string toString() const
	{
		return toString(false);
	}
	
	/**
		* Convert this URL to a string.
        *
		* The string is intended to be human-readable rather than machine-readable.
		*/
	string toHumanReadableString() const
	{
		return toString(true);
	}
	
	///
	unittest
	{
		auto url = "https://xn--m3h.xn--n3h.org/?hi=bye".parseURL;
		assert(url.toString == "https://xn--m3h.xn--n3h.org/?hi=bye", url.toString);
		assert(url.toHumanReadableString == "https://☂.☃.org/?hi=bye", url.toString);
	}
	
	unittest
	{
		assert("http://example.org/some_path".parseURL.toHumanReadableString ==
			"http://example.org/some_path");
	}
	
	private string toString(bool humanReadable) const
	{
		import std.array : Appender;
		Appender!string s;
		s ~= scheme;
		s ~= "://";
		if (user) {
			s ~= humanReadable ? user : user.percentEncode;
			s ~= ":";
			s ~= humanReadable ? pass : pass.percentEncode;
			s ~= "@";
		}
		s ~= humanReadable ? host : host.toPuny;
		if (providedPort) {
			if ((scheme in schemeToDefaultPort) == null || schemeToDefaultPort[scheme] != providedPort) {
				s ~= ":";
				s ~= providedPort.to!string;
			}
		}
		string p = path;
		if (p.length == 0 || p == "/") {
			s ~= '/';
		} else {
			if (humanReadable) {
				s ~= p;
			} else {
				if (p[0] == '/') {
					p = p[1..$];
				}
				foreach (part; p.split('/')) {
					s ~= '/';
					s ~= part.percentEncode;
				}
			}
		}
		if (query.length) {
			s ~= '?';
			s ~= query;
		}		
		if (fragment) {
			s ~= '#';
			s ~= fragment.percentEncode;
		}
		return s.data;
	}
	
	/// Implicitly convert URLs to strings.
	alias toString this;
	
	/**
      Compare two URLs.

      I tried to make the comparison produce a sort order that seems natural, so it's not identical
      to sorting based on .toString(). For instance, username/password have lower priority than
      host. The scheme has higher priority than port but lower than host.

      While the output of this is guaranteed to provide a total ordering, and I've attempted to make
      it human-friendly, it isn't guaranteed to be consistent between versions. The implementation
      and its results can change without a minor version increase.
    */
	int opCmp(const URL other) const
	{
		return asTuple.opCmp(other.asTuple);
	}
	
	private auto asTuple() const nothrow
	{
		import std.typecons : tuple;
		return tuple(host, scheme, port, user, pass, path, query);
	}
	
	/// Equality checks.
	bool opEquals(string other) const
	{
		URL o;
		if (!tryParseURL(other, o))
		{
			return false;
		}
		return asTuple() == o.asTuple();
	}
	
	/// Ditto
	bool opEquals(ref const URL other) const
	{
		return asTuple() == other.asTuple();
	}
	
	/// Ditto
	bool opEquals(const URL other) const
	{
		return asTuple() == other.asTuple();
	}
	
	unittest
	{
		import std.algorithm, std.array, std.format;
		assert("http://example.org/some_path".parseURL > "http://example.org/other_path".parseURL);
		alias sorted = std.algorithm.sort;
		auto parsedURLs =
		[
			"http://example.org/some_path",
			"http://example.org:81/other_path",
			"http://example.org/other_path",
			"https://example.org/first_path",
			"http://example.xyz/other_other_path",
			"http://me:secret@blog.ikeran.org/wp_admin",
		].map!(x => x.parseURL).array;
		auto urls = sorted(parsedURLs).map!(x => x.toHumanReadableString).array;
		auto expected =
		[
			"http://me:secret@blog.ikeran.org/wp_admin",
			"http://example.org/other_path",
			"http://example.org/some_path",
			"http://example.org:81/other_path",
			"https://example.org/first_path",
			"http://example.xyz/other_other_path",
		];
		assert(cmp(urls, expected) == 0, "expected:\n%s\ngot:\n%s".format(expected, urls));
	}
	
	unittest
	{
		auto a = "http://x.org/a?b=c".parseURL;
		auto b = "http://x.org/a?d=e".parseURL;
		auto c = "http://x.org/a?b=a".parseURL;
		assert(a < b);
		assert(c < b);
		assert(c < a);
	}
	
	/**
		* The append operator (~).
		*
		* The append operator for URLs returns a new URL with the given string appended as a path
		* element to the URL's path. It only adds new path elements (or sequences of path elements).
		*
		* Don't worry about path separators; whether you include them or not, it will just work.
		*
		* Query elements are copied.
		*
		* Examples:
		* ---
		* auto random = "http://testdata.org/random".parseURL;
		* auto randInt = random ~ "int";
		* writeln(randInt);  // prints "http://testdata.org/random/int"
		* ---
		*/
	URL opBinary(string op : "~")(string subsequentPath) {
		URL other = this;
		other ~= subsequentPath;
		return other;
	}
	
	/**
		* The append-in-place operator (~=).
		*
		* The append operator for URLs adds a path element to this URL. It only adds new path elements
		* (or sequences of path elements).
		*
		* Don't worry about path separators; whether you include them or not, it will just work.
		*
		* Examples:
		* ---
		* auto random = "http://testdata.org/random".parseURL;
		* random ~= "int";
		* writeln(random);  // prints "http://testdata.org/random/int"
		* ---
		*/
	URL opOpAssign(string op : "~")(string subsequentPath) {
		if (path.endsWith("/")) {
			if (subsequentPath.startsWith("/")) {
				path ~= subsequentPath[1..$];
			} else {
				path ~= subsequentPath;
			}
		} else {
			if (!subsequentPath.startsWith("/")) {
				path ~= '/';
			}
			path ~= subsequentPath;
		}
		return this;
	}
	
	/**
        * Convert a relative URL to an absolute URL.
        *
        * This is designed so that you can scrape a webpage and quickly convert links within the
        * page to URLs you can actually work with, but you're clever; I'm sure you'll find more uses
        * for it.
        *
        * It's biased toward HTTP family URLs; as one quirk, "//" is interpreted as "same scheme,
        * different everything else", which might not be desirable for all schemes.
        *
        * This only handles URLs, not URIs; if you pass in 'mailto:bob.dobbs@subgenius.org', for
        * instance, this will give you our best attempt to parse it as a URL.
        *
        * Examples:
        * ---
        * auto base = "https://example.org/passworddb?secure=false".parseURL;
        *
        * // Download https://example.org/passworddb/by-username/dhasenan
        * download(base.resolve("by-username/dhasenan"));
        *
        * // Download https://example.org/static/style.css
        * download(base.resolve("/static/style.css"));
        *
        * // Download https://cdn.example.net/jquery.js
        * download(base.resolve("https://cdn.example.net/jquery.js"));
        * ---
        */
	URL resolve(string other)
	{
		if (other.length == 0) return this;
		if (other[0] == '/')
		{
			if (other.length > 1 && other[1] == '/')
			{
				// Uncommon syntax: a link like "//wikimedia.org" means "same scheme, switch URL"
				return parseURL(this.scheme ~ ':' ~ other);
			}
		}
		else
		{
			auto schemeSep = other.indexOf("://");
			if (schemeSep >= 0 && schemeSep < other.indexOf("/"))
				// separate URL
			{
				return other.parseURL;
			}
		}
		
		URL ret = this;
		ret.path = "";
		if (other[0] != '/')
		{
			// relative to something
			if (!this.path.length)
			{
				// nothing to be relative to
				other = "/" ~ other;
			}
			else if (this.path[$-1] == '/')
			{
				// directory-style path for the current thing
				// resolve relative to this directory
				other = this.path ~ other;
			}
			else
			{
				// this is a file-like thing
				// find the 'directory' and relative to that
				other = this.path[0..this.path.lastIndexOf('/') + 1] ~ other;
			}
		}
		// collapse /foo/../ to /
		if (other.indexOf("/../") >= 0)
		{
			import std.array : Appender, array;
			import std.string : split;
			import std.algorithm.iteration : joiner, filter;
			string[] parts = other.split('/');
			for (int i = 0; i < parts.length; i++)
			{
				if (parts[i] == "..")
				{
					for (int j = i - 1; j >= 0; j--)
					{
						if (parts[j] != null)
						{
							parts[j] = null;
							parts[i] = null;
							break;
						}
					}
				}
			}
			other = "/" ~ parts.filter!(x => x != null).joiner("/").to!string;
		}
		parsePathAndQuery(ret, other);
		return ret;
	}
	
	unittest
	{
		auto a = "http://alcyius.com/dndtools/index.html".parseURL;
		auto b = a.resolve("contacts/index.html");
		assert(b.toString == "http://alcyius.com/dndtools/contacts/index.html");
	}
	
	unittest
	{
		auto a = "http://alcyius.com/dndtools/index.html?a=b".parseURL;
		auto b = a.resolve("contacts/index.html?foo=bar");
		assert(b.toString == "http://alcyius.com/dndtools/contacts/index.html?foo=bar");
	}
	
	unittest
	{
		auto a = "http://alcyius.com/dndtools/index.html".parseURL;
		auto b = a.resolve("../index.html");
		assert(b.toString == "http://alcyius.com/index.html", b.toString);
	}
	
	unittest
	{
		auto a = "http://alcyius.com/dndtools/foo/bar/index.html".parseURL;
		auto b = a.resolve("../index.html");
		assert(b.toString == "http://alcyius.com/dndtools/foo/index.html", b.toString);
	}
}

/**
	* Parse a URL from a string.
	*
	* This attempts to parse a wide range of URLs as people might actually type them. Some mistakes
	* may be made. However, any URL in a correct format will be parsed correctly.
	*/
bool tryParseURL(string value, out URL url)
{
	url = URL.init;
	// scheme:[//[user:password@]host[:port]][/]path[?query][#fragment]
	// Scheme is optional in common use. We infer 'http' if it's not given.
	auto i = value.indexOf("//");
	if (i > -1) {
		if (i > 1) {
			url.scheme = value[0..i-1];
		}
		value = value[i+2 .. $];
	} else {
		url.scheme = "http";
	}
	// Check for an ipv6 hostname.
	// [user:password@]host[:port]][/]path[?query][#fragment
	i = value.indexOfAny([':', '/', '[']);
	if (i == -1) {
		// Just a hostname.
		url.host = value.fromPuny;
		return true;
	}
	
	if (value[i] == ':') {
		// This could be between username and password, or it could be between host and port.
		auto j = value.indexOfAny(['@', '/']);
		if (j > -1 && value[j] == '@') {
			try {
				url.user = value[0..i].percentDecode;
				url.pass = value[i+1 .. j].percentDecode;
			} catch (URLException) {
				return false;
			}
			value = value[j+1 .. $];
		}
	}
	
	// It's trying to be a host/port, not a user/pass.
	i = value.indexOfAny([':', '/', '[']);
	if (i == -1) {
		url.host = value.fromPuny;
		return true;
	}
	
	// Find the hostname. It's either an ipv6 address (which has special rules) or not (which doesn't
	// have special rules). -- The main sticking point is that ipv6 addresses have colons, which we
	// handle specially, and are offset with square brackets.
	if (value[i] == '[') {
		auto j = value[i..$].indexOf(']');
		if (j < 0) {
			// unterminated ipv6 addr
			return false;
		}
		// includes square brackets
		url.host = value[i .. i+j+1];
		value = value[i+j+1 .. $];
		if (value.length == 0) {
			// read to end of string; we finished parse
			return true;
		}
		if (value[0] != ':' && value[0] != '?' && value[0] != '/') {
			return false;
		}
	} else {
		// Normal host.
		url.host = value[0..i].fromPuny;
		value = value[i .. $];
	}
	
	if (value[0] == ':') {
		auto end = value.indexOf('/');
		if (end == -1) {
			end = value.length;
		}
		try {
			url.port = value[1 .. end].to!ushort;
		} catch (ConvException) {
			return false;
		}
		value = value[end .. $];
		if (value.length == 0) {
			return true;
		}
	}
	return parsePathAndQuery(url, value);
}

private bool parsePathAndQuery(ref URL url, string value)
{
	auto i = value.indexOfAny("?#");
	if (i == -1)
	{
		url.path = value.percentDecode;
		return true;
	}
	
	try
	{
		url.path = value[0..i].percentDecode;
	}
	catch (URLException)
	{
		return false;
	}
	
	auto c = value[i];
	value = value[i + 1 .. $];
	if (c == '?')
	{
		i = value.indexOf('#');
		string query;
		if (i < 0)
		{
			query = value;
			value = null;
		}
		else
		{
			query = value[0..i];
			value = value[i + 1 .. $];
		}
		url.query = query;

		foreach(kv; query.split('&'))
		{
			auto pos = kv.indexOf('=');
			if(pos != - 1)
			{
				url.queryArr[kv[0 .. pos]] = kv[pos+1 .. $];
			}
		}
	}
	
	try
	{
		url.fragment = value.percentDecode;
	}
	catch (URLException)
	{
		return false;
	}
	
	return true;
}

unittest {
	{
		// Basic.
		URL url;
		with (url) {
			scheme = "https";
			host = "example.org";
			path = "/foo/bar";
			queryParams.add("hello", "world");
			queryParams.add("gibe", "clay");
			fragment = "frag";
		}
		assert(
			// Not sure what order it'll come out in.
			url.toString == "https://example.org/foo/bar?hello=world&gibe=clay#frag" ||
			url.toString == "https://example.org/foo/bar?gibe=clay&hello=world#frag",
			url.toString);
	}
	{
		// Percent encoded.
		URL url;
		with (url) {
			scheme = "https";
			host = "example.org";
			path = "/f☃o";
			queryParams.add("❄", "❀");
			queryParams.add("[", "]");
			fragment = "ş";
		}
		assert(
			// Not sure what order it'll come out in.
			url.toString == "https://example.org/f%E2%98%83o?%E2%9D%84=%E2%9D%80&%5B=%5D#%C5%9F" ||
			url.toString == "https://example.org/f%E2%98%83o?%5B=%5D&%E2%9D%84=%E2%9D%80#%C5%9F",
			url.toString);
	}
	{
		// Port, user, pass.
		URL url;
		with (url) {
			scheme = "https";
			host = "example.org";
			user = "dhasenan";
			pass = "itsasecret";
			port = 17;
		}
		assert(
			url.toString == "https://dhasenan:itsasecret@example.org:17/",
			url.toString);
	}
	{
		// Query with no path.
		URL url;
		with (url) {
			scheme = "https";
			host = "example.org";
			queryParams.add("hi", "bye");
		}
		assert(
			url.toString == "https://example.org/?hi=bye",
			url.toString);
	}
}

unittest
{
	auto url = "//foo/bar".parseURL;
	assert(url.host == "foo", "expected host foo, got " ~ url.host);
	assert(url.path == "/bar");
}

unittest
{
	// ipv6 hostnames!
	{
		// full range of data
		auto url = parseURL("https://bob:secret@[::1]:2771/foo/bar");
		assert(url.scheme == "https", url.scheme);
		assert(url.user == "bob", url.user);
		assert(url.pass == "secret", url.pass);
		assert(url.host == "[::1]", url.host);
		assert(url.port == 2771, url.port.to!string);
		assert(url.path == "/foo/bar", url.path);
	}
	
	// minimal
	{
		auto url = parseURL("[::1]");
		assert(url.host == "[::1]", url.host);
	}
	
	// some random bits
	{
		auto url = parseURL("http://[::1]/foo");
		assert(url.scheme == "http", url.scheme);
		assert(url.host == "[::1]", url.host);
		assert(url.path == "/foo", url.path);
	}
	
	{
		auto url = parseURL("https://[2001:0db8:0:0:0:0:1428:57ab]/?login=true#justkidding");
		assert(url.scheme == "https");
		assert(url.host == "[2001:0db8:0:0:0:0:1428:57ab]");
		assert(url.path == "/");
		assert(url.fragment == "justkidding");
	}
}

unittest
{
	auto url = "localhost:5984".parseURL;
	auto url2 = url ~ "db1";
	assert(url2.toString == "http://localhost:5984/db1", url2.toString);
	auto url3 = url2 ~ "_all_docs";
	assert(url3.toString == "http://localhost:5984/db1/_all_docs", url3.toString);
}

///
unittest {
	{
		// Basic.
		URL url;
		with (url) {
			scheme = "https";
			host = "example.org";
			path = "/foo/bar";
			queryParams.add("hello", "world");
			queryParams.add("gibe", "clay");
			fragment = "frag";
		}
		assert(
			// Not sure what order it'll come out in.
			url.toString == "https://example.org/foo/bar?hello=world&gibe=clay#frag" ||
			url.toString == "https://example.org/foo/bar?gibe=clay&hello=world#frag",
			url.toString);
	}
	{
		// Passing an array of query values.
		URL url;
		with (url) {
			scheme = "https";
			host = "example.org";
			path = "/foo/bar";
			queryParams.add("hello", "world");
			queryParams.add("hello", "aether");
			fragment = "frag";
		}
		assert(
			// Not sure what order it'll come out in.
			url.toString == "https://example.org/foo/bar?hello=world&hello=aether#frag" ||
			url.toString == "https://example.org/foo/bar?hello=aether&hello=world#frag",
			url.toString);
	}
	{
		// Percent encoded.
		URL url;
		with (url) {
			scheme = "https";
			host = "example.org";
			path = "/f☃o";
			queryParams.add("❄", "❀");
			queryParams.add("[", "]");
			fragment = "ş";
		}
		assert(
			// Not sure what order it'll come out in.
			url.toString == "https://example.org/f%E2%98%83o?%E2%9D%84=%E2%9D%80&%5B=%5D#%C5%9F" ||
			url.toString == "https://example.org/f%E2%98%83o?%5B=%5D&%E2%9D%84=%E2%9D%80#%C5%9F",
			url.toString);
	}
	{
		// Port, user, pass.
		URL url;
		with (url) {
			scheme = "https";
			host = "example.org";
			user = "dhasenan";
			pass = "itsasecret";
			port = 17;
		}
		assert(
			url.toString == "https://dhasenan:itsasecret@example.org:17/",
			url.toString);
	}
	{
		// Query with no path.
		URL url;
		with (url) {
			scheme = "https";
			host = "example.org";
			queryParams.add("hi", "bye");
		}
		assert(
			url.toString == "https://example.org/?hi=bye",
			url.toString);
	}
}

unittest {
	// Percent decoding.
	
	// http://#:!:@
	auto urlString = "http://%23:%21%3A@example.org/%7B/%7D?%3B&%26=%3D#%23hash%EF%BF%BD";
	auto url = urlString.parseURL;
	assert(url.user == "#");
	assert(url.pass == "!:");
	assert(url.host == "example.org");
	assert(url.path == "/{/}");
	assert(url.queryParams[";"].front == "");
	assert(url.queryParams["&"].front == "=");
	assert(url.fragment == "#hash�");
	
	// Round trip.
	assert(urlString == urlString.parseURL.toString, urlString.parseURL.toString);
	assert(urlString == urlString.parseURL.toString.parseURL.toString);
}

unittest {
	auto url = "https://xn--m3h.xn--n3h.org/?hi=bye".parseURL;
	assert(url.host == "☂.☃.org", url.host);
}

unittest {
	auto url = "https://☂.☃.org/?hi=bye".parseURL;
	assert(url.toString == "https://xn--m3h.xn--n3h.org/?hi=bye");
}

///
unittest {
	// There's an existing path.
	auto url = parseURL("http://example.org/foo");
	URL url2;
	// No slash? Assume it needs a slash.
	assert((url ~ "bar").toString == "http://example.org/foo/bar");
	// With slash? Don't add another.
	url2 = url ~ "/bar";
	assert(url2.toString == "http://example.org/foo/bar", url2.toString);
	url ~= "bar";
	assert(url.toString == "http://example.org/foo/bar");
	
	// Path already ends with a slash; don't add another.
	url = parseURL("http://example.org/foo/");
	assert((url ~ "bar").toString == "http://example.org/foo/bar");
	// Still don't add one even if you're appending with a slash.
	assert((url ~ "/bar").toString == "http://example.org/foo/bar");
	url ~= "/bar";
	assert(url.toString == "http://example.org/foo/bar");
	
	// No path.
	url = parseURL("http://example.org");
	assert((url ~ "bar").toString == "http://example.org/bar");
	assert((url ~ "/bar").toString == "http://example.org/bar");
	url ~= "bar";
	assert(url.toString == "http://example.org/bar");
	
	// Path is just a slash.
	url = parseURL("http://example.org/");
	assert((url ~ "bar").toString == "http://example.org/bar");
	assert((url ~ "/bar").toString == "http://example.org/bar");
	url ~= "bar";
	assert(url.toString == "http://example.org/bar", url.toString);
	
	// No path, just fragment.
	url = "ircs://irc.freenode.com/#d".parseURL;
	assert(url.toString == "ircs://irc.freenode.com/#d", url.toString);
}
unittest
{
	// basic resolve()
	{
		auto base = "https://example.org/this/".parseURL;
		assert(base.resolve("that") == "https://example.org/this/that");
		assert(base.resolve("/that") == "https://example.org/that");
		assert(base.resolve("//example.net/that") == "https://example.net/that");
	}
	
	// ensure we don't preserve query params
	{
		auto base = "https://example.org/this?query=value&other=value2".parseURL;
		assert(base.resolve("that") == "https://example.org/that");
		assert(base.resolve("/that") == "https://example.org/that");
		assert(base.resolve("tother/that") == "https://example.org/tother/that");
		assert(base.resolve("//example.net/that") == "https://example.net/that");
	}
}


unittest
{
	import std.net.curl;
	auto url = "http://example.org".parseURL;
	assert(is(typeof(std.net.curl.get(url))));
}

/**
	* Parse the input string as a URL.
	*
	* Throws:
	*   URLException if the string was in an incorrect format.
	*/
URL parseURL(string value) {
	URL url;
	if (tryParseURL(value, url)) {
		return url;
	}
	throw new URLException("failed to parse URL " ~ value);
}

///
unittest {
	{
		// Infer scheme
		auto u1 = parseURL("example.org");
		assert(u1.scheme == "http");
		assert(u1.host == "example.org");
		assert(u1.path == "");
		assert(u1.port == 80);
		assert(u1.providedPort == 0);
		assert(u1.fragment == "");
	}
	{
		// Simple host and scheme
		auto u1 = parseURL("https://example.org");
		assert(u1.scheme == "https");
		assert(u1.host == "example.org");
		assert(u1.path == "");
		assert(u1.port == 443);
		assert(u1.providedPort == 0);
	}
	{
		// With path
		auto u1 = parseURL("https://example.org/foo/bar");
		assert(u1.scheme == "https");
		assert(u1.host == "example.org");
		assert(u1.path == "/foo/bar", "expected /foo/bar but got " ~ u1.path);
		assert(u1.port == 443);
		assert(u1.providedPort == 0);
	}
	{
		// With explicit port
		auto u1 = parseURL("https://example.org:1021/foo/bar");
		assert(u1.scheme == "https");
		assert(u1.host == "example.org");
		assert(u1.path == "/foo/bar", "expected /foo/bar but got " ~ u1.path);
		assert(u1.port == 1021);
		assert(u1.providedPort == 1021);
	}
	{
		// With user
		auto u1 = parseURL("https://bob:secret@example.org/foo/bar");
		assert(u1.scheme == "https");
		assert(u1.host == "example.org");
		assert(u1.path == "/foo/bar");
		assert(u1.port == 443);
		assert(u1.user == "bob");
		assert(u1.pass == "secret");
	}
	{
		// With user, URL-encoded
		auto u1 = parseURL("https://bob%21:secret%21%3F@example.org/foo/bar");
		assert(u1.scheme == "https");
		assert(u1.host == "example.org");
		assert(u1.path == "/foo/bar");
		assert(u1.port == 443);
		assert(u1.user == "bob!");
		assert(u1.pass == "secret!?");
	}
	{
		// With user and port and path
		auto u1 = parseURL("https://bob:secret@example.org:2210/foo/bar");
		assert(u1.scheme == "https");
		assert(u1.host == "example.org");
		assert(u1.path == "/foo/bar");
		assert(u1.port == 2210);
		assert(u1.user == "bob");
		assert(u1.pass == "secret");
		assert(u1.fragment == "");
	}
	{
		// With query string
		auto u1 = parseURL("https://example.org/?login=true");
		assert(u1.scheme == "https");
		assert(u1.host == "example.org");
		assert(u1.path == "/", "expected path: / actual path: " ~ u1.path);
		assert(u1.queryParams["login"].front == "true");
		assert(u1.fragment == "");
	}
	{
		// With query string and fragment
		auto u1 = parseURL("https://example.org/?login=true#justkidding");
		assert(u1.scheme == "https");
		assert(u1.host == "example.org");
		assert(u1.path == "/", "expected path: / actual path: " ~ u1.path);
		assert(u1.queryParams["login"].front == "true");
		assert(u1.fragment == "justkidding");
	}
	{
		// With URL-encoded values
		auto u1 = parseURL("https://example.org/%E2%98%83?%E2%9D%84=%3D#%5E");
		assert(u1.scheme == "https");
		assert(u1.host == "example.org");
		assert(u1.path == "/☃", "expected path: /☃ actual path: " ~ u1.path);
		assert(u1.queryParams["❄"].front == "=");
		assert(u1.fragment == "^");
	}
}

unittest {
	assert(parseURL("http://example.org").port == 80);
	assert(parseURL("http://example.org:5326").port == 5326);
	
	auto url = parseURL("redis://admin:password@redisbox.local:2201/path?query=value#fragment");
	assert(url.scheme == "redis");
	assert(url.user == "admin");
	assert(url.pass == "password");
	
	assert(parseURL("example.org").toString == "http://example.org/");
	assert(parseURL("http://example.org:80").toString == "http://example.org/");
	
	assert(parseURL("localhost:8070").toString == "http://localhost:8070/");
}

/**
	* Percent-encode a string.
	*
	* URL components cannot contain non-ASCII characters, and there are very few characters that are
	* safe to include as URL components. Domain names using Unicode values use Punycode. For
	* everything else, there is percent encoding.
	*/
string percentEncode(string raw) {
	// We *must* encode these characters: :/?#[]@!$&'()*+,;="
	// We *can* encode any other characters.
	// We *should not* encode alpha, numeric, or -._~.
	import std.utf : encode;
	import std.array : Appender;
	Appender!string app;
	foreach (dchar d; raw) {
		if (('a' <= d && 'z' >= d) ||
			('A' <= d && 'Z' >= d) ||
			('0' <= d && '9' >= d) ||
			d == '-' || d == '.' || d == '_' || d == '~') {
			app ~= d;
			continue;
		}
		// Something simple like a space character? Still in 7-bit ASCII?
		// Then we get a single-character string out of it and just encode
		// that one bit.
		// Something not in 7-bit ASCII? Then we percent-encode each octet
		// in the UTF-8 encoding (and hope the server understands UTF-8).
		char[] c;
		encode(c, d);
		auto bytes = cast(ubyte[])c;
		foreach (b; bytes) {
			app ~= format("%%%02X", b);
		}
	}
	return cast(string)app.data;
}

///
unittest {
	assert(percentEncode("IDontNeedNoPercentEncoding") == "IDontNeedNoPercentEncoding");
	assert(percentEncode("~~--..__") == "~~--..__");
	assert(percentEncode("0123456789") == "0123456789");
	
	string e;
	
	e = percentEncode("☃");
	assert(e == "%E2%98%83", "expected %E2%98%83 but got" ~ e);
}

/**
	* Percent-decode a string.
	*
	* URL components cannot contain non-ASCII characters, and there are very few characters that are
	* safe to include as URL components. Domain names using Unicode values use Punycode. For
	* everything else, there is percent encoding.
	*
	* This explicitly ensures that the result is a valid UTF-8 string.
	*/
string percentDecode(string encoded)
{
	import std.utf : validate, UTFException;
	auto raw = percentDecodeRaw(encoded);
	auto s = cast(string) raw;
	try
	{
		validate(s);
	}
	catch (UTFException e)
	{
		throw new URLException(
			"The percent-encoded data `" ~ encoded ~ "` does not represent a valid UTF-8 sequence.");
	}
	return s;
}

///
unittest {
	assert(percentDecode("IDontNeedNoPercentDecoding") == "IDontNeedNoPercentDecoding");
	assert(percentDecode("~~--..__") == "~~--..__");
	assert(percentDecode("0123456789") == "0123456789");
	
	string e;
	
	e = percentDecode("%E2%98%83");
	assert(e == "☃", "expected a snowman but got" ~ e);
	
	e = percentDecode("%e2%98%83");
	assert(e == "☃", "expected a snowman but got" ~ e);
	
	try {
		// %ES is an invalid percent sequence: 'S' is not a hex digit.
		percentDecode("%es");
		assert(false, "expected exception not thrown");
	} catch (URLException) {
	}
	
	try {
		percentDecode("%e");
		assert(false, "expected exception not thrown");
	} catch (URLException) {
	}
}

/**
	* Percent-decode a string into a ubyte array.
	*
	* URL components cannot contain non-ASCII characters, and there are very few characters that are
	* safe to include as URL components. Domain names using Unicode values use Punycode. For
	* everything else, there is percent encoding.
	*
	* This yields a ubyte array and will not perform validation on the output. However, an improperly
	* formatted input string will result in a URLException.
	*/
immutable(ubyte)[] percentDecodeRaw(string encoded)
{
	// We're dealing with possibly incorrectly encoded UTF-8. Mark it down as ubyte[] for now.
	import std.array : Appender;
	Appender!(immutable(ubyte)[]) app;
	for (int i = 0; i < encoded.length; i++) {
		if (encoded[i] != '%') {
			app ~= encoded[i];
			continue;
		}
		if (i >= encoded.length - 2) {
			throw new URLException("Invalid percent encoded value: expected two characters after " ~
				"percent symbol. Error at index " ~ i.to!string);
		}
		if (isHex(encoded[i + 1]) && isHex(encoded[i + 2])) {
			auto b = fromHex(encoded[i + 1]);
			auto c = fromHex(encoded[i + 2]);
			app ~= cast(ubyte)((b << 4) | c);
		} else {
			throw new URLException("Invalid percent encoded value: expected two hex digits after " ~
				"percent symbol. Error at index " ~ i.to!string);
		}
		i += 2;
	}
	return app.data;
}

private bool isHex(char c) {
	return ('0' <= c && '9' >= c) ||
		('a' <= c && 'f' >= c) ||
			('A' <= c && 'F' >= c);
}

private ubyte fromHex(char s) {
	enum caseDiff = 'a' - 'A';
	if (s >= 'a' && s <= 'z') {
		s -= caseDiff;
	}
	return cast(ubyte)("0123456789ABCDEF".indexOf(s));
}

private string toPuny(string unicodeHostname)
{
	if (unicodeHostname[0] == '[')
	{
		// It's an ipv6 name.
		return unicodeHostname;
	}
	bool mustEncode = false;
	foreach (i, dchar d; unicodeHostname) {
		auto c = cast(uint) d;
		if (c > 0x80) {
			mustEncode = true;
			break;
		}
		if (c < 0x2C || (c >= 0x3A && c <= 40) || (c >= 0x5B && c <= 0x60) || (c >= 0x7B)) {
			throw new URLException(
				format(
					"domain name '%s' contains illegal character '%s' at position %s",
					unicodeHostname, d, i));
		}
	}
	if (!mustEncode) {
		return unicodeHostname;
	}
	import std.algorithm.iteration : map;
	return unicodeHostname.split('.').map!punyEncode.join(".");
}

private string fromPuny(string hostname)
{
	import std.algorithm.iteration : map;
	return hostname.split('.').map!punyDecode.join(".");
}

private {
	enum delimiter = '-';
	enum marker = "xn--";
	enum ulong damp = 700;
	enum ulong tmin = 1;
	enum ulong tmax = 26;
	enum ulong skew = 38;
	enum ulong base = 36;
	enum ulong initialBias = 72;
	enum dchar initialN = cast(dchar)128;
	
	ulong adapt(ulong delta, ulong numPoints, bool firstTime) {
		if (firstTime) {
			delta /= damp;
		} else {
			delta /= 2;
		}
		delta += delta / numPoints;
		ulong k = 0;
		while (delta > ((base - tmin) * tmax) / 2) {
			delta /= (base - tmin);
			k += base;
		}
		return k + (((base - tmin + 1) * delta) / (delta + skew));
	}
}

/**
	* Encode the input string using the Punycode algorithm.
	*
	* Punycode is used to encode UTF domain name segment. A Punycode-encoded segment will be marked
	* with "xn--". Each segment is encoded separately. For instance, if you wish to encode "☂.☃.com"
	* in Punycode, you will get "xn--m3h.xn--n3h.com".
	*
	* In order to puny-encode a domain name, you must split it into its components. The following will
	* typically suffice:
	* ---
	* auto domain = "☂.☃.com";
	* auto encodedDomain = domain.splitter(".").map!(punyEncode).join(".");
	* ---
	*/
string punyEncode(string input)
{
	import std.array : Appender;
	ulong delta = 0;
	dchar n = initialN;
	auto i = 0;
	auto bias = initialBias;
	Appender!string output;
	output ~= marker;
	auto pushed = 0;
	auto codePoints = 0;
	foreach (dchar c; input) {
		codePoints++;
		if (c <= initialN) {
			output ~= c;
			pushed++;
		}
	}
	if (pushed < codePoints) {
		if (pushed > 0) {
			output ~= delimiter;
		}
	} else {
		// No encoding to do.
		return input;
	}
	bool first = true;
	while (pushed < codePoints) {
		auto best = dchar.max;
		foreach (dchar c; input) {
			if (n <= c && c < best) {
				best = c;
			}
		}
		if (best == dchar.max) {
			throw new URLException("failed to find a new codepoint to process during punyencode");
		}
		delta += (best - n) * (pushed + 1);
		if (delta > uint.max) {
			// TODO better error message
			throw new URLException("overflow during punyencode");
		}
		n = best;
		foreach (dchar c; input) {
			if (c < n) {
				delta++;
			}
			if (c == n) {
				ulong q = delta;
				auto k = base;
				while (true) {
					ulong t;
					if (k <= bias) {
						t = tmin;
					} else if (k >= bias + tmax) {
						t = tmax;
					} else {
						t = k - bias;
					}
					if (q < t) {
						break;
					}
					output ~= digitToBasic(t + ((q - t) % (base - t)));
					q = (q - t) / (base - t);
					k += base;
				}
				output ~= digitToBasic(q);
				pushed++;
				bias = adapt(delta, pushed, first);
				first = false;
				delta = 0;
			}
		}
		delta++;
		n++;
	}
	return cast(string)output.data;
}

/**
	* Decode the input string using the Punycode algorithm.
	*
	* Punycode is used to encode UTF domain name segment. A Punycode-encoded segment will be marked
	* with "xn--". Each segment is encoded separately. For instance, if you wish to encode "☂.☃.com"
	* in Punycode, you will get "xn--m3h.xn--n3h.com".
	*
	* In order to puny-decode a domain name, you must split it into its components. The following will
	* typically suffice:
	* ---
	* auto domain = "xn--m3h.xn--n3h.com";
	* auto decodedDomain = domain.splitter(".").map!(punyDecode).join(".");
	* ---
	*/
string punyDecode(string input) {
	if (!input.startsWith(marker)) {
		return input;
	}
	input = input[marker.length..$];
	
	// let n = initial_n
	dchar n = cast(dchar)128;
	
	// let i = 0
	// let bias = initial_bias
	// let output = an empty string indexed from 0
	size_t i = 0;
	auto bias = initialBias;
	dchar[] output;
	// This reserves a bit more than necessary, but it should be more efficient overall than just
	// appending and inserting volo-nolo.
	output.reserve(input.length);
	
	// consume all code points before the last delimiter (if there is one)
	//   and copy them to output, fail on any non-basic code point
	// if more than zero code points were consumed then consume one more
	//   (which will be the last delimiter)
	auto end = input.lastIndexOf(delimiter);
	if (end > -1) {
		foreach (dchar c; input[0..end]) {
			output ~= c;
		}
		input = input[end+1 .. $];
	}
	
	// while the input is not exhausted do begin
	size_t pos = 0;
	while (pos < input.length) {
		//   let oldi = i
		//   let w = 1
		auto oldi = i;
		auto w = 1;
		//   for k = base to infinity in steps of base do begin
		for (ulong k = base; k < uint.max; k += base) {
			//     consume a code point, or fail if there was none to consume
			// Note that the input is all ASCII, so we can simply index the input string bytewise.
			auto c = input[pos];
			pos++;
			//     let digit = the code point's digit-value, fail if it has none
			auto digit = basicToDigit(c);
			//     let i = i + digit * w, fail on overflow
			i += digit * w;
			//     let t = tmin if k <= bias {+ tmin}, or
			//             tmax if k >= bias + tmax, or k - bias otherwise
			ulong t;
			if (k <= bias) {
				t = tmin;
			} else if (k >= bias + tmax) {
				t = tmax;
			} else {
				t = k - bias;
			}
			//     if digit < t then break
			if (digit < t) {
				break;
			}
			//     let w = w * (base - t), fail on overflow
			w *= (base - t);
			//   end
		}
		//   let bias = adapt(i - oldi, length(output) + 1, test oldi is 0?)
		bias = adapt(i - oldi, output.length + 1, oldi == 0);
		//   let n = n + i div (length(output) + 1), fail on overflow
		n += i / (output.length + 1);
		//   let i = i mod (length(output) + 1)
		i %= (output.length + 1);
		//   {if n is a basic code point then fail}
		// (We aren't actually going to fail here; it's clear what this means.)
		//   insert n into output at position i
		import std.array : insertInPlace;
		(() @trusted { output.insertInPlace(i, cast(dchar)n); })();  // should be @safe but isn't marked
		//   increment i
		i++;
		// end
	}
	return output.to!string;
}

// Lifted from punycode.js.
private dchar digitToBasic(ulong digit) {
	return cast(dchar)(digit + 22 + 75 * (digit < 26));
}

// Lifted from punycode.js.
private uint basicToDigit(char c) {
	auto codePoint = cast(uint)c;
	if (codePoint - 48 < 10) {
		return codePoint - 22;
	}
	if (codePoint - 65 < 26) {
		return codePoint - 65;
	}
	if (codePoint - 97 < 26) {
		return codePoint - 97;
	}
	return base;
}

unittest {
	{
		auto a = "b\u00FCcher";
		assert(punyEncode(a) == "xn--bcher-kva");
	}
	{
		auto a = "b\u00FCc\u00FCher";
		assert(punyEncode(a) == "xn--bcher-kvab");
	}
	{
		auto a = "ýbücher";
		auto b = punyEncode(a);
		assert(b == "xn--bcher-kvaf", b);
	}
	
	{
		auto a = "mañana";
		assert(punyEncode(a) == "xn--maana-pta");
	}
	
	{
		auto a = "\u0644\u064A\u0647\u0645\u0627\u0628\u062A\u0643\u0644"
			~ "\u0645\u0648\u0634\u0639\u0631\u0628\u064A\u061F";
		auto b = punyEncode(a);
		assert(b == "xn--egbpdaj6bu4bxfgehfvwxn", b);
	}
	import std.stdio;
}

unittest {
	{
		auto b = punyDecode("xn--egbpdaj6bu4bxfgehfvwxn");
		assert(b == "ليهمابتكلموشعربي؟", b);
	}
	{
		assert(punyDecode("xn--maana-pta") == "mañana");
	}
}

unittest {
	import std.string, std.algorithm, std.array, std.range;
	{
		auto domain = "xn--m3h.xn--n3h.com";
		auto decodedDomain = domain.splitter(".").map!(punyDecode).join(".");
		assert(decodedDomain == "☂.☃.com", decodedDomain);
	}
	{
		auto domain = "☂.☃.com";
		auto decodedDomain = domain.splitter(".").map!(punyEncode).join(".");
		assert(decodedDomain == "xn--m3h.xn--n3h.com", decodedDomain);
	}
}

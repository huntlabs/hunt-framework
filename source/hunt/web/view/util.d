/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
 *
 * Copyright (C) 2015-2016  Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the BSD License.
 *
 */
module hunt.web.view.util;

private import std.algorithm, std.typecons, std.array, std.uni, std.conv,
    std.utf;

private import hunt.web.view.delims;

package:

bool validBeforeShort(string str)
{
    // Check that the tail of str is whitespace
    // before a newline, or nothing.
    foreach_reverse (dchar chr; str)
    {
        if (chr == '\n')
        {
            return true;
        }
        if (!chr.isWhite())
        {
            return false;
        }
    }
    return true;
}

unittest
{
    static assert("   ".validBeforeShort());
    static assert(" \t".validBeforeShort());
    static assert("foo\n".validBeforeShort());
    static assert("foo\n  ".validBeforeShort());
    static assert("foo\n  \t".validBeforeShort);

    static assert("foo  \t".validBeforeShort() == false);
    static assert("foo".validBeforeShort() == false);
    static assert("\nfoo".validBeforeShort() == false);
}

void munchHeadOf(ref string a, ref string b, size_t amt)
{
    // Transfers amt of b's head onto a's tail
    a = a ~ b[0 .. amt];
    b = b[amt .. $];
}

unittest
{
    auto a = "123";
    auto b = "abc";
    a.munchHeadOf(b, 1);
    assert(a == "123a");
    assert(b == "bc");
}

unittest
{
    auto a = "123";
    auto b = "abc";
    a.munchHeadOf(b, b.length);
    assert(a == "123abc");
    assert(b == "");
}

/// Returns the next matching delimeter in 'delims' found in the haystack,
/// or null
DelimPos!(D)* nextDelim(D)(string haystack, const(D)[] delims) if (is(D : Delim))
{
    alias DelimStrPair = Tuple!(Delim, "delim", string, "str");

    /// The foreach is there to get around some DMD bugs
    /// Preferrably, one of the next two lines would be used instead
    //auto delims_strs =      delims.map!(a => new DelimStrPair(a, a.toString()) )().array();
    //auto delim_strs  = delims_strs.map!(a => a.str)().array();
    DelimStrPair[] delims_strs;
    foreach (delim; delims)
    {
        delims_strs ~= DelimStrPair(delim, toString(delim));
    }

    // Map delims into their string representations
    // e.g. OpenDelim.OpenStr => `<%=`
    string[] delim_strs;
    foreach (delim; delims)
    {
        // BUG: Would use ~= here, but CTFE in 2.063 can't handle it
        delim_strs = delim_strs ~ toString(delim);
    }

    // Find the first occurance of any of the delimers in the haystack
    immutable index = countUntilAny(haystack, delim_strs);
    if (index == -1)
    {
        return null;
    }

    // Jump to where the delim is on haystack, using stride to handle
    // unicode correctly
    size_t pos = 0;
    foreach (_; 0 .. index)
    {
        auto size = stride(haystack, 0);

        haystack = haystack[size .. $];
        pos += size;
    }

    // Make sure that we match the longest of the delimers first,
    // e.g. `<%=` is matched before `<%` for maximal munch
    auto sorted = delims_strs.sort!("a.str.length > b.str.length")();
    foreach (s; sorted)
    {
        if (startsWith(haystack, s.str))
        {
            return new DelimPos!D(pos, cast(D) s.delim);
        }
    }

    // invariant
    assert(false, "internal bug: \natPos: " ~ index.to!string ~ "\nhaystack: " ~ haystack);
}

unittest
{
    const haystack = "% Я";
    static assert(*(haystack.nextDelim([Delim.OpenShort])) == DelimPos!Delim(0, Delim.OpenShort));
}

unittest
{
    const haystack = "Я";
    static assert(haystack.nextDelim([Delim.OpenShort]) == null);
}

unittest
{
    const haystack = "Я%";
    static assert(
        *(haystack.nextDelim([Delim.OpenShort])) == DelimPos!Delim(
        codeLength!char('Я'), Delim.OpenShort));
}

unittest
{
    const haystack = Delim.Open.toString();
    static assert(*(haystack.nextDelim([Delim.Open])) == DelimPos!Delim(0, Delim.Open));
}

unittest
{
    const haystack = "foo";
    static assert(haystack.nextDelim([Delim.Open]) is null);
}

/// Returns the location of the first occurance of any of 'subs' found in
/// haystack, or -1 if none are found
ptrdiff_t countUntilAny(string haystack, string[] subs)
{
    // First, calculate first occurance for all subs
    auto indexes_of = subs.map!(sub => haystack.countUntil(sub));
    ptrdiff_t min_index = -1;

    // Then find smallest index that isn't -1
    foreach (index_of; indexes_of)
    {
        if (index_of != -1)
        {
            if (min_index == -1)
            {
                min_index = index_of;
            }
            else
            {
                min_index = min(min_index, index_of);
            }
        }
    }

    return min_index;
}

unittest
{
    enum a = "1, 2, 3, 4";
    static assert(a.countUntilAny(["1", "2"]) == 0);
    static assert(a.countUntilAny(["2", "1"]) == 0);
    static assert(a.countUntilAny(["4", "2"]) == 3);
}

unittest
{
    enum a = "1, 2, 3, 4";
    static assert(a.countUntilAny(["5", "1"]) == 0);
    static assert(a.countUntilAny(["5", "6"]) == -1);
}

unittest
{
    enum a = "%>";
    static assert(a.countUntilAny(["<%", "<%="]) == -1);
}

string escapeQuotes(string unclean)
{
    unclean = unclean.replace(`"`, `\"`);
    unclean = unclean.replace(`'`, `\'`);
    return unclean;
}

unittest
{
    static assert(escapeQuotes(`"`) == `\"`);
    static assert(escapeQuotes(`'`) == `\'`);
}

// Internal, inefficiant function for removing the whitespace from
// a string (for comparing that templates generate the same output,
// ignoring whitespace exactnes)
string stripWs(string unclean)
{
    return unclean.filter!(a => !isWhite(a)).map!(a => cast(char) a).array.idup;
}

unittest
{
    static assert(stripWs("") == "");
    static assert(stripWs("    \t") == "");
    static assert(stripWs(" a s d f ") == "asdf");
    static assert(stripWs(" a\ns\rd f ") == "asdf");
}

// Checks if haystack ends with needle, ignoring the whitespace in either
// of them
bool endsWithIgnoreWhitespace(string haystack, string needle)
{
    haystack = haystack.stripWs;
    needle = needle.stripWs;

    return haystack.endsWith(needle);
}

unittest
{
    static assert(endsWithIgnoreWhitespace(")   {  ", "){"));
    static assert(!endsWithIgnoreWhitespace(")   {}", "){"));
}

bool startsWithBlockClose(string haystack)
{
    haystack = haystack.stripWs;

    // something that looks like }<something>); passes this
    if (haystack.startsWith("}") && haystack.canFind(");"))
        return true;
    return false;
}

unittest
{
    static assert(startsWithBlockClose(`}, 10);`));
    static assert(startsWithBlockClose(`});`));
    static assert(startsWithBlockClose(`}, "foo");`));
    static assert(startsWithBlockClose(`}); auto a = "foo";`));

    static assert(!startsWithBlockClose(`if() {}`));
    static assert(!startsWithBlockClose(`};`));
}

bool isBlockStart(string haystack)
{
    return haystack.endsWithIgnoreWhitespace("){");
}

bool isBlockEnd(string haystack)
{
    return haystack.startsWithBlockClose();
}

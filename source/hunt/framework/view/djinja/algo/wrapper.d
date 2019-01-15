/**
  * Wrapper for translating Jinja calls into native D function calls
  *
  * Copyright:
  *     Copyright (c) 2018, Maxim Tyapkin.
  * Authors:
  *     Maxim Tyapkin
  * License:
  *     This software is licensed under the terms of the BSD 3-clause license.
  *     The full terms of the license can be found in the LICENSE.md file.
  */

module hunt.framework.view.djinja.algo.wrapper;

private
{
    import std.algorithm : min;
    import std.format : fmt = format;
    import std.functional : toDelegate;
    import std.traits;
    import std.typecons : Tuple;
    import std.string : join;

    import hunt.framework.view.djinja.exception : assertJinja = assertJinjaException;
    import hunt.framework.view.djinja.uninode;
}


alias Function = UniNode delegate(UniNode);


template wrapper(alias F)
    if (isSomeFunction!F)
{
    alias ParameterIdents = ParameterIdentifierTuple!F;
    alias ParameterTypes = Parameters!F;
    alias ParameterDefs = ParameterDefaults!F;
    alias RT = ReturnType!F;
    alias PT = Tuple!ParameterTypes;


    Function wrapper()
    {
        UniNode func (UniNode params)
        {
            assertJinja(params.kind == UniNode.Kind.object, "Non object params");
            assertJinja(cast(bool)("varargs" in params), "Missing varargs in params");
            assertJinja(cast(bool)("kwargs" in params), "Missing kwargs in params");

            bool[string] filled;
            PT args;

            foreach(i, def; ParameterDefs)
            {
                alias key = ParameterIdents[i];
                static if (key == "varargs")
                    args[i] = UniNode.emptyArray;
                else static if (key == "kwargs")
                    args[i] = UniNode.emptyObject;
                else static if (!is(def == void))
                    args[i] = def;
                else
                    filled[key] = false;
            }

            void fillArg(size_t idx, PType)(string key, UniNode val)
            {
                // TODO toBoolType, toStringType
                try
                    args[idx] = val.deserialize!PType;
                catch
                    assertJinja(0, "Can't deserialize param `%s` from `%s` to `%s` in function `%s`"
                                            .fmt(key, val.kind, PType.stringof, fullyQualifiedName!F));
            }

            UniNode varargs = UniNode.emptyArray;
            UniNode kwargs = UniNode.emptyObject;

            bool isVarargs = false;
            int varargsFilled = 0;
            static foreach (int i; 0 .. PT.length)
            {
                static if (ParameterIdents[i] == "varargs" || ParameterIdents[i] == "kwargs")
                {
                    isVarargs = true;
                }
                if (params["varargs"].length > i)
                {
                    if (!isVarargs)
                    {
                        fillArg!(i, ParameterTypes[i])(ParameterIdents[i], params["varargs"][i]);
                        filled[ParameterIdents[i]] = true;
                    }
                    else
                        varargs ~= params["varargs"][i];
                    varargsFilled++;
                }
            }
            // Filled missed varargs
            if (varargsFilled < params["varargs"].length)
                foreach(i; varargsFilled .. params["varargs"].length)
                    varargs ~= params["varargs"][i];

            bool[string] kwargsFilled;
            static foreach(i, key; ParameterIdents)
            {
                if (key in params["kwargs"])
                {
                    fillArg!(i, ParameterTypes[i])(key, params["kwargs"][key]);
                    filled[ParameterIdents[i]] = true;
                    kwargsFilled[key] = true;
                }
            }
            // Filled missed kwargs
            foreach (string key, ref UniNode val; params["kwargs"])
            {
                if (key !in kwargsFilled)
                    kwargs[key] = val;
            }

            // Fill varargs/kwargs
            foreach(i, key; ParameterIdents)
            {
                static if (key == "varargs")
                    args[i] = varargs;
                else static if (key == "kwargs")
                    args[i] = kwargs;
            }

            string[] missedArgs = [];
            foreach(key, val; filled)
                if (!val)
                    missedArgs ~= key;

            if (missedArgs.length)
                assertJinja(0, "Missed values for args `%s`".fmt(missedArgs.join(", ")));

            static if (is (RT == void))
            {
                F(args.expand);
                return UniNode(null);
            }
            else
            {
                auto ret = F(args.expand);
                return ret.serialize!RT;
            }
        }

        return toDelegate(&func);
    }
}

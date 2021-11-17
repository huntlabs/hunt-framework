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

module hunt.framework.view.algo.Wrapper;

private
{
    import std.algorithm : min;
    import std.format : fmt = format;
    import std.functional : toDelegate;
    import std.traits;
    import std.typecons : Tuple;
    import std.string : join;

    import hunt.framework.view.Exception : assertTemplate = assertTemplateException;
    import hunt.framework.view.Uninode;
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
            assertTemplate(params.kind == UniNode.Kind.object, "Non object params");
            assertTemplate(cast(bool)("varargs" in params), "Missing varargs in params");
            assertTemplate(cast(bool)("kwargs" in params), "Missing kwargs in params");

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
                try {
                    args[idx] = val.deserialize!PType;
                } catch(Exception) {
                    assertTemplate(0, "Can't deserialize param `%s` from `%s` to `%s` in function `%s`"
                                            .fmt(key, val.kind, PType.stringof, fullyQualifiedName!F));
                }
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
                assertTemplate(0, "Missed values for args `%s`".fmt(missedArgs.join(", ")));

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

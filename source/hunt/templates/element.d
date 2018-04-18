module hunt.templates.element;

import std.string;
import std.variant;
import std.json;
import hunt.templates.rule;

class Element
{
    Type type;
    string inner;
    Element[] children;

    this(const Type mtype)
    {
        type = mtype;
    }

    this(const Type mtype, const string minner)
    {
        type = mtype;
        inner = minner;
    }
};

class ElementString : Element
{
    string text;

    this(const string mtext)
    {
        super(Type.String);
        text = mtext;
    }
};

class ElementComment : Element
{
    string text;

    this(const string mtext)
    {
        super(Type.Comment);
        text = mtext;
    }
};

class ElementExpression : Element
{
    Function func;
    ElementExpression[] args;
    string command;
    JSONValue result;

    this()
    {
        super(Type.Expression);
        func = Function.ReadJson;
    }

    this(const Function function_)
    {
        super(Type.Expression);
        func = function_;
    }
};

class ElementLoop : Element
{
    Loop loop;
    string key;
    string value;
    ElementExpression list;

    this(const Loop loop_, const string mvalue, ElementExpression mlist, const string inner)
    {
        super(Type.Loop, inner);
        loop = loop_;
        value = mvalue;
        list = mlist;
    }

    this(const Loop loop_, const string mkey, const string mvalue,
            ElementExpression mlist, string inner)
    {
        super(Type.Loop, inner);
        loop = loop_;
        key = mkey;
        value = mvalue;
        list = mlist;
    }
};

class ElementConditionContainer : Element
{
    this()
    {
        super(Type.Condition);
    }
};

class ElementConditionBranch : Element
{
    Condition condition_type;
    ElementExpression condition;

    this(const string inner, const Condition m_condition_type)
    {
        super(Type.ConditionBranch, inner);
        condition_type = m_condition_type;
        condition = new ElementExpression();
    }

    this(const string inner, const Condition m_condition_type, ElementExpression m_condition)
    {
        super(Type.ConditionBranch, inner);
        condition_type = m_condition_type;
        condition = m_condition;
    }
};

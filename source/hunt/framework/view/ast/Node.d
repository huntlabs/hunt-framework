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

module hunt.framework.view.ast.Node;

public
{
    import std.typecons : Nullable, nullable;
    import hunt.framework.view.Lexer : Position;
}

private
{
    import std.meta : AliasSeq;

    import hunt.framework.view.ast.Visitor;
}


alias NodeTypes = AliasSeq!(
        TemplateNode,
        BlockNode,
        StmtBlockNode,
        RawNode,
        ExprNode,
        UnaryOpNode,
        BinOpNode,
        StringNode,
        BooleanNode,
        NilNode,
        ListNode,
        DictNode,
        NumNode,
        IdentNode,
        IfNode,
        ForNode,
        SetNode,
        AssignableNode,
        MacroNode,
        CallNode,
        InlineIfNode,
        FilterBlockNode,
        ImportNode,
        IncludeNode,
        ExtendsNode,
    );



interface NodeInterface
{
    void accept(VisitorInterface);
}


mixin template AcceptVisitor()
{
    override void accept(VisitorInterface visitor)
    {
        visitor.visit(this);
    }
}


abstract class Node : NodeInterface
{
    public Position pos;

    void accept(VisitorInterface visitor) {}
}


class TemplateNode : Node
{
    Nullable!StmtBlockNode stmt;
    BlockNode[string] blocks;

    this(Position pos, StmtBlockNode stmt, BlockNode[string] blocks)
    {
        this.pos = pos;
        this.stmt = stmt.toNullable;
        this.blocks = blocks;
    }

    mixin AcceptVisitor;
}



class BlockNode : Node
{
    string name;
    Nullable!Node stmt;

    this(Position pos, string name, Node stmt)
    {
        this.pos = pos;
        this.name = name;
        this.stmt = stmt.toNullable;
    }

    mixin AcceptVisitor;
}



class StmtBlockNode : Node
{
    Node[] children;

    this(Position pos)
    {
        this.pos = pos;
    }

    mixin AcceptVisitor;
}



class RawNode : Node
{
    string raw;

    this(Position pos, string raw)
    {
        this.pos = pos;
        this.raw = raw;
    }

    mixin AcceptVisitor;
}



class ExprNode : Node
{
    Nullable!Node expr;

    this(Position pos, Node expr)
    {
        this.pos = pos;
        this.expr = expr.toNullable;
    }

    mixin AcceptVisitor;
}


class InlineIfNode : Node
{
    Nullable!Node expr, cond, other;

    this(Position pos, Node expr, Node cond, Node other)
    {
        this.pos = pos;
        this.expr = expr.toNullable;
        this.cond = cond.toNullable;
        this.other = other.toNullable;
    }

    mixin AcceptVisitor;
}


class BinOpNode : Node
{
    string op;
    Node lhs, rhs;

    this(Position pos, string op, Node lhs, Node rhs)
    {
        this.pos = pos;
        this.op = op;
        this.lhs = lhs;
        this.rhs = rhs;
    }

    mixin AcceptVisitor;
}


class UnaryOpNode : Node
{
    string op;
    Node expr;

    this(Position pos, string op, Node expr)
    {
        this.pos = pos;
        this.op = op;
        this.expr = expr;
    }

    mixin AcceptVisitor;
}


class NumNode : Node
{
    enum Type
    {
        Integer,
        Float,
    }

    union Data
    {
        long _integer;
        double _float;
    }

    Data data;
    Type type;

    this(Position pos, long num)
    {
        this.pos = pos;
        data._integer = num;
        type = Type.Integer;
    }

    this(Position pos, double num)
    {
        this.pos = pos;
        data._float = num;
        type = Type.Float;
    }

    mixin AcceptVisitor;
}


class BooleanNode : Node
{
    bool boolean;

    this(Position pos, bool boolean)
    {
        this.pos = pos;
        this.boolean = boolean;
    }

    mixin AcceptVisitor;
}


class NilNode : Node
{
    mixin AcceptVisitor;
}


class IdentNode : Node
{
    string name;
    Node[] subIdents;


    this(Position pos, string name, Node[] subIdents)
    {
        this.pos = pos;
        this.name = name;
        this.subIdents = subIdents;
    }

    mixin AcceptVisitor;
}


class AssignableNode : Node
{
    string name;
    Node[] subIdents;


    this(Position pos, string name, Node[] subIdents)
    {
        this.pos = pos;
        this.name = name;
        this.subIdents = subIdents;
    }

    mixin AcceptVisitor;
}


class IfNode : Node
{
    Node cond, then, other;

    this(Position pos, Node cond, Node then, Node other)
    {
        this.pos = pos;
        this.cond = cond;
        this.then = then;
        this.other = other;
    }

    mixin AcceptVisitor;
}


class ForNode : Node
{
    string[] keys;
    Nullable!Node iterable;
    Nullable!Node block;
    Nullable!Node other;
    Nullable!Node cond;
    bool isRecursive;

    this(Position pos, string[] keys, Node iterable, Node block, Node other, Node cond, bool isRecursive)
    {
        this.pos = pos;
        this.keys = keys;
        this.iterable = iterable.toNullable;
        this.block = block.toNullable;
        this.other = other.toNullable;
        this.cond = cond.toNullable;
        this.isRecursive = isRecursive;
    }

    mixin AcceptVisitor;
}


class StringNode : Node
{
    string str;

    this(Position pos, string str)
    {
        this.pos = pos;
        this.str = str;
    }

    mixin AcceptVisitor;
}


class ListNode : Node
{
    Node[] list;

    this(Position pos, Node[] list)
    {
        this.pos = pos;
        this.list = list;
    }

    mixin AcceptVisitor;
}


class DictNode : Node
{
    Node[string] dict;

    this(Position pos, Node[string] dict)
    {
        this.pos = pos;
        this.dict = dict;
    }

    mixin AcceptVisitor;
}


class SetNode : Node
{
    Node[] assigns;
    Node expr;

    this(Position pos, Node[] assigns, Node expr)
    {
        this.pos = pos;
        this.assigns = assigns;
        this.expr = expr;
    }

    mixin AcceptVisitor;
}


class MacroNode : Node
{
    string name;
    Arg[] args;
    Nullable!Node block;
    bool isReturn;

    this(Position pos, string name, Arg[] args, Node block, bool isReturn)
    {
        this.pos = pos;
        this.name = name;
        this.args = args;
        this.block = block.toNullable;
        this.isReturn = isReturn;
    }

    mixin AcceptVisitor;
}


class CallNode : Node
{
    string macroName;
    Arg[] formArgs;
    Nullable!Node factArgs;
    Nullable!Node block;

    this(Position pos, string macroName, Arg[] formArgs, Node factArgs, Node block)
    {
        this.pos = pos;
        this.macroName = macroName;
        this.formArgs = formArgs;
        this.factArgs = factArgs.toNullable;
        this.block = block.toNullable;
    }

    mixin AcceptVisitor;
}


class FilterBlockNode : Node
{
    string filterName;
    Nullable!Node args;
    Nullable!Node block;

    this(Position pos, string filterName, Node args, Node block)
    {
        this.pos = pos;
        this.filterName = filterName;
        this.args = args.toNullable;
        this.block = block.toNullable;
    }

    mixin AcceptVisitor;
}



class ImportNode : Node
{
    struct Rename
    {
        string was, become;
    }

    string fileName;
    Rename[] macrosNames;
    Nullable!TemplateNode tmplBlock;
    bool withContext;

    this(Position pos, string fileName, Rename[] macrosNames, TemplateNode tmplBlock, bool withContext)
    {
        this.pos = pos;
        this.fileName = fileName;
        this.macrosNames = macrosNames;
        this.tmplBlock = tmplBlock.toNullable;
        this.withContext = withContext;
    }

    mixin AcceptVisitor;
}



class IncludeNode : Node
{
    string fileName;
    Nullable!TemplateNode tmplBlock;
    bool withContext;

    this(Position pos, string fileName, TemplateNode tmplBlock, bool withContext)
    {
        this.pos = pos;
        this.fileName = fileName;
        this.tmplBlock = tmplBlock.toNullable;
        this.withContext = withContext;
    }

    mixin AcceptVisitor;
}



class ExtendsNode : Node
{
    string fileName;
    Nullable!TemplateNode tmplBlock;

    this(Position pos, string fileName, TemplateNode tmplBlock)
    {
        this.pos = pos;
        this.fileName = fileName;
        this.tmplBlock = tmplBlock.toNullable;
    }

    mixin AcceptVisitor;
}



struct Arg
{
    string name;
    Nullable!Node defaultExpr;

    this(string name, Node def)
    {
        this.name = name;
        this.defaultExpr = def.toNullable;
    }
}



auto toNullable(T)(T val)
    if (is(T == class))
{
    if (val is null)
        return Nullable!T.init;
    else
        return Nullable!T(val);
}

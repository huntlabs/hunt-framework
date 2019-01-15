/*
 * Hunt - A high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design.
 *
 * Copyright (C) 2015-2019 HuntLabs
 *
 * Website: https://www.huntlabs.net/
 *
 * Licensed under the Apache-2.0 License.
 *
 */


module hunt.framework.view.ast.Visitor;

private
{
    import hunt.framework.view.ast.Node;
}

mixin template VisitNode(T)
{
    void visit(T);
}

interface VisitorInterface
{
    static foreach(NT; NodeTypes)
    {
        mixin VisitNode!NT;
    }
}

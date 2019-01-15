/**
  *
  *
  * Copyright:
  *     Copyright (c) 2018, Maxim Tyapkin.
  * Authors:
  *     Maxim Tyapkin
  * License:
  *     This software is licensed under the terms of the BSD 3-clause license.
  *     The full terms of the license can be found in the LICENSE.md file.
  */

module hunt.framework.view.djinja.ast.visitor;


private
{
    import hunt.framework.view.djinja.ast.node;
}



mixin template VisitNode(T)
{
    void visit(T);
}


interface IVisitor
{
    static foreach(NT; NodeTypes)
    {
        mixin VisitNode!NT;
    }
}

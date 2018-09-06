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

module hunt.framework.view.ast;

import hunt.framework.view.element;

class ASTNode
{
public:
    Element parsed_node;

    this()
    {
    }

    this(Element parsed_template)
    {
        parsed_node = parsed_template;
    }
}

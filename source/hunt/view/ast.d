module hunt.view.ast;

import hunt.view.element;

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

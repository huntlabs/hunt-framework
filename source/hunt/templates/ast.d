module hunt.templates.ast;

import hunt.templates.element;

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
};

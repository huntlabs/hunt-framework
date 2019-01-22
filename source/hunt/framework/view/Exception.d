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

module hunt.framework.view.Exception;

private
{
    import hunt.framework.view.Lexer : Position;
}


class TemplateException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}



class TemplateLexerException : TemplateException
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}



class TemplateParserException : TemplateException
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}



class TemplateRenderException : TemplateException
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}


void assertTemplate(E : TemplateException)(bool expr, string msg = "", Position pos = Position.init, string file = __FILE__, size_t line = __LINE__)
{
    if (!expr)
    {
        if (pos == Position.init)
            throw new E(msg, file, line);
        else
            throw new E(pos.toString ~ ": " ~ msg, file, line); 
    }
}


alias assertTemplateException = assertTemplate!TemplateException;
alias assertTemplateLexer = assertTemplate!TemplateLexerException;
alias assertTemplateParser = assertTemplate!TemplateParserException;
alias assertTemplateRender = assertTemplate!TemplateRenderException;

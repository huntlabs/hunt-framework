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


class JinjaException : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}



class JinjaLexerException : JinjaException
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}



class JinjaParserException : JinjaException
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}



class JinjaRenderException : JinjaException
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}


void assertJinja(E : JinjaException)(bool expr, string msg = "", Position pos = Position.init, string file = __FILE__, size_t line = __LINE__)
{
    if (!expr)
    {
        if (pos == Position.init)
            throw new E(msg, file, line);
        else
            throw new E(pos.toString ~ ": " ~ msg, file, line); 
    }
}


alias assertJinjaException = assertJinja!JinjaException;
alias assertJinjaLexer = assertJinja!JinjaLexerException;
alias assertJinjaParser = assertJinja!JinjaParserException;
alias assertJinjaRender = assertJinja!JinjaRenderException;

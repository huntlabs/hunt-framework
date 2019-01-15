/**
  * Djinja Exceptions
  *
  * Copyright:
  *     Copyright (c) 2018, Maxim Tyapkin.
  * Authors:
  *     Maxim Tyapkin
  * License:
  *     This software is licensed under the terms of the BSD 3-clause license.
  *     The full terms of the license can be found in the LICENSE.md file.
  */

module hunt.framework.view.djinja.exception;

private
{
    import hunt.framework.view.djinja.lexer : Position;
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

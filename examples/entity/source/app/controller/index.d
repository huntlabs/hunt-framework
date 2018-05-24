/*
 * Hunt - Hunt is a high-level D Programming Language Web framework that encourages rapid development and clean, pragmatic design. It lets you build high-performance Web applications quickly and easily.
 *
 * Copyright (C) 2015-2016  Shanghai Putao Technology Co., Ltd 
 *
 * Developer: putao's Dlang team
 *
 * Licensed under the BSD License.
 *
 */

module app.controller.index;

import hunt;

import app.repository.UserRepository;

import std.conv;

class IndexController : Controller
{
    mixin MakeController;
	
    this()
    {
    }
  
    @Action
    void list()
    {
        auto repository = new UserRepository;

        User[] users = repository.findAll();

        string str = "id &nbsp; name &nbsp; action<p>";
        foreach(user;users){
            str ~= "<a href=\"find?id="~user.id.to!string~"\">"~user.id.to!string ~ "</a>&nbsp;" ~ user.name  
            ~"&nbsp;  <a href=\"/del?id="~user.id.to!string~"\">delete</a>"
            ~"&nbsp;  <a href=\"/update?id="~user.id.to!string~"\">update</a><p>";
        }

        str ~= "<br>  <a href=\"/add\">add</a><p>";
        response.html(str);
    }
    
    @Action
    void add()
    {
        response.html(```
                      <form action="/add" method="post">
                        <p>name: <input type="text" name="name" /></p>
                        <input type="submit" value="Submit" />
                      </form>
                      ```);
    }
    

    @Action
    void addPost()
    {
        auto repository = new UserRepository;
        
        auto name = request.post("name","");

        User user = new User();
        user.name = name;
        repository.save(user);

        response.html(user.id.to!string ~ "<br> <a href=\"/list\">list</a>");
    }
    
    @Action
    void del()
    {
        auto id = request.get("id","");

        auto repository = new UserRepository;

        repository.remove(id.to!int);

        response.html("<br> <a href=\"/list\">list</a>");
    }
    
    @Action
    void update()
    {
        auto id = request.get("id","");
        
        auto repository = new UserRepository;
        User user = repository.find(id.to!int);

        response.html(```
                      <form action="/update" method="post">
                        <p>name: <input type="hidden"  name="id" value="```~id~```" /></p>
                        <p>name: <input type="text" name="name" value="`````~user.name~`"/></p>
                        <input type="submit" value="Submit" />
                      </form>
                      ```);
    }
    
    @Action
    void updatePost()
    {
        auto id = request.post("id","");
        auto name = request.post("name","");

        auto repository = new UserRepository;
        User user = repository.find(id.to!int);
        
        user.name = name;

        repository.save(user);

        response.html(id ~ "<br> <a href=\"/list\">list</a>");
    }
    
    @Action
    void find()
    {
        auto id = request.get("id","");

        auto repository = new UserRepository;
        User user = repository.find(id.to!int);

        response.html("id:" ~id ~ "&nbsp; name:" ~ user.name.to!string ~ "<br> <a href=\"/list\">list</a>");
    }
}

/*
 * Hunt - a framework for web and console application based on Collie using Dlang development
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

import app.model.user;

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
        auto cb = entityManager.createCriteriaBuilder!User();
        cb.where(cb.gt(cb.User.id,1));
        User[] users = entityManager.getResultList!User(cb);

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
        auto name = request.post("name","");
        User user = new User();
        user.name = name;
        entityManager.persist(user);
        response.html(user.id.to!string ~ "<br> <a href=\"/list\">list</a>");
    }
    
    @Action
    void del()
    {
        auto id = request.get("id","");
        User user = new User();
        user.id = id.to!int;
        int result = entityManager.remove(user);
        response.html(result.to!string ~ "<br> <a href=\"/list\">list</a>");
    }
    
    @Action
    void update()
    {
        auto id = request.get("id","");
        User user = new User();
        user.id = id.to!int;
        entityManager.find(user);
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
        User user = new User();
        user.id = id.to!int;
        user.name = name;
        entityManager.merge(user);
        response.html(id ~ "<br> <a href=\"/list\">list</a>");
    }
    
    @Action
    void find()
    {
        auto id = request.get("id","");
        User user = new User();
        user.id = id.to!int;
        entityManager.find(user);
        response.html("id:" ~id ~ "&nbsp; name:" ~ user.name.to!string ~ "<br> <a href=\"/list\">list</a>");
    }
}

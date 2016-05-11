module hunt.router.router;

import std.regex;

import hunt.router.middleware;
import hunt.router.utils;


class Router(REQ, RES)
{
    alias HandleDelegate = void delegate(REQ, RES);
    alias Pipeline = PipelineImpl!(REQ, RES);
    alias PipelineFactory = Pipeline delegate();
    alias RouterElement = PathElement(REQ, RES);
    
    void setBeforeMiddleware(PipelineFactory before);
    void setAfterMiddleware(PipelineFactory after);
    
    RouterElement addRouter(string method,string path,HandleDelegate handle,PipelineFactory before = null; PipelineFactory after = null);
    
    Pipeline match(string method,string path);
    
    
}


class PathElement(REQ, RES)
{
    alias HandleDelegate = void delegate(REQ, RES);
    alias Pipeline = PipelineImpl!(REQ, RES);
    alias PipelineFactory = Pipeline delegate();

    this(string path){_path = path;}
    
    PathElement!(REQ, RES) macth(string path,Pipeline pipe)
    {
        return this;
    }

    @property path(){return _path;}
    
    @property handler(){return _handler;}
    @property handler(HandleDelegate handle){ _handler = handle ;}
    
    Pipeline before(){if(_before) return _before(); else return null;}
    Pipeline after(){if(_after) return _after(); else return null;}
    
    void setBeforeMiddleware(PipelineFactory before){_before = before;}
    void setAfterMiddleware(PipelineFactory after){_after = after;}
    
protected:
    string _path;
    HandleDelegate _handler = null;
    PipelineFactory _before = null;
    PipelineFactory _after = null;
}
private:

class RegexElement(REQ, RES) : PathElement!(REQ,RES)
{
    this(string path)
    {
        super(path);
    }
    
    override PathElement!(REQ, RES) macth(string path,Pipeline pipe)
    {
        auto rg = regex(compiledRoute.regex, "s");
        auto mt = matchFirst(path, _reg);
        if(!mt)
        {
                return null;
        }
        foreach(attr;_reg.namedCaptures)
        {
            pipe.addMatch(attr,mt[attr]);
        }
        return this;
    }
    
private:
    void setRegex(string regex)
    {
        _reg = buildRegex(regex);
    }
    string _reg;
}


class RegexMap(REQ, RES) //: PathElement!(REQ,RES)
{
    alias RElement = RegexElement!(REQ, RES);
    alias RElementMap = RegexMap!(REQ, RES);
    
    this(string path)
    {
        super(path);
    }
    
    PathElement!(REQ, RES) add(RElement ele, string preg)
    {
        string rege;
        string str = getFristPath(ele.path, rege);
        if(str.length == 0 || isHaveRegex(str))
        {
            bool isHas = false;
            for(int i = 0; i < _list.length; ++i) //添加的时候去重
            {
                if(_list[i].path == ele.path)
                {
                    isHas = true;
                    auto tele = _list[i];
                    _list[i] = ele;
                    tele.destroy;
                }
            }
            if(!isHas)
            {
                _list ~= ele;
            }
            return ele;
        }
        else
        {
            RElementMap map = _map.get(str,null);
            if(!map){
                map = new RElementMap(str);
                _map[str] = map;
            }
            return map.add(ele,rege);
        }
    }
    
    PathElement!(REQ, RES) macth(string path,Pipeline pipe)
    {
        string lpath;
        string frist = getFristPath(path,lpath);
        RElementMap map = _map.get(str,null);
        if(map)
        {
            return map.macth(lpath,pipe);
        }
        else
        {
            foreach(ele;RElement)
            {
                auto element = ele.macth(path,pipe);
                if(element)
                {
                    return element;
                }
            }
        }
        return null;
    }
    
private:
    RElementMap[string] _map;
    RElement[] _list;
}


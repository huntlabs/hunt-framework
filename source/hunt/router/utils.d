module hunt.router.utils;

/// 构造正则表达式，类似上个版本的，把配置里的单独的表达式，构建成一个
string buildRegex(string reglist)
{}

/// 判断URL中是否是正则表达式的 (是否有{字符)
string isHaveRegex(string path)
{}


/// 取出来地一个path： 例如： /file/ddd/f ; reurn = file,  lpath= /ddd/f;
string getFristPath(string fpath,out string lpath)
{}

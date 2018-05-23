module app.controller.member.index;
import hunt.application;

class IndexController : Controller
{
	mixin MakeController;
    this()
    {
    }
    @Action
    void show()
	{	
		auto response = this.request.createResponse();
        response.html("hello world<br/>")
        //.setHeader("content-type","text/html;charset=UTF-8")
        .setCookie("name", "value", 10000)
        .setCookie("name1", "value", 10000, "/path")
        .setCookie("name2", "value", 10000);
    }
	@Action
    void list()
    {
		this.view.setLayout!"main.dhtml"();	
		this.view.test = "viile";
		this.view.username = "viile";
		this.view.header = "donglei header";
		this.view.footer = "footer";
		this.render!"content.dhtml"();

    }
	@Action
    void index()
    {
        this.response.html("list");
    }
}

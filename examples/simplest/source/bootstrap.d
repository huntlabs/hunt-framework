import hunt;

void main()
{
	auto app = Application.getInstance();

	app.GET("/index",function(Request req){
		Response res = req.createResponse();
		res.html("hello world");
		res.done();
	});
	
    app.POST("/index",function(Request req){
        auto form = req.postForm();
		Response res = req.createResponse();
		res.html("hello world");
		res.done();
	});

	app.run(parseAddress("0.0.0.0",11234));
}

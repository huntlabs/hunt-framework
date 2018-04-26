import hunt;
import hunt.application.config;

void main()
{
	Application app = Application.getInstance();

	app.GET("/", function(Request req) {
		Response res = req.createResponse();
		res.html("Hello world!");
		res.done();
	});

	app.POST("/", function(Request req) {
		auto form = req.postForm();
		Response res = req.createResponse();
		res.html("Hello world!");
		res.done();
	});

	AppConfig c = app.appConfig();
	// c.http.address = "0.0.0.0";
	c.http.port = 8090;
	app.setConfig(c);

	app.run();
}

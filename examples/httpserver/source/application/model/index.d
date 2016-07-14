module application.model.index;

import hunt.application;
public import entity;


@TABLE("test2")
struct Test
{
	@PRIMARYKEY()
	int id;

	@COLUMN("floatcol")
	float fcol;

	@COLUMN("doublecol")
	double dcol;

	@COLUMN("datecol")
	Date date;

	@COLUMN("datetimecol")
	DateTime dt;

	@COLUMN("timecol")
	Time time;

	@COLUMN()
	string stringcol;

	@COLUMN()
	ubyte[] ubytecol;
} 

class IndexModel
{
    void showTest2()
    {
        auto quer = getQuery!Test();
        auto iter = quer.Select();
	if(iter !is null)
            while(!iter.empty)
            {
                    Test tp = iter.front();
                    iter.popFront();
                    writeln("float is  : ", tp.fcol);
                    writeln("the string is : ", tp.stringcol);
                    writeln("the ubyte is : ", cast(string)tp.ubytecol);
            }
    }
    
    void insertNew(Test t)
    {
        auto quer = getQuery!Test();
        quer.Insert(t);
    }
}

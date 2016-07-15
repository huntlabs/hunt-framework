module application.model.index;

import hunt.application;
public import entity;


@Table("test2")
struct Test
{
	@Primarykey()
	int id;

	@Field ("floatcol")
	float fcol;

	@Field("doublecol")
	double dcol;

	@Field("datecol")
	Date date;

	@Field("datetimecol")
	DateTime dt;

	@Field("timecol")
	Time time;

	@Field()
	string stringcol;

	@Field()
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

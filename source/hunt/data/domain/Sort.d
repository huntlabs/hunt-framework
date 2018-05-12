module hunt.data.domain.Sort;

import entity;
import std.traits;
public import entity.Constant;
class Sort
{
	Order[] _lst;

	this()
	{

	}

	this(string column ,  OrderBy order)
	{
		_lst ~= new Order(column , order);
	}

	Sort add( Order order)
	{
		_lst ~= order;
		return this;
	}


	Order[] list()
	{
		return _lst;
	}
}


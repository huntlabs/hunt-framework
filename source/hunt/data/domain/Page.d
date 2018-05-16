module hunt.data.domain.Page;

import hunt.data.domain.Pageable;
import hunt.data.domain.Sort;

class Page(T)
{
	T[] 		_content;
	Pageable	_pageable;
	long		_total;


	this(T []content , 
		Pageable pageable , 
		long total)
	{
		_content = content;
		_pageable = pageable;
		_total = total;
	}

	int getNumber()
	{
		return _pageable.getPageNumber();
	}
	
	int getSize()             
	{
		return _pageable.getPageSize();
	}

	int getTotalPages()
	{
		return cast(int)(_total / getSize() + (_total % getSize() == 0 ? 0 : 1));
	}
	
	int getNumberOfElements()
	{
		return cast(int)_content.length;
	}
	
	long getTotalElements()
	{
		return _total;
	}
	
	bool hasPreviousPage()
	{
		return getNumber() > 0;
	}
	
	bool isFirstPage()
	{
		return getNumber() == 0;
	}
	
	bool hasNextPage()
	{
		return getNumber() < getTotalPages() - 1;
	}
	
	bool isLastPage()
	{
		return getNumber() == getTotalPages() - 1;
	}

	T[] getContent()
	{
		return _content;
	}
	
	bool hasContent()
	{
		return _content.length > 0 ;
	}
	
	Sort getSort()
	{
		return _pageable.getSort();
	}
}
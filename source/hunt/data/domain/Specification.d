module hunt.data.domain.Specification;

import entity;

interface Specification(T)
{
	Predicate toPredicate(Root!T root, CriteriaQuery!T criteriaQuery ,
		CriteriaBuilder criteriaBuilder);
}


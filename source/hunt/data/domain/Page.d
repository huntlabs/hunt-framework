module hunt.data.domain.Page;

class Page(T)
{
    T empty()
    {
        return null;
    }

    long getTotalElements()
    {
        return 0;
    }

    int getTotalPages()
    {
        return 0;
    }

    Page map()
    {
        return null;
    }
}

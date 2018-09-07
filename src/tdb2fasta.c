main()
{
    char buf[512], id[80];

    gets(buf);
    if (buf[0] == '#')
        sscanf(buf, "%*s%s", id);
    else
        sscanf(buf, "%s", id);
    printf(">%s TDB SEQUENCE FROM %s\n", id, id);
    while (gets(buf))
        if (isalpha(buf[5]))
            putchar(buf[5]);
    putchar('\n');
}

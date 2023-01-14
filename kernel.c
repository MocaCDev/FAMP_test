void __attribute__((section("__start"))) kmain()
{
    unsigned char *vid_mem = (unsigned char *)0xB8000;
    *vid_mem = 'B';

    while(1);
}
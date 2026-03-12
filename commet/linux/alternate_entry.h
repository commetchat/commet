
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <string>

int alternate_entry_point(int argc,
                          char *argv[])
{

    if (argc < 2)
    {
        return 0;
    }

    if (strcmp(argv[1], "--entry") != 0)
    {
        return 0;
    }

    std::cout << "Opening alternate entry point";
    void *plibobj = dlopen("librust_lib_commet.so", RTLD_LAZY);

    if (!plibobj)
    {
        std::cerr << "Error loading the library\n";
        return -1;
    }

    void (*rust_entry)();

    void *symbol_ptr = dlsym(plibobj, "commet_entry");

    if (!symbol_ptr)
    {
        std::cerr << "Could not find correct entrypoint in the library\n";
        return -1;
    }

    std::cout << "Found entry: " << std::hex << symbol_ptr;

    rust_entry = reinterpret_cast<decltype(rust_entry)>(symbol_ptr);
    rust_entry();

    return 1;
}
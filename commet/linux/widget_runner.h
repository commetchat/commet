
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>
#include <string>

int widget_runner(int argc,
                  char *argv[])
{

    if (argc < 2)
    {
        return 0;
    }

    if (strcmp(argv[1], "--widget_runner") != 0)
    {
        return 0;
    }

    std::cerr << "Opening widget runner entry point";
    void *plibobj = dlopen("librust_lib_commet.so", RTLD_LAZY);

    if (!plibobj)
    {
        std::cerr << "Error loading the library\n";
        return -1;
    }

    void (*rust_entry)();

    void *symbol_ptr = dlsym(plibobj, "commet_widget_runner");

    if (!symbol_ptr)
    {
        std::cerr << "Could not find correct entrypoint in the library\n";
        return -1;
    }

    std::cerr << "Found entry: " << std::hex << symbol_ptr;

    rust_entry = reinterpret_cast<decltype(rust_entry)>(symbol_ptr);
    rust_entry();

    return 1;
}
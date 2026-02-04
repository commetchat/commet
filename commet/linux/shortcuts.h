#include <dbus/dbus.h>

#include <cstddef>
#include <cstdio>
#include <iostream>

int shortcuts_main(
    int argc,
    char *argv[])
{
    (void)argc;
    (void)argv;
    DBusError dbus_error;
    DBusConnection *dbus_conn = nullptr;
    DBusMessage *dbus_msg = nullptr;

    if (argc < 2)
    {
        return 0;
    }

    if (strcmp(argv[1], "--shortcut") != 0)
    {
        return 0;
    }

    std::cout << "Got dbus invocation: " << argc << std::endl;
    for (int i = 0; i < argc; ++i)
    {
        std::cout << "Arg " << i << ": " << argv[i] << std::endl;
    }

    // Initialize D-Bus error
    ::dbus_error_init(&dbus_error);

    // Connect to D-Bus
    dbus_conn = ::dbus_bus_get(DBUS_BUS_SESSION, &dbus_error);

    if (dbus_conn == nullptr)
    {
        ::perror(dbus_error.name);
        ::perror(dbus_error.message);
        return -1;
    }

    if (strcmp(argv[2], "mute") == 0)
    {
        dbus_msg = ::dbus_message_new_method_call("chat.commet.commetapp", "/chat/commet/commetapp/Shortcuts", "chat.commet.commetapp.Shortcuts", "mute");
    }
    else if (strcmp(argv[2], "unmute") == 0)
    {
        dbus_msg = ::dbus_message_new_method_call("chat.commet.commetapp", "/chat/commet/commetapp/Shortcuts", "chat.commet.commetapp.Shortcuts", "unmute");
    }

    if (dbus_msg == nullptr)
    {
        ::dbus_connection_unref(dbus_conn);
        ::perror("ERROR: ::dbus_message_new_method_call - Unable to allocate memory for the message!");

        return -1;
    }

    dbus_uint32_t serial = 0;
    ::dbus_connection_send(dbus_conn, dbus_msg, &serial);

    ::dbus_message_unref(dbus_msg);
    ::dbus_connection_unref(dbus_conn);
    return 1;
}

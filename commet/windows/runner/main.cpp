#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <iostream>
#include "flutter_window.h"
#include "utils.h"

typedef int(__stdcall *rust_entry)();

int widgetRunnerEntry(std::vector<std::string> args)
{
  HINSTANCE hGetProcIDDLL = LoadLibrary(L"rust_lib_commet.dll");

  if (!hGetProcIDDLL)
  {
    std::cout << "could not load the dynamic library" << std::endl;
    return EXIT_FAILURE;
  }

  // resolve function address here
  rust_entry funci = (rust_entry)GetProcAddress(hGetProcIDDLL, "commet_widget_runner");
  if (!funci)
  {
    std::cout << "could not locate the function" << std::endl;
    return EXIT_FAILURE;
  }
  else
  {
    funci();
  }

  return EXIT_SUCCESS;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command)
{
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent())
  {
    CreateAndAttachConsole();
  }

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  for (const std::string &i : command_line_arguments)
  {
    int result = strcmp(i.c_str(), "--widget_runner");

    if (result == 0)
    {
      return widgetRunnerEntry(command_line_arguments);
    }
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"commet", origin, size))
  {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0))
  {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}

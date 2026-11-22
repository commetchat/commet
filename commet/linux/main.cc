#include "my_application.h"
#include "shortcuts.h"
#include "widget_runner.h"
#include "overlay_runner.h"
#include "overlay_runner_debug.h"

int main(int argc, char **argv)
{

  // flutter run -d linux --dart-entrypoint-args --shortcut,mute
  int is_shortcut = shortcuts_main(argc, argv);
  if (is_shortcut != 0)
  {
    return is_shortcut;
  }

  // flutter run -d linux --dart-entrypoint-args --widget_runner
  int is_widget_runner = widget_runner(argc, argv);
  if (is_widget_runner != 0)
  {
    return is_widget_runner;
  }

  // flutter run -d linux --dart-entrypoint-args --overlay
  int is_overlay = overlay_runner(argc, argv);
  if(is_overlay != 0) 
  {
    return is_overlay;
  }

  // flutter run -d linux --dart-entrypoint-args --overlay_debug
  int is_overlay_debug = overlay_runner_debug(argc, argv);
  if(is_overlay_debug != 0) 
  {
    return is_overlay_debug;
  }

  if (is_shortcut == 0)
  {
    g_autoptr(MyApplication) app = my_application_new();
    return g_application_run(G_APPLICATION(app), argc, argv);
  }
}

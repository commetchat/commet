#include "my_application.h"
#include "shortcuts.h"
#include "widget_runner.h"

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

  if (is_shortcut == 0)
  {
    g_autoptr(MyApplication) app = my_application_new();
    return g_application_run(G_APPLICATION(app), argc, argv);
  }
}

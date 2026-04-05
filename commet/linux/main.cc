#include "my_application.h"
#include "shortcuts.h"
#include "alternate_entry.h"

int main(int argc, char **argv)
{

  // flutter run -d linux --dart-entrypoint-args --shortcut,mute
  int is_shortcut = shortcuts_main(argc, argv);
  if (is_shortcut != 0)
  {
    return is_shortcut;
  }

  // flutter run -d linux --dart-entrypoint-args --entry
  int is_alternate_entry = alternate_entry_point(argc, argv);
  if (is_alternate_entry != 0)
  {
    return is_alternate_entry;
  }

  if (is_shortcut == 0)
  {
    g_autoptr(MyApplication) app = my_application_new();
    return g_application_run(G_APPLICATION(app), argc, argv);
  }
}

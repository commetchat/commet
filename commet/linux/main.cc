#include "my_application.h"
#include "shortcuts.h"

int main(int argc, char **argv)
{

  // flutter run -d linux --dart-entrypoint-args --shortcut,mute
  int is_shortcut = shortcuts_main(argc, argv);

  if (is_shortcut == 0)
  {
    g_autoptr(MyApplication) app = my_application_new();
    return g_application_run(G_APPLICATION(app), argc, argv);
  }

  return is_shortcut;
}

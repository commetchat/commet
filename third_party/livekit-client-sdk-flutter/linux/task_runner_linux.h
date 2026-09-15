#ifndef PACKAGES_FLUTTER_WEBRTC_LINUX_TASK_RUNNER_LINUX_H_
#define PACKAGES_FLUTTER_WEBRTC_LINUX_TASK_RUNNER_LINUX_H_

#include <memory>
#include <mutex>
#include <queue>
 #include <functional>
 
 using TaskClosure = std::function<void()>;

namespace livekit_client_plugin {

class TaskRunnerLinux {
 public:
  TaskRunnerLinux() = default;
  ~TaskRunnerLinux() = default;

  // TaskRunner implementation.
  void EnqueueTask(TaskClosure task);

 private:
  std::mutex tasks_mutex_;
  std::queue<TaskClosure> tasks_;
};

}  // namespace livekit_client_plugin

#endif  // PACKAGES_FLUTTER_WEBRTC_LINUX_TASK_RUNNER_LINUX_H_
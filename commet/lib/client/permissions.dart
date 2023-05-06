class Permissions {
  bool get canBan => false;

  bool get canKick => false;

  bool get canSendMessage => false;

  bool get canEditName => false;

  bool get canEditAvatar => false;

  bool get canEditAnything => (canEditName || canEditAvatar);
}

class Permissions {
  bool get canBan => false;

  bool get canKick => false;

  bool get canSendMessage => false;

  bool get canEditName => false;

  bool get canEditAvatar => false;

  bool get canEditAnything =>
      (canEditName || canEditAvatar || canChangeNotificationSettings);

  bool get canEditAppearance => (canEditAvatar || canEditName);

  bool get canEnableE2EE => false;

  bool get canEditRoomSecurity => canEnableE2EE;

  bool get canChangeNotificationSettings => true;

  bool get canUserEditMessages => true;

  bool get canDeleteOtherUserMessages => true;

  bool get canEditRoomEmoticons => true;

  bool get canEditChildren => true;
}

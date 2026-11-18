enum Role {
  player,
  owner,
  admin;

  String get label => switch (this) {
    Role.player => 'Player',
    Role.owner => 'Pitch Owner',
    Role.admin => 'Admin',
  };

  static Role parse(Object? value) {
    return Role.values.firstWhere(
      (r) => r.name == value?.toString(),
      orElse: () => Role.player,
    );
  }
}

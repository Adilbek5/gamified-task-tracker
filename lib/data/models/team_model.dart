class TeamModel {
  final String id;
  final String name;
  final String leadId;
  final String inviteCode;
  final List<String> memberIds;

  TeamModel({
    required this.id,
    required this.name,
    required this.leadId,
    required this.inviteCode,
    this.memberIds = const [],
  });

  Map<String, dynamic> toFirebase() => {
    'name': name, 'lead_id': leadId,
    'invite_code': inviteCode,
    'member_ids': memberIds,
  };

  factory TeamModel.fromFirebase(
      String id, Map<dynamic, dynamic> m) => TeamModel(
    id: id,
    name: m['name'] ?? '',
    leadId: m['lead_id'] ?? '',
    inviteCode: m['invite_code'] ?? '',
    memberIds: m['member_ids'] != null
        ? List<String>.from(m['member_ids'])
        : [],
  );
}
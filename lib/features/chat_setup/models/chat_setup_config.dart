/// User configuration selected during setup prior to analysis.
class ChatSetupConfig {
  final String userParticipantName;
  final String relationshipType; // crush, partner, ex, friend, family, group, work
  final String outputLanguage; // en, es, fr, etc.
  final String roastIntensity; // gentle, spicy, savage
  final bool enableRoast;

  const ChatSetupConfig({
    required this.userParticipantName,
    required this.relationshipType,
    required this.outputLanguage,
    required this.roastIntensity,
    this.enableRoast = true,
  });

  Map<String, dynamic> toJson() => {
        'user_participant_name': userParticipantName,
        'relationship_type': relationshipType,
        'output_language': outputLanguage,
        'roast_intensity': roastIntensity,
        'enable_roast': enableRoast,
      };

  factory ChatSetupConfig.fromJson(Map<String, dynamic> json) {
    return ChatSetupConfig(
      userParticipantName: json['user_participant_name'] as String,
      relationshipType: json['relationship_type'] as String,
      outputLanguage: json['output_language'] as String? ?? 'en',
      roastIntensity: json['roast_intensity'] as String? ?? 'spicy',
      enableRoast: json['enable_roast'] as bool? ?? true,
    );
  }
}

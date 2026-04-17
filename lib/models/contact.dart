class Contact {
  final String? id;
  final String userId;
  final String? companyName;
  final String? clientName;
  final String? businessModel;
  final String? businessOperation;
  final String? targetMarket;
  final String? lookingFor;
  final String? phoneNumber;
  final String? email;
  final String? additionalNotes;
  final String? audioFilePath;
  final String? transcription;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contact({
    this.id,
    required this.userId,
    this.companyName,
    this.clientName,
    this.businessModel,
    this.businessOperation,
    this.targetMarket,
    this.lookingFor,
    this.phoneNumber,
    this.email,
    this.additionalNotes,
    this.audioFilePath,
    this.transcription,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'company_name': companyName,
      'client_name': clientName,
      'business_model': businessModel,
      'business_operation': businessOperation,
      'target_market': targetMarket,
      'looking_for': lookingFor,
      'phone_number': phoneNumber,
      'email': email,
      'additional_notes': additionalNotes,
      'audio_file_path': audioFilePath,
      'transcription': transcription,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      companyName: json['company_name']?.toString(),
      clientName: json['client_name']?.toString(),
      businessModel: json['business_model']?.toString(),
      businessOperation: json['business_operation']?.toString(),
      targetMarket: json['target_market']?.toString(),
      lookingFor: json['looking_for']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      email: json['email']?.toString(),
      additionalNotes: json['additional_notes']?.toString(),
      audioFilePath: json['audio_file_path']?.toString(),
      transcription: json['transcription']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Contact copyWith({
    String? id,
    String? userId,
    String? companyName,
    String? clientName,
    String? businessModel,
    String? businessOperation,
    String? targetMarket,
    String? lookingFor,
    String? phoneNumber,
    String? email,
    String? additionalNotes,
    String? audioFilePath,
    String? transcription,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      clientName: clientName ?? this.clientName,
      businessModel: businessModel ?? this.businessModel,
      businessOperation: businessOperation ?? this.businessOperation,
      targetMarket: targetMarket ?? this.targetMarket,
      lookingFor: lookingFor ?? this.lookingFor,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      transcription: transcription ?? this.transcription,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

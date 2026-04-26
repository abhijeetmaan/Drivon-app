import 'package:hive/hive.dart';

import '../../domain/entities/user_profile.dart';

@HiveType(typeId: 21)
class ProfileModel extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String? phone;

  @HiveField(3)
  final String? avatarPath;

  ProfileModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarPath,
  });

  UserProfile toEntity() => UserProfile(name: name, email: email, phone: phone, avatarPath: avatarPath);

  static ProfileModel fromEntity(UserProfile p) => ProfileModel(
        name: p.name,
        email: p.email,
        phone: p.phone,
        avatarPath: p.avatarPath,
      );
}

class ProfileModelAdapter extends TypeAdapter<ProfileModel> {
  static const int typeIdValue = 21;

  @override
  int get typeId => typeIdValue;

  @override
  ProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProfileModel(
      name: (fields[0] as String?) ?? '',
      email: (fields[1] as String?) ?? '',
      phone: fields[2] as String?,
      avatarPath: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProfileModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.avatarPath);
  }
}


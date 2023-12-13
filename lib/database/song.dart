import 'package:isar/isar.dart';
import 'package:music_server/audio_processing.dart';
import 'package:music_server/database/unprocessed_song.dart';
import 'package:music_server/music_server.dart';
import 'package:path/path.dart' as p;

part 'song.g.dart';

@collection
class Song {
  final String id;

  final String owner;

  @utc
  final DateTime timestamp;

  final bool public;

  final String name;
  final String description;

  final int numPlays;

  Song({
    required this.id,
    required this.owner,
    required this.timestamp,
    required this.public,
    required this.name,
    required this.description,
    this.numPlays = 0,
  });

  Song.create({required this.id, required this.owner, required this.name, required this.description})
      : timestamp = DateTime.now().toUtc(),
        public = false,
        numPlays = 0;

  Song.createFromUnprocessed(UnprocessedSong unprocessedSong)
      : id = unprocessedSong.id,
        owner = unprocessedSong.owner,
        timestamp = DateTime.now().toUtc(),
        name = unprocessedSong.name,
        description = unprocessedSong.description,
        public = false,
        numPlays = 0;
}

String getSongStorageDir(MusicServerPaths paths, String id) => p.join(paths.storagePath, 'songs', id);
String getSongFilePath(MusicServerPaths paths, String id, ProcessAudioPreset preset) => p.join(paths.storagePath, 'songs', id, '${preset.quality.outputFileName}${preset.format.fileExtension}');

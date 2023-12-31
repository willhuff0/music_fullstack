import 'dart:async';

import 'package:flutter/material.dart';
import 'package:music_client/client/song.dart';
import 'package:music_client/ui/widgets/song_image.dart';
import 'package:music_shared/music_shared.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController controller;

  Timer? onChangedTimer;

  List<Song>? songs;

  @override
  void initState() {
    controller = TextEditingController();
    super.initState();
  }

  void onChanged() {
    onChangedTimer?.cancel();
    onChangedTimer = Timer(const Duration(milliseconds: 600), onSearch);
  }

  void onSearch() async {
    final text = controller.text;
    if (text.isEmpty) {
      setState(() => songs = null);
      return;
    }

    final results = await searchSongs(text);
    if (mounted) setState(() => songs = results);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0),
            child: TextField(
              controller: controller,
              onChanged: (value) => onChanged(),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10000.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 28.0,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 56.0),
                hintText: 'Search for music',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6)),
              ),
            ),
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 100),
              child: songs == null
                  ? Container()
                  : songs!.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(48.0),
                          child: Text('No resuts :('),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: songs!.length + 30,
                          padding: const EdgeInsets.all(24.0),
                          itemBuilder: (context, index) {
                            final song = songs![0];
                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
                              child: SizedBox(
                                height: 80.0,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: AspectRatio(
                                        aspectRatio: 1.0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(14.0),
                                            image: DecorationImage(image: NetworkImage(getSongImageUrl(song.id, ImageSize.thumb))),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 6.0, right: 18.0, top: 8.0, bottom: 8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(song.name, style: Theme.of(context).textTheme.titleMedium),
                                            const SizedBox(height: 4.0),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(left: 4.0),
                                                child: Text(
                                                  song.description,
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8)),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ),
      ],
    );
  }
}

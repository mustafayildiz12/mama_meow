import 'package:mama_meow/models/podcast_model.dart';

class DisplayPodcastArgs {
  final Podcast podcast;
  final List<Podcast> podcastList;
  final int currentIndex;

  const DisplayPodcastArgs({
    required this.podcast,
    required this.podcastList,
    required this.currentIndex,
  });
}

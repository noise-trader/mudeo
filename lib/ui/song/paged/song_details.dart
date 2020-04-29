import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:mudeo/data/models/song_model.dart';
import 'package:mudeo/redux/app/app_state.dart';
import 'package:mudeo/redux/artist/artist_actions.dart';
import 'package:mudeo/redux/song/song_actions.dart';
import 'package:mudeo/ui/artist/artist_profile.dart';
import 'package:mudeo/utils/localization.dart';
import 'package:share/share.dart';

class SongDetails extends StatelessWidget {
  const SongDetails({@required this.song});

  final SongEntity song;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black12.withOpacity(.9),
            Colors.transparent,
          ],
          stops: [0, 1],
          begin: Alignment(0, 1),
          end: Alignment(0, .3),
        ),
      ),
      padding: const EdgeInsets.only(
        left: 15,
        top: 15,
        right: 15,
        bottom: 70,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Container(
                color: Colors.black,
                width: 120,
                height: 200,
              ),
            ],
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '@${song.artist.handle}',
                        style: textTheme.headline6,
                      ),
                      SizedBox(height: 12),
                      if ((song.description ?? '').trim().isNotEmpty) ...[
                        Text(song.description),
                        SizedBox(height: 12),
                      ],
                      Text(
                        '🎵  ${song.title}',
                        style: textTheme.bodyText1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                _SongActions(
                  song: song,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SongActions extends StatelessWidget {
  const _SongActions({@required this.song});

  final SongEntity song;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final store = StoreProvider.of<AppState>(context);
    final state = store.state;
    final artist = state.authState.artist;

    _editSong({SongEntity song, BuildContext context}) {
      // TODO remove this workaround for selecting selected song in list view
      if (state.uiState.song.id == song.id) {
        store.dispatch(EditSong(song: SongEntity(), context: context));
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => store.dispatch(EditSong(song: song, context: context)));
      } else {
        store.dispatch(EditSong(song: song, context: context));
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        ArtistProfile(
            artist: song.artist,
            onTap: () => kIsWeb
                ? null
                : store.dispatch(ViewArtist(
                    context: context,
                    artist: song.artist,
                  ))),
        _LargeIconButton(
          iconData: Icons.videocam,
          onPressed: () {
            final uiSong = state.uiState.song;
            SongEntity newSong = song;

            if (!artist.ownsSong(song)) {
              newSong = song.fork;
            }
            if (state.isDance && !state.artist.ownsSong(newSong)) {
              newSong = newSong.justKeepFirstTrack;
            }

            if (uiSong.hasNewVideos && uiSong.id != newSong.id) {
              showDialog<AlertDialog>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  semanticLabel: localization.areYouSure,
                  title: Text(localization.loseChanges),
                  content: Text(localization.areYouSure),
                  actions: <Widget>[
                    new FlatButton(
                        child: Text(localization.cancel.toUpperCase()),
                        onPressed: () {
                          Navigator.pop(context);
                        }),
                    new FlatButton(
                        child: Text(localization.ok.toUpperCase()),
                        onPressed: () {
                          Navigator.pop(context);
                          _editSong(song: newSong, context: context);
                        })
                  ],
                ),
              );
            } else {
              _editSong(song: newSong, context: context);
            }
          },
        ),
        if (state.authState.hasValidToken)
          _LargeIconButton(
            iconData: Icons.favorite,
            count: song.countLike,
            color: artist.likedSong(song.id) ? Colors.red : null,
            onPressed: () {
              store.dispatch(LikeSongRequest(song: song));
            },
          ),
        _LargeIconButton(
          iconData: Icons.comment,
          tooltip: localization.comment,
          count: song.comments.length,
          onPressed: () {
            //
          },
        ),
        _LargeIconButton(
          iconData: Icons.share,
          tooltip: localization.share,
          onPressed: () {
            Share.share(song.url);
          },
        ),
      ],
    );
  }
}

class _LargeIconButton extends StatelessWidget {
  const _LargeIconButton({
    this.iconData,
    this.tooltip,
    this.onPressed,
    this.color,
    this.count,
    this.requireLoggedIn = false,
  });

  final IconData iconData;
  final String tooltip;
  final Function onPressed;
  final bool requireLoggedIn;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          IconButton(
            icon: Icon(
              iconData,
              size: 40,
              color: color,
            ),
            tooltip: tooltip,
            onPressed: onPressed,
          ),
          /*
          if (count != null && count > 0)
            Text('$count'),
           */
        ],
      ),
    );
  }
}
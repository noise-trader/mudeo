import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mudeo/data/models/song_model.dart';
import 'package:mudeo/utils/localization.dart';

class TrackSyncer extends StatefulWidget {
  const TrackSyncer({
    @required this.song,
    @required this.onDelayChanged,
  });

  final SongEntity song;
  final Function(TrackEntity, int) onDelayChanged;

  @override
  _TrackSyncerState createState() => _TrackSyncerState();
}

class _TrackSyncerState extends State<TrackSyncer> {
  int _timeSpan = 1000 * 10;
  int _timeStart = 0;
  Map<int, bool> _isSyncing = {
    1: false,
    2: false,
    3: false,
    4: false,
  };

  SongEntity _song;

  @override
  void initState() {
    super.initState();
    _song = widget.song;
  }

  void _syncVideos() async {
    if (_song.tracks.length < 2) {
      return;
    }

    for (int i = 1; i <= _song.tracks.length - 1; i++) {
      setState(() {
        _isSyncing[i] = true;
      });

      final track = _song.tracks[i];
      int delay = await compute(getMinDelay,
          [_song.tracks[0].video.volumeMap, _song.tracks[i].video.volumeMap]);
      widget.onDelayChanged(track, delay);
      setState(() {
        _song = _song.setTrackDelay(track, delay);
        _isSyncing[i] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);

    return AlertDialog(
      title: Text(AppLocalization.of(context).trackAdjustment),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < _song.tracks.length; i++)
            TrackVolume(
              track: _song.tracks[i],
              timeSpan: _timeSpan,
              isSyncing: i == 0 ? false : _isSyncing[i],
            ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Expanded(
                child: RaisedButton(
                  color: Colors.grey,
                  child: Text(localization.sync.toUpperCase()),
                  onPressed: _isSyncing.values.contains(true)
                      ? null
                      : () => _syncVideos(),
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: RaisedButton(
                  child: Text(localization.done.toUpperCase()),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TrackVolume extends StatelessWidget {
  const TrackVolume({
    @required this.track,
    @required this.timeSpan,
    @required this.isSyncing,
  });

  final TrackEntity track;
  final int timeSpan;
  final bool isSyncing;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        height: 1400,
        width: timeSpan.toDouble(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 100),
          child: Container(
            color: Colors.black38,
            child: CustomPaint(
              painter: VolumePainter(
                track: track,
                timeSpan: timeSpan,
                color: isSyncing ? Colors.blueAccent : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VolumePainter extends CustomPainter {
  const VolumePainter(
      {@required this.track, @required this.timeSpan, @required this.color});

  final TrackEntity track;
  final int timeSpan;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final video = track.video;
    var paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.fill;

    if (video == null || video.volumeData == null) {
      return;
    }

    final volumeData = video.volumeData;

    double volume = 0;

    for (int i = 0; i <= timeSpan; i++) {
      var time = (i - track.delay).toString();

      if (volumeData.containsKey(time)) {
        volume = volumeData[time];
      }

      if (volume > 120) {
        volume = 120;
      } else if (volume < 20) {
        volume = 20;
      }

      if (i % 10 == 0) {
        final height = 1200.0;
        final rect = Rect.fromLTRB(i.toDouble(), height, i.toDouble() + 7,
            height - ((volume - 20) * 10));
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

int getMinDelay(List<Map<int, double>> maps) {
  final video1Map = maps[0];
  final video2Map = maps[1];
  double minDiff = 999999999;
  int minDiffDelay = 0;
  for (int j = -1000; j <= 1000; j++) {
    double totalDiff = 0;

    for (int k = 1000; k <= 9000; k++) {
      final oldVolume = video1Map[k];
      final newVolume = video2Map[k + j];
      final diff =
          oldVolume > newVolume ? oldVolume - newVolume : newVolume - oldVolume;

      totalDiff += diff;
    }

    if (totalDiff < minDiff) {
      minDiff = totalDiff;
      minDiffDelay = j;
    }
  }

  return minDiffDelay * -1;
}

/// Is the picked file a photo (or a video, if [video])? The browser's type wins.
/// If it gives none, the end of the name decides.
bool isRightFile({
  required String? mimeType,
  required String name,
  required bool video,
}) {
  if (mimeType != null && mimeType.isNotEmpty) {
    return mimeType.startsWith(video ? 'video/' : 'image/');
  }
  final dot = name.lastIndexOf('.');
  final ending = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  return (video ? _videoEndings : _imageEndings).contains(ending);
}

const _imageEndings = {
  'jpg',
  'jpeg',
  'png',
  'webp',
  'gif',
  'heic',
  'heif',
  'bmp',
};
const _videoEndings = {'mp4', 'mov', 'webm', '3gp', 'm4v', 'mkv'};

# Big Buck Bunny bird clips

`big_buck_bunny_bird.h264` and `big_buck_bunny_bird.h265` are 480×270,
24 FPS, silent derivatives of [Big Buck Bunny 8 seconds bird clip][source]
from Wikimedia Commons.

- Author and attribution: © copyright Blender Foundation | www.bigbuckbunny.org
- License: [Creative Commons Attribution 3.0][license]
- Original file: 1,758,384-byte Ogg/Theora clip, SHA-256
  `1a86a4af685a5285d593b7d3ee9d8e23f3c63c5ba3f86bd191c97157c12a237a`
- Included H.264 derivative: 177 video frames, 283,763 bytes, SHA-256
  `709ee3b379f9d0c74ad2cc47c9e771c312047a28cca8a46be21e3a07cbe91fae`
- Included H.265 derivative: 177 video frames, 184,131 bytes, SHA-256
  `742233f83acc33895d2059b6fef0e635bfb8f858a7f66e012e351bfd369761a0`
- Color interpretation: BT.709 primaries, transfer, and matrix; limited range;
  left chroma location

The original was resized, frame-rate normalized, stripped of audio, and
transcoded from Theora to constrained-baseline H.264 for this demo:

```bash
ffmpeg -copyts -start_at_zero -i Big_Buck_Bunny_8_seconds_bird_clip.ogv \
  -map 0:v:0 -an \
  -vf 'setpts=PTS-STARTPTS,fps=24,scale=480:270:flags=lanczos' \
  -r 24 -c:v libx264 -preset slow -crf 23 -pix_fmt yuv420p \
  -profile:v baseline -level:v 3.0 \
  -x264-params 'keyint=48:min-keyint=48:scenecut=0:repeat-headers=1:colorprim=bt709:transfer=bt709:colormatrix=bt709:range=limited' \
  -f h264 big_buck_bunny_bird.h264
```

The H.265/HEVC derivative was generated independently from the same original:

```bash
ffmpeg -copyts -start_at_zero -i Big_Buck_Bunny_8_seconds_bird_clip.ogv \
  -map 0:v:0 -an \
  -vf 'setpts=PTS-STARTPTS,fps=24,scale=480:270:flags=lanczos' \
  -r 24 -c:v libx265 -preset slow -crf 25 -pix_fmt yuv420p \
  -profile:v main -level:v 3.0 \
  -color_primaries bt709 -color_trc bt709 -colorspace bt709 \
  -color_range tv -chroma_sample_location left \
  -x265-params 'keyint=48:min-keyint=48:scenecut=0:repeat-headers=1:colorprim=bt709:transfer=bt709:colormatrix=bt709:range=limited' \
  -f hevc big_buck_bunny_bird.h265
```

This project is not endorsed by the Blender Foundation.

[source]: https://commons.wikimedia.org/wiki/File:Big_Buck_Bunny_8_seconds_bird_clip.ogv
[license]: https://creativecommons.org/licenses/by/3.0/

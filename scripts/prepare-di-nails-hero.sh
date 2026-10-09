#!/usr/bin/env bash
# DI NAILS: create browser-compatible MP4 from the uploaded MOV at publish time.
set -euo pipefail

source_mov="DI_NAILS_Hero_6s_Smooth_60fps.mov"
output_dir="${1:-_site}"
output_mp4="${output_dir}/DI_NAILS_Hero_6s_Smooth_60fps.mp4"

test -s "$source_mov" || { echo "::error::DI NAILS hero MOV is missing"; exit 1; }
command -v ffmpeg >/dev/null || { echo "::error::ffmpeg is required to package the DI NAILS hero"; exit 1; }
command -v ffprobe >/dev/null || { echo "::error::ffprobe is required to validate the DI NAILS hero"; exit 1; }
mkdir -p "$output_dir"

codec="$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 "$source_mov")"
pixel_format="$(ffprobe -v error -select_streams v:0 -show_entries stream=pix_fmt -of default=nokey=1:noprint_wrappers=1 "$source_mov")"

if [[ "$codec" == "h264" && "$pixel_format" == "yuv420p" ]]; then
  # Only remux: keep the original 60 fps frames and their exact quality.
  ffmpeg -hide_banner -loglevel error -nostdin -y -i "$source_mov" -map 0:v:0 -an -c:v copy -movflags +faststart "$output_mp4"
else
  # Convert incompatible codecs to widely supported H.264 / 4:2:0.
  ffmpeg -hide_banner -loglevel error -nostdin -y -i "$source_mov" -map 0:v:0 -an -c:v libx264 -preset fast -crf 19 -pix_fmt yuv420p -movflags +faststart "$output_mp4"
fi

test -s "$output_mp4"
out_codec="$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 "$output_mp4")"
out_pixel_format="$(ffprobe -v error -select_streams v:0 -show_entries stream=pix_fmt -of default=nokey=1:noprint_wrappers=1 "$output_mp4")"
fps="$(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=nokey=1:noprint_wrappers=1 "$output_mp4")"
duration="$(ffprobe -v error -show_entries format=duration -of default=nokey=1:noprint_wrappers=1 "$output_mp4")"
[[ "$out_codec" == "h264" && "$out_pixel_format" == "yuv420p" ]] || { echo "::error::Hero output is not compatible H.264/yuv420p"; exit 1; }
awk -v fps="$fps" -v duration="$duration" 'BEGIN {
  split(fps, f, "/"); rate=f[1]/(f[2] ? f[2] : 1);
  if (rate < 59.5 || rate > 60.5 || duration < 5.8 || duration > 6.2) exit 1
}' || { echo "::error::Hero output is not approximately 6s at 60fps (got $duration sec, $fps fps)"; exit 1; }
echo "DI NAILS hero ready: $output_mp4 ($duration seconds; $fps fps; H.264)"

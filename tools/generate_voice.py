"""Generate prototype Chinese voice lines with the local Windows SAPI voice.

Huihui Desktop is used because it is the only zh-CN SAPI voice on this machine.
SAPI output is fine for a prototype but Microsoft does not give a clear
commercial redistribution grant; replace these files with a licensed voice
actor or a paid TTS tier before a commercial release.
"""
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "audio" / "voice" / "zh_cn"
OUT.mkdir(parents=True, exist_ok=True)

LINES = [
    ("luchen_mission", "昌子，你终于回来了。档案馆的灯还亮着，说明世界还没彻底忘记我们。名册被撕走了三页，散落在墨雨档案馆、呼吸废墟和无光海。没有名册，死者会忘记自己的名字。去吧，第一页在墨雨档案馆的封印库里。"),
    ("ch1_intro", "名册被撕走了三页。第一页还在档案馆深处。昌子，我连自己的名字都只剩一半。那就从别人的名字开始找。"),
    ("ch1_outro", "墨骸史官倒下时，散落的纸页拼出半页名册。上面有一个被反复涂改的名字：昌子。"),
    ("ch2_intro", "呼吸废墟的肺钟每响一次，就有一段记忆被呼出体外。跟紧我留下的灯。别在雾里回头。如果回头呢？那你会看见自己忘记的人。"),
    ("ch2_outro", "肺钟守卫说，还给我，那是我的名字。钟声停了，雾里浮出第二页名册。"),
    ("ch3_intro", "无光海上没有倒影。你看见的每一张脸，都是别人丢失的。昌子，你终于走到这里。名册的最后一页，写的是你。那我还需要找回什么？选择由谁来写下一页。"),
    ("ch3_outro", "最后的读者合上书，把最后一页交给你。海面裂开，露出一座仍在鼓掌的剧场。"),
    ("ch4_intro", "剧场里坐满了纸人，它们只为最后一页鼓掌。笑面史官说，你终于来了，我等你写这一页，等了很久。昌子问，你是谁？他笑着说，一个记得你所有名字的人。"),
    ("ch4_outro", "笑面史官问，你记得自己是谁吗？昌子说，我记得我选择记住谁。"),
    ("boss_ink_phase2", "把名字还给我。"),
    ("boss_ink_phase3", "这一页，不该有你。"),
    ("boss_reader_phase2", "读下去……读下去……"),
    ("boss_reader_phase3", "这一页，也是你写的。"),
    ("boss_lung_phase2", "呼……吸……呼……"),
    ("boss_lung_phase3", "别停下……钟声……"),
    ("boss_smiling_phase2", "你写得很好，昌子。"),
    ("boss_smiling_phase3", "现在，轮到我写了。"),
    ("ending_restored", "三页名册重新对齐。失踪者的名字回到纸上，昌子的名字也终于有了下一行。最后的档案馆亮起了灯。"),
    ("ending_burned", "名册在无光海上烧了三天三夜。世界失去了历史，但从此没有人能用过去命令任何人。"),
    ("ending_abyss", "你写下最后一页时，墨自己动了起来。昌子成为污染的一部分，也成为唯一还记得世界的人。"),
    ("ending_unfinished", "名册补全了，却仍有一页空白。昌子合上档案，知道下一次潮水会带来新的名字。"),
    ("ending_interrupted", "污染吞没了这一页。昌子的名字从档案中淡去，但记忆碎片已经被写下。"),
]

payload = [{"id": line_id, "text": text} for line_id, text in LINES]
(ROOT / "tools" / "voice_lines.json").write_text(
    json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8-sig"
)

ps1 = r'''Add-Type -AssemblyName System.Speech
$lines = Get-Content -Raw -Encoding UTF8 (Join-Path $PSScriptRoot 'voice_lines.json') | ConvertFrom-Json
$outDir = Join-Path $PSScriptRoot '..\assets\audio\voice\zh_cn'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$s = New-Object System.Speech.Synthesis.SpeechSynthesizer
$s.SelectVoice('Microsoft Huihui Desktop')
$s.Rate = -1
$s.Volume = 100
$format = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(22050, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
foreach ($line in $lines) {
  $path = Join-Path $outDir ($line.id + '.wav')
  Remove-Item $path -ErrorAction Ignore
  $s.SetOutputToWaveFile($path, $format)
  $s.Speak($line.text)
}
$s.Dispose()
'''
script_path = ROOT / "tools" / "generate_voice.ps1"
script_path.write_text(ps1, encoding="utf-8-sig")
subprocess.run(["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(script_path)], check=True)

for line_id, _ in LINES:
    wav = OUT / f"{line_id}.wav"
    if not wav.exists():
        print("MISSING", line_id)
        continue
    ogg = OUT / f"{line_id}.ogg"
    filters = "highpass=f=85,lowpass=f=7000,aecho=0.8:0.6:90:0.2,loudnorm=I=-18:TP=-1.5:LRA=7"
    if line_id.startswith("boss_"):
        filters = "asetrate=22050*0.9,aresample=22050,atempo=1.12," + filters
    subprocess.run([
        "ffmpeg", "-y", "-loglevel", "error", "-i", str(wav),
        "-af", filters, "-ac", "1", "-ar", "24000",
        "-c:a", "libvorbis", "-q:a", "3", str(ogg),
    ], check=True)
    wav.unlink(missing_ok=True)
    print(f"{line_id}.ogg  {ogg.stat().st_size / 1024:.0f} KiB")

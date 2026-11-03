Add-Type -AssemblyName System.Speech
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

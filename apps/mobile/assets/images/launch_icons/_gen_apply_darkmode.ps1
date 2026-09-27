# Takwa launcher icon (final): dark-mode gradient background + the raw
# takwa_transparent_bg.png wordmark (tagline included) as the emblem.
#   - takwa_icon_master.png : 1024 composite (gradient bg + wordmark at 16% inset)
#                             -> used for legacy Android + iOS (image_path)
#   - takwa_icon_bg.png     : 1024 gradient only -> adaptive background layer
# The adaptive foreground layer uses assets/images/takwa_transparent_bg.png directly.
Add-Type -AssemblyName System.Drawing
$img = "C:\Projects\takwa\apps\mobile\assets\images"
$out = Join-Path $img "launch_icons"
New-Item -ItemType Directory -Force -Path $out | Out-Null
$src = New-Object System.Drawing.Bitmap (Join-Path $img "takwa_transparent_bg.png")

function Hex([string]$h){ $h=$h.TrimStart('#'); $o=New-Object psobject
  $o|Add-Member NoteProperty R ([Convert]::ToInt32($h.Substring(0,2),16))
  $o|Add-Member NoteProperty G ([Convert]::ToInt32($h.Substring(2,2),16))
  $o|Add-Member NoteProperty B ([Convert]::ToInt32($h.Substring(4,2),16)); return $o }
function C($hex){ $x=Hex $hex; [System.Drawing.Color]::FromArgb($x.R,$x.G,$x.B) }
function Fill-Bg($g,$S){
  $blend=New-Object System.Drawing.Drawing2D.ColorBlend
  $blend.Colors=[System.Drawing.Color[]]@((C '111827'),(C '0D1117'),(C '04011E'))
  $blend.Positions=[double[]]@(0.0,0.55,1.0)
  $b=[System.Drawing.Drawing2D.LinearGradientBrush]::new((New-Object System.Drawing.Rectangle 0,0,$S,$S),(C '000000'),(C 'FFFFFF'),[System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
  $b.InterpolationColors=$blend; $g.FillRectangle($b,(New-Object System.Drawing.Rectangle 0,0,$S,$S)); $b.Dispose() }

$S=1024
# master = gradient + raw wordmark at 16% inset (matches the adaptive composite)
$m=New-Object System.Drawing.Bitmap ($S,$S,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g=[System.Drawing.Graphics]::FromImage($m); $g.SmoothingMode='AntiAlias'; $g.InterpolationMode='HighQualityBicubic'; $g.PixelOffsetMode='HighQuality'
Fill-Bg $g $S
$ins=[int]($S*0.16); $d=$S-2*$ins
$g.DrawImage($src,$ins,$ins,$d,$d); $g.Dispose()
$m.Save((Join-Path $out "takwa_icon_master.png"),[System.Drawing.Imaging.ImageFormat]::Png); $m.Dispose()

# bg layer = gradient only
$bg=New-Object System.Drawing.Bitmap ($S,$S,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g=[System.Drawing.Graphics]::FromImage($bg); Fill-Bg $g $S; $g.Dispose()
$bg.Save((Join-Path $out "takwa_icon_bg.png"),[System.Drawing.Imaging.ImageFormat]::Png); $bg.Dispose()

$src.Dispose(); Write-Output "DONE"

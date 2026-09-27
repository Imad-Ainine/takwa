# Apply chosen launcher (C: Takwa dark-mode gradient background + gold wordmark).
# Emits into a build-time-only folder (assets/images/launch_icons/ is NOT bundled:
# Flutter's `assets/images/` glob does not recurse into subdirectories).
Add-Type -AssemblyName System.Drawing
$img = "C:\Projects\takwa\apps\mobile\assets\images"
$out = Join-Path $img "launch_icons"
New-Item -ItemType Directory -Force -Path $out | Out-Null
$src = New-Object System.Drawing.Bitmap (Join-Path $img "takwa_transparent_bg.png")

function Hex([string]$h){ $h=$h.TrimStart('#'); $o=New-Object psobject
  $o|Add-Member NoteProperty R ([Convert]::ToInt32($h.Substring(0,2),16))
  $o|Add-Member NoteProperty G ([Convert]::ToInt32($h.Substring(2,2),16))
  $o|Add-Member NoteProperty B ([Convert]::ToInt32($h.Substring(4,2),16)); return $o }
function Lerp($a,$b,$t){ $o=New-Object psobject
  $o|Add-Member NoteProperty R ([int]($a.R+($b.R-$a.R)*$t))
  $o|Add-Member NoteProperty G ([int]($a.G+($b.G-$a.G)*$t))
  $o|Add-Member NoteProperty B ([int]($a.B+($b.B-$a.B)*$t)); return $o }
function C($hex){ $x=Hex $hex; [System.Drawing.Color]::FromArgb($x.R,$x.G,$x.B) }
function New-Emblem([int]$ew,[int]$eh,[int]$cy0,[int]$cy1){
  $sw=$src.Width; $sh=$cy1-$cy0
  $bmp=New-Object System.Drawing.Bitmap ($ew,$eh,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $gg=[System.Drawing.Graphics]::FromImage($bmp)
  $gg.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $gg.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $gg.DrawImage($src,(New-Object System.Drawing.Rectangle 0,0,$ew,$eh),(New-Object System.Drawing.Rectangle 0,$cy0,$sw,$sh),[System.Drawing.GraphicsUnit]::Pixel); $gg.Dispose()
  $top=Hex 'E4C98A'; $bot=Hex 'B8920E'
  $dd=$bmp.LockBits((New-Object System.Drawing.Rectangle 0,0,$ew,$eh),[System.Drawing.Imaging.ImageLockMode]::ReadWrite,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $stride=$dd.Stride; $buf=New-Object 'byte[]' ($stride*$eh)
  [System.Runtime.InteropServices.Marshal]::Copy($dd.Scan0,$buf,0,$buf.Length)
  for($y=0;$y -lt $eh;$y++){ $t=$y/($eh-1); $c=Lerp $top $bot $t; $row=$y*$stride
    for($x=0;$x -lt $ew;$x++){ $i=$row+$x*4; if($buf[$i+3] -ne 0){ $buf[$i+0]=[byte]$c.B; $buf[$i+1]=[byte]$c.G; $buf[$i+2]=[byte]$c.R } } }
  [System.Runtime.InteropServices.Marshal]::Copy($buf,0,$dd.Scan0,$buf.Length); $bmp.UnlockBits($dd); return $bmp }
function Fill-Bg($g,$S){
  $blend=New-Object System.Drawing.Drawing2D.ColorBlend
  $blend.Colors=[System.Drawing.Color[]]@((C '111827'),(C '0D1117'),(C '04011E'))
  $blend.Positions=[double[]]@(0.0,0.55,1.0)
  $b=[System.Drawing.Drawing2D.LinearGradientBrush]::new((New-Object System.Drawing.Rectangle 0,0,$S,$S),(C '000000'),(C 'FFFFFF'),[System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
  $b.InterpolationColors=$blend; $g.FillRectangle($b,(New-Object System.Drawing.Rectangle 0,0,$S,$S)); $b.Dispose() }

$S=1024; $cy0=660; $cy1=1150; $aspect=$src.Width/($cy1-$cy0)

# master (opaque): bg + wordmark at 0.72
$m=New-Object System.Drawing.Bitmap ($S,$S,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g=[System.Drawing.Graphics]::FromImage($m); $g.SmoothingMode='AntiAlias'; $g.InterpolationMode='HighQualityBicubic'
Fill-Bg $g $S
$ew=[int]($S*0.72); $eh=[int]($ew/$aspect); $em=New-Emblem $ew $eh $cy0 $cy1
$g.DrawImage($em,[int](($S-$ew)/2),[int](($S-$eh)/2),$ew,$eh); $em.Dispose(); $g.Dispose()
$m.Save((Join-Path $out "takwa_icon_master.png"),[System.Drawing.Imaging.ImageFormat]::Png); $m.Dispose()

# bg layer (opaque): gradient only
$bg=New-Object System.Drawing.Bitmap ($S,$S,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g=[System.Drawing.Graphics]::FromImage($bg); Fill-Bg $g $S; $g.Dispose()
$bg.Save((Join-Path $out "takwa_icon_bg.png"),[System.Drawing.Imaging.ImageFormat]::Png); $bg.Dispose()

# fg layer (transparent): safe-zoned wordmark at 0.46
$fg=New-Object System.Drawing.Bitmap ($S,$S,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g=[System.Drawing.Graphics]::FromImage($fg); $g.SmoothingMode='AntiAlias'; $g.InterpolationMode='HighQualityBicubic'
$ew2=[int]($S*0.46); $eh2=[int]($ew2/$aspect); $em2=New-Emblem $ew2 $eh2 $cy0 $cy1
$g.DrawImage($em2,[int](($S-$ew2)/2),[int](($S-$eh2)/2),$ew2,$eh2); $em2.Dispose(); $g.Dispose()
$fg.Save((Join-Path $out "takwa_icon_fg.png"),[System.Drawing.Imaging.ImageFormat]::Png); $fg.Dispose()

$src.Dispose(); Write-Output "DONE apply"

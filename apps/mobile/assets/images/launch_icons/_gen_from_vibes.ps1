# Regenerates the Takwa launcher icon from the repo-root vibes.png artwork.
#
#   vibes.png --(soft R-B key)--> gold art on transparency
#   master 1024, art at 620px  -> assets/images/launch_icons/takwa_icon_master.png
#                                 (the only image flutter_launcher_icons reads: iOS + legacy mipmaps)
#   layers 108..432, art at 440px (the 66dp adaptive safe circle)
#                              -> android/.../drawable-<dpi>/ic_launcher_{background,foreground,monochrome}.png
#
# mipmap-anydpi-v26/ic_launcher.xml is hand-maintained: the plugin only writes it when
# adaptive_icon_background/foreground are set, and this project deliberately omits them.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File assets/images/launch_icons/_gen_from_vibes.ps1
#   dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'
$launchDir = Split-Path -Parent $PSCommandPath
$mobile    = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $launchDir))
$source    = Join-Path (Split-Path -Parent (Split-Path -Parent $mobile)) 'vibes.png'
$res       = Join-Path $mobile 'android/app/src/main/res'
$densities = [ordered]@{ mdpi = 108; hdpi = 162; xhdpi = 216; xxhdpi = 324; xxxhdpi = 432 }
$masterArt = 620
$safeArt   = 440

function Save-Image([System.Drawing.Bitmap]$bmp, [string]$path) {
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  Write-Output "wrote $path"
}

function New-Gradient([int]$size, $top, $bottom) {
  $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
  $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $rect, $top, $bottom, [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
  $g.FillRectangle($brush, $rect)
  $g.Dispose()
  return $bmp
}

# Gold on navy separates cleanly on the red-minus-blue channel; the soft band keeps the
# grunge edges anti-aliased instead of stair-stepping them.
function Get-Art([System.Drawing.Bitmap]$src, [switch]$white) {
  $out = New-Object System.Drawing.Bitmap($src.Width, $src.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  for ($y = 0; $y -lt $src.Height; $y++) {
    for ($x = 0; $x -lt $src.Width; $x++) {
      $p = $src.GetPixel($x, $y)
      $a = [Math]::Min(255, [Math]::Max(0, [int]((($p.R - $p.B) - 8) * 255 / 24)))
      if ($white) {
        $out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($a, 255, 255, 255))
      } else {
        $out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($a, $p.R, $p.G, $p.B))
      }
    }
  }
  return $out
}

function New-Composed([int]$size, $bg, [System.Drawing.Bitmap]$art, [int]$artSize) {
  $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.Clear([System.Drawing.Color]::Transparent)
  if ($null -ne $bg) { $g.DrawImage($bg, 0, 0, $size, $size) }
  $len = [int]($size * $artSize / 1024)
  $off = [int](($size - $len) / 2)
  $g.DrawImage($art, $off, $off, $len, $len)
  $g.Dispose()
  return $bmp
}

$vibes = New-Object System.Drawing.Bitmap($source)
$top = $vibes.GetPixel(2, 2)
$bottom = $vibes.GetPixel(2, $vibes.Height - 3)
Write-Output "source $source $($vibes.Width)x$($vibes.Height) navy $($top.R),$($top.G),$($top.B) -> $($bottom.R),$($bottom.G),$($bottom.B)"

$art = Get-Art $vibes
$whiteArt = Get-Art $vibes -white
$bg = New-Gradient 1024 $top $bottom

Save-Image (New-Composed 1024 $bg $art $masterArt) (Join-Path $launchDir 'takwa_icon_master.png')
foreach ($dpi in $densities.Keys) {
  $px = $densities[$dpi]
  $dir = Join-Path $res "drawable-$dpi"
  Save-Image (New-Gradient $px $top $bottom)              (Join-Path $dir 'ic_launcher_background.png')
  Save-Image (New-Composed $px $null $art $safeArt)       (Join-Path $dir 'ic_launcher_foreground.png')
  Save-Image (New-Composed $px $null $whiteArt $safeArt)  (Join-Path $dir 'ic_launcher_monochrome.png')
}
$vibes.Dispose(); $art.Dispose(); $whiteArt.Dispose(); $bg.Dispose()

# Draws curseforge/logo.png (400x400): a white skull over a list on a dark red background.
# Run: powershell -ExecutionPolicy Bypass -File curseforge\make-logo.ps1
Add-Type -AssemblyName System.Drawing

$size = 400
$bmp = New-Object System.Drawing.Bitmap $size, $size
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

function Color($hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }
function RoundRect($x, $y, $w, $h, $r) {
	$p = New-Object System.Drawing.Drawing2D.GraphicsPath
	$p.AddArc($x, $y, 2 * $r, 2 * $r, 180, 90)
	$p.AddArc($x + $w - 2 * $r, $y, 2 * $r, 2 * $r, 270, 90)
	$p.AddArc($x + $w - 2 * $r, $y + $h - 2 * $r, 2 * $r, 2 * $r, 0, 90)
	$p.AddArc($x, $y + $h - 2 * $r, 2 * $r, 2 * $r, 90, 90)
	$p.CloseFigure()
	return $p
}

# Background: dark red, lighter in the middle
$g.Clear((Color '#1a0709'))
$bg = New-Object System.Drawing.Drawing2D.GraphicsPath
$bg.AddEllipse(-80, -80, 560, 560)
$radial = New-Object System.Drawing.Drawing2D.PathGradientBrush $bg
$radial.CenterColor = (Color '#9b1c24')
$radial.SurroundColors = @((Color '#1a0709'))
$g.FillPath($radial, $bg)

# List card behind the skull
$card = RoundRect 70 196 260 160 18
$g.FillPath((New-Object System.Drawing.SolidBrush (Color '#f1ece4')), $card)
$lineBrush = New-Object System.Drawing.SolidBrush (Color '#2b2b30')
$redBrush = New-Object System.Drawing.SolidBrush (Color '#e5484d')
foreach ($i in 0..2) {
	$y = 262 + $i * 30
	$g.FillEllipse($redBrush, 98, $y - 7, 14, 14)
	$g.FillPath($lineBrush, (RoundRect 124 ($y - 5) (170 - $i * 34) 10 5))
}

# Skull
$white = New-Object System.Drawing.SolidBrush (Color '#ffffff')
$dark = New-Object System.Drawing.SolidBrush (Color '#1a0709')
$outline = New-Object System.Drawing.Pen ((Color '#1a0709'), 10)
$skull = New-Object System.Drawing.Drawing2D.GraphicsPath ([System.Drawing.Drawing2D.FillMode]::Winding)
$skull.AddEllipse(110, 36, 180, 168)
$skull.AddPath((RoundRect 148 150 104 82 22), $false)
# Outline first, then fill: the fill hides the inner edges where head and jaw overlap
$g.DrawPath($outline, $skull)
$g.FillPath($white, $skull)
$g.FillEllipse($dark, 140, 104, 50, 50)
$g.FillEllipse($dark, 210, 104, 50, 50)
$nose = [System.Drawing.Point[]]@((New-Object System.Drawing.Point 200, 158), (New-Object System.Drawing.Point 188, 182), (New-Object System.Drawing.Point 212, 182))
$g.FillPolygon($dark, $nose)
$tooth = New-Object System.Drawing.Pen ((Color '#1a0709'), 5)
foreach ($x in 176, 200, 224) { $g.DrawLine($tooth, $x, 200, $x, 228) }

$out = Join-Path $PSScriptRoot 'logo.png'
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Output $out

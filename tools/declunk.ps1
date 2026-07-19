param([int]$NeutralTol = 18, [int]$LightMin = 178)
Add-Type -AssemblyName System.Drawing
$code = @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class Declunk {
  // ลบพิกเซลสีเทากลาง+สว่าง (checkerboard) ที่ยังทึบอยู่ทั้งภาพ — เก็บช่องในที่ flood-fill เข้าไม่ถึง
  public static int Clean(string path, int neutralTol, int lightMin) {
    int removed = 0;
    using (var bmp = new Bitmap(path)) {
      int w = bmp.Width, h = bmp.Height;
      var rect = new Rectangle(0,0,w,h);
      var data = bmp.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
      int stride = data.Stride, bytes = Math.Abs(stride) * h;
      byte[] buf = new byte[bytes];
      Marshal.Copy(data.Scan0, buf, 0, bytes);
      for (int i = 0; i < bytes; i += 4) {
        if (buf[i+3] == 0) continue;
        int b = buf[i], g = buf[i+1], r = buf[i+2];
        int mx = Math.Max(r, Math.Max(g, b)), mn = Math.Min(r, Math.Min(g, b));
        if ((mx - mn) <= neutralTol && mn >= lightMin) { buf[i+3] = 0; removed++; }
      }
      Marshal.Copy(buf, 0, data.Scan0, bytes);
      bmp.UnlockBits(data);
      // save to temp then replace (avoid file lock)
      string tmp = path + ".tmp.png";
      bmp.Save(tmp, ImageFormat.Png);
      bmp.Dispose();
      System.IO.File.Delete(path);
      System.IO.File.Move(tmp, path);
    }
    return removed;
  }
}
"@
Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing
$dir = "D:\classroom-p18\practice\img\plants"
foreach ($f in Get-ChildItem "$dir\*.png") {
  $n = [Declunk]::Clean($f.FullName, $NeutralTol, $LightMin)
  Write-Output ("{0,-18} ลบเพิ่ม {1} พิกเซล" -f $f.Name, $n)
}

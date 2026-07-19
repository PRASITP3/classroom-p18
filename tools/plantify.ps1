param(
  [string]$Src,
  [string]$DestName,
  [int]$Max = 512,
  [int]$NeutralTol = 24,
  [int]$LightMin = 168
)
$destDir = "D:\classroom-p18\practice\img\plants"
if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force $destDir | Out-Null }
$dest = Join-Path $destDir $DestName

Add-Type -AssemblyName System.Drawing
$code = @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class Plantify {
  public static void Process(string src, string dest, int max, int neutralTol, int lightMin) {
    using (var orig = new Bitmap(src)) {
      int w = orig.Width, h = orig.Height;
      var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
      using (var g = Graphics.FromImage(bmp)) { g.DrawImage(orig, 0, 0, w, h); }
      var rect = new Rectangle(0,0,w,h);
      var data = bmp.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
      int stride = data.Stride;
      int bytes = Math.Abs(stride) * h;
      byte[] buf = new byte[bytes];
      Marshal.Copy(data.Scan0, buf, 0, bytes);
      bool[] visited = new bool[w*h];
      var q = new Queue<int>();
      for(int x=0;x<w;x++){ Seed(buf,visited,q,x,0,w,stride,neutralTol,lightMin); Seed(buf,visited,q,x,h-1,w,stride,neutralTol,lightMin); }
      for(int y=0;y<h;y++){ Seed(buf,visited,q,0,y,w,stride,neutralTol,lightMin); Seed(buf,visited,q,w-1,y,w,stride,neutralTol,lightMin); }
      int[] dx = {1,-1,0,0}; int[] dy = {0,0,1,-1};
      while(q.Count>0){
        int idx=q.Dequeue();
        int x=idx%w, y=idx/w;
        buf[y*stride + x*4 + 3] = 0;
        for(int k=0;k<4;k++){
          int nx=x+dx[k], ny=y+dy[k];
          if(nx<0||ny<0||nx>=w||ny>=h) continue;
          Seed(buf,visited,q,nx,ny,w,stride,neutralTol,lightMin);
        }
      }
      // global pass: ลบช่องในที่เป็น checkerboard (สีเทากลาง+สว่าง) ที่ flood-fill จากขอบเข้าไม่ถึง
      for(int i=0;i<bytes;i+=4){
        if(buf[i+3]==0) continue;
        int b2=buf[i], g2=buf[i+1], r2=buf[i+2];
        int mx2=Math.Max(r2,Math.Max(g2,b2)), mn2=Math.Min(r2,Math.Min(g2,b2));
        if((mx2-mn2)<=neutralTol && mn2>=lightMin){ buf[i+3]=0; }
      }
      Marshal.Copy(buf,0,data.Scan0,bytes);
      bmp.UnlockBits(data);
      double scale=Math.Min((double)max/w,(double)max/h); if(scale>1) scale=1;
      int nw=(int)Math.Round(w*scale), nh=(int)Math.Round(h*scale);
      var outb=new Bitmap(nw,nh,PixelFormat.Format32bppArgb);
      using(var g=Graphics.FromImage(outb)){
        g.InterpolationMode=InterpolationMode.HighQualityBicubic;
        g.SmoothingMode=SmoothingMode.HighQuality;
        g.PixelOffsetMode=PixelOffsetMode.HighQuality;
        g.Clear(Color.Transparent);
        g.DrawImage(bmp,0,0,nw,nh);
      }
      outb.Save(dest, ImageFormat.Png);
      outb.Dispose(); bmp.Dispose();
    }
  }
  static void Seed(byte[] buf, bool[] visited, Queue<int> q, int x, int y, int w, int stride, int neutralTol, int lightMin){
    int idx=y*w+x;
    if(visited[idx]) return;
    int p=y*stride+x*4;
    int b=buf[p], gg=buf[p+1], r=buf[p+2];
    int mx=Math.Max(r,Math.Max(gg,b)), mn=Math.Min(r,Math.Min(gg,b));
    if((mx-mn)<=neutralTol && mn>=lightMin){ visited[idx]=true; q.Enqueue(idx); }
  }
}
"@
Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing

[Plantify]::Process($Src, $dest, $Max, $NeutralTol, $LightMin)
$size = [Math]::Round((Get-Item $dest).Length / 1KB, 1)
Write-Output "OK: $DestName  (${size} KB, transparent)"

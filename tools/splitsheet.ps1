param(
  [string]$Src,
  [string]$OutDir,
  [int]$Max = 512,
  [int]$NeutralTol = 18,
  [int]$LightMin = 178,
  [int]$EmptyThr = 3,     # คอลัมน์/แถวที่มีพิกเซลทึบ <= ค่านี้ = ช่องว่าง
  [int]$MinBand = 24      # แถบเนื้อหาต้องกว้าง/สูงอย่างน้อยเท่านี้ (กันจุดรบกวน)
)
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force $OutDir | Out-Null }
Get-ChildItem "$OutDir\*.png" -ErrorAction SilentlyContinue | Remove-Item -Force
Add-Type -AssemblyName System.Drawing
$code = @"
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
public static class SplitSheet {
  public static int Run(string src, string outDir, int max, int neutralTol, int lightMin, int emptyThr, int minBand) {
    using (var orig = new Bitmap(src)) {
      int w = orig.Width, h = orig.Height;
      var bmp = new Bitmap(w, h, PixelFormat.Format32bppArgb);
      using (var g = Graphics.FromImage(bmp)) { g.DrawImage(orig, 0, 0, w, h); }
      var rect = new Rectangle(0,0,w,h);
      var data = bmp.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
      int stride = data.Stride, bytes = Math.Abs(stride)*h;
      byte[] buf = new byte[bytes];
      Marshal.Copy(data.Scan0, buf, 0, bytes);
      // --- ลบพื้นหลัง checkerboard: flood-fill จากขอบ + global pass ---
      bool[] vis = new bool[w*h];
      var q = new Queue<int>();
      for(int x=0;x<w;x++){ Seed(buf,vis,q,x,0,w,stride,neutralTol,lightMin); Seed(buf,vis,q,x,h-1,w,stride,neutralTol,lightMin); }
      for(int y=0;y<h;y++){ Seed(buf,vis,q,0,y,w,stride,neutralTol,lightMin); Seed(buf,vis,q,w-1,y,w,stride,neutralTol,lightMin); }
      int[] dx={1,-1,0,0}, dy={0,0,1,-1};
      while(q.Count>0){ int idx=q.Dequeue(); int x=idx%w,y=idx/w; buf[y*stride+x*4+3]=0;
        for(int k=0;k<4;k++){ int nx=x+dx[k],ny=y+dy[k]; if(nx<0||ny<0||nx>=w||ny>=h) continue; Seed(buf,vis,q,nx,ny,w,stride,neutralTol,lightMin); } }
      for(int i=0;i<bytes;i+=4){ if(buf[i+3]==0) continue; int b=buf[i],gg=buf[i+1],r=buf[i+2];
        int mx=Math.Max(r,Math.Max(gg,b)), mn=Math.Min(r,Math.Min(gg,b)); if((mx-mn)<=neutralTol && mn>=lightMin) buf[i+3]=0; }
      // --- หาแถบแถว (row bands) ---
      int idxOut = 0;
      var rowBands = Bands(RowCounts(buf,w,h,stride), emptyThr, minBand);
      foreach(var rb in rowBands){
        int y0=rb[0], y1=rb[1];
        var colBands = Bands(ColCounts(buf,w,h,stride,y0,y1), emptyThr, minBand);
        foreach(var cb in colBands){
          int x0=cb[0], x1=cb[1];
          // หา bbox แน่นภายใน (y0..y1, x0..x1)
          int bx0=x1,bx1=x0,by0=y1,by1=y0; bool any=false;
          for(int y=y0;y<=y1;y++) for(int x=x0;x<=x1;x++){ if(buf[y*stride+x*4+3]>16){ any=true; if(x<bx0)bx0=x; if(x>bx1)bx1=x; if(y<by0)by0=y; if(y>by1)by1=y; } }
          if(!any) continue;
          int cw=bx1-bx0+1, ch=by1-by0+1;
          if(cw<minBand && ch<minBand) continue;
          // crop
          var crop = new Bitmap(cw, ch, PixelFormat.Format32bppArgb);
          var cd = crop.LockBits(new Rectangle(0,0,cw,ch), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);
          int cstride=cd.Stride; byte[] cbuf=new byte[Math.Abs(cstride)*ch];
          for(int y=0;y<ch;y++) for(int x=0;x<cw;x++){ int s=(by0+y)*stride+(bx0+x)*4, d=y*cstride+x*4;
            cbuf[d]=buf[s]; cbuf[d+1]=buf[s+1]; cbuf[d+2]=buf[s+2]; cbuf[d+3]=buf[s+3]; }
          Marshal.Copy(cbuf,0,cd.Scan0,cbuf.Length); crop.UnlockBits(cd);
          // ย่อให้พอดี max แบบสี่เหลี่ยมจัตุรัส (จัดกลาง)
          double sc=Math.Min((double)max/cw,(double)max/ch); if(sc>1) sc=1;
          int nw=(int)Math.Round(cw*sc), nh=(int)Math.Round(ch*sc);
          var outb=new Bitmap(max,max,PixelFormat.Format32bppArgb);
          using(var g2=Graphics.FromImage(outb)){
            g2.InterpolationMode=InterpolationMode.HighQualityBicubic; g2.SmoothingMode=SmoothingMode.HighQuality; g2.PixelOffsetMode=PixelOffsetMode.HighQuality;
            g2.Clear(Color.Transparent); g2.DrawImage(crop,(max-nw)/2,(max-nh)/2,nw,nh);
          }
          idxOut++;
          outb.Save(System.IO.Path.Combine(outDir,"part"+idxOut+".png"), ImageFormat.Png);
          outb.Dispose(); crop.Dispose();
        }
      }
      bmp.UnlockBits(data); bmp.Dispose();
      return idxOut;
    }
  }
  static int[] RowCounts(byte[] buf,int w,int h,int stride){ int[] c=new int[h]; for(int y=0;y<h;y++){int n=0; for(int x=0;x<w;x++) if(buf[y*stride+x*4+3]>16) n++; c[y]=n;} return c; }
  static int[] ColCounts(byte[] buf,int w,int h,int stride,int y0,int y1){ int[] c=new int[w]; for(int x=0;x<w;x++){int n=0; for(int y=y0;y<=y1;y++) if(buf[y*stride+x*4+3]>16) n++; c[x]=n;} return c; }
  static List<int[]> Bands(int[] counts, int emptyThr, int minBand){
    var bands=new List<int[]>(); int start=-1;
    for(int i=0;i<counts.Length;i++){
      bool content = counts[i] > emptyThr;
      if(content && start<0) start=i;
      else if(!content && start>=0){ if(i-1-start+1>=minBand) bands.Add(new int[]{start,i-1}); start=-1; }
    }
    if(start>=0 && counts.Length-start>=minBand) bands.Add(new int[]{start,counts.Length-1});
    return bands;
  }
  static void Seed(byte[] buf, bool[] vis, Queue<int> q, int x, int y, int w, int stride, int neutralTol, int lightMin){
    int idx=y*w+x; if(vis[idx]) return; int p=y*stride+x*4; int b=buf[p],gg=buf[p+1],r=buf[p+2];
    int mx=Math.Max(r,Math.Max(gg,b)), mn=Math.Min(r,Math.Min(gg,b));
    if((mx-mn)<=neutralTol && mn>=lightMin){ vis[idx]=true; q.Enqueue(idx); }
  }
}
"@
Add-Type -TypeDefinition $code -ReferencedAssemblies System.Drawing
$n = [SplitSheet]::Run($Src, $OutDir, $Max, $NeutralTol, $LightMin, $EmptyThr, $MinBand)
Write-Output "ตัดได้ $n ชิ้น -> $OutDir (part1..part$n.png)"

"""Original parchment, carved wood and brass UI textures; Python standard library."""
import math, random, struct, zlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'assets/ui'
N=256
for kind in ['parchment','wood','button']:
    rng=random.Random(142)
    pixels=bytearray(N*N*4)
    def put(x,y,c):
        if 0<=x<N and 0<=y<N:
            i=(y*N+x)*4; pixels[i:i+4]=bytes(max(0,min(255,int(v))) for v in c)
    for y in range(N):
        for x in range(N):
            edge=min(x,y,N-1-x,N-1-y)
            grain=rng.uniform(-5,5)+3*math.sin(y*.55+math.sin(x*.035)*4)+2*math.sin(y*1.9)
            if kind=='parchment':
                grain=rng.uniform(-5,5)+1.5*math.sin(x*.41+y*.73)
                stain=7*math.sin(x*.028)*math.sin(y*.036)+4*math.sin((x+y)*.1)
                shade=max(0,18-edge)*2.7
                rgb=[221+grain+stain-shade,201+grain+stain-shade,156+grain+stain-shade]
            else:
                grain+=5*math.sin(y*.14+math.sin(x*.012)*7)+3*math.sin(y*.93+x*.015)
                shade=8 if kind=='button' else 0
                rgb=[64+grain+shade,42+grain*.7+shade,27+grain*.4+shade]
                if edge<3: rgb=[31,24,17]
                elif edge<5: rgb=[155,121,71]
                elif edge<8: rgb=[88,64,35]
                elif edge<10: rgb=[35,25,17]
                elif edge<12: rgb=[131,97,54]
                elif edge<16: rgb=[46,30,18]
                elif edge<19: rgb=[93,65,38]
            if kind=='button':
                if edge<1: rgb=[29,22,16]
                elif edge<2: rgb=[160,125,74]
                elif edge<3: rgb=[91,64,35]
                elif edge<5: rgb=[42,29,19]
                else:
                    grain=rng.uniform(-3,3)+4*math.sin(y*.21+math.sin(x*.023)*3)
                    rgb=[76+grain,50+grain*.7,31+grain*.5]
            alpha=255
            if edge<2: alpha=100 if edge else 0
            put(x,y,(*rgb,alpha))
    if kind=='wood':
        # Small brass leaf scrolls stay crisp in each nine-patch corner.
        for cx,cy in [(18,18),(237,18),(18,237),(237,237)]:
            sx=1 if cx<128 else -1; sy=1 if cy<128 else -1
            for t in range(55):
                a=t*.1; r=2+t*.12
                xx=int(cx+sx*(math.cos(a)*r+7)); yy=int(cy+sy*(math.sin(a)*r+7))
                for dx,dy in [(0,0),(1,0),(0,1)]: put(xx+dx,yy+dy,(174,138,81,255))
            for j in range(10):
                for k in range(-2,3):
                    put(cx+sx*j,cy+sy*(j+k),(183,147,88,255))
    raw=b''.join(b'\0'+pixels[y*N*4:(y+1)*N*4] for y in range(N))
    def chunk(t,d): return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
    png=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',N,N,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b'')
    (ROOT/(kind+'.png')).write_bytes(png)
print('Original menu textures written')

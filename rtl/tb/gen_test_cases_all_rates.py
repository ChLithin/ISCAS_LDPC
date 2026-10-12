#!/usr/bin/env python3
"""
gen_test_cases_all_rates.py  (CORRECTED)
Base matrices exactly match RTL DSH_ localparams.
Outputs: test_cases_r1316/  test_cases_r34/  test_cases_r58/  test_cases_r12/
Each case: <label>_llr.hex  <label>_chat.txt  <label>_info.txt
Usage: python3 gen_test_cases_all_rates.py
"""
import numpy as np, os

Z=42; N=672; MAX_ITER=10; MAX_MAG=15; NUM_COLS=16

BASE = {
'r1316': np.array([
    [ 29, 30,  0,  8, 33, 22, 17,  4, 27, 28, 20, 27, 24, 23, -1, -1],
    [ 37, 31, 18, 23, 11, 21,  6, 20, 32,  9, 12, 29, 10,  0, 13, -1],
    [ 25, 22,  4, 34, 31,  3, 14, 15,  4,  2, 14, 18, 13, 22, 22, 24],
], dtype=int),
'r34': np.array([
    [ 35, 19, 41, 22, 40, 41, 39,  6, 28, 18, 17,  3, 28, -1, -1, -1],
    [ 29, 30,  0,  8, 33, 22, 17,  4, 27, 28, 20, 27, 24, 23, -1, -1],
    [ 37, 31, 18, 23, 11, 21,  6, 20, 32,  9, 12, 29, 10,  0, 13, -1],
    [ 25, 22,  4, 34, 31,  3, 14, 15,  4,  2, 14, 18, 13, 22, 22, 24],
], dtype=int),
'r58': np.array([
    [ 20, 36, 34, 31, 20,  7, 41, 34, 10, 41, -1, -1, -1, -1, -1, -1],
    [ 30, 27, 34, 31, 12, 20, 14,  2, 25, 15,  6, -1, -1, -1, -1, -1],
    [ 35, -1, 41, -1, 40, -1, 39, -1, 28, -1, -1,  3, 28, -1, -1, -1],
    [ 29, -1,  0, -1, 22, -1,  4, -1, 28, 26,  8, 27, -1,  8, 23, -1],
    [ -1, 31, 23, -1,  8, 21, 20, -1, -1, 12, -1, -1,  0, -1, 13, -1],
    [ -1, 22, -1, 34, 31, -1, -1, 14,  4, -1, -1, 18, 13, 22, 22, 24],
], dtype=int),
'r12': np.array([
    [ 40, -1, 38, -1, 13, -1,  5, -1, 18, -1, -1, -1, -1, -1, -1, -1],
    [ 34, -1, 35, -1, 27, -1, -1, -1, 30,  2,  1, -1, -1, -1, -1, -1],
    [ -1, 36, 31, -1,  7, -1, -1, -1, 34, 10, 41, -1, -1, -1, -1, -1],
    [ -1, 27, -1, 18, -1, 12, 20, -1, -1, -1, 15,  6, -1, -1, -1, -1],
    [ 35, -1, 41, -1, 40, -1, 39, -1, 28, -1, -1,  3, 28, -1, -1, -1],
    [ 29, -1,  0, -1, 22, -1,  4, -1, 28, 26,  8, 27, -1,  8, 23, -1],
    [ -1, 31, 23, -1,  8, 21, 20, -1, -1, 12, -1, -1,  0, -1, 13, -1],
    [ -1, 22, -1, 34, 31, -1, -1, 14,  4, -1, -1, 18, 13, 22, 22, 24],
], dtype=int),
}

RATE_INFO = {
    'r1316': ('test_cases_r1316', 3),
    'r34':   ('test_cases_r34',   4),
    'r58':   ('test_cases_r58',   6),
    'r12':   ('test_cases_r12',   8),
}

# Same 10 case names for all rates (must match tb_r*.v)
CASES = [
    ('allzero_snr5_seed5',    'zero',   5.0,   5),
    ('allzero_snr4_seed1',    'zero',   4.0,   1),
    ('allzero_snr4_seed2',    'zero',   4.0,   2),
    ('allzero_snr3p5_seed10', 'zero',   3.5,  10),
    ('allzero_snr3_seed7',    'zero',   3.0,   7),
    ('allzero_snr6_seed99',   'zero',   6.0,  99),
    ('random_snr5_seed42',    'random', 5.0,  42),
    ('random_snr4_seed123',   'random', 4.0, 123),
    ('random_snr6_seed7',     'random', 6.0,   7),
    ('random_snr3_seed55',    'random', 3.0,  55),
]

def build_H(base):
    nl=base.shape[0]; H=np.zeros((nl*Z,N),dtype=int)
    for l in range(nl):
        for c in range(NUM_COLS):
            s=base[l,c]
            if s<0: continue
            for n in range(Z): H[l*Z+(n-s+Z)%Z,c*Z+n]=1
    return H

def syn(H,cw): return H@cw%2

def gf2_rref(A):
    A=A.copy()%2; rows,cols=A.shape; pivots=[]; r=0
    for c in range(cols):
        found=next((rr for rr in range(r,rows) if A[rr,c]),-1)
        if found==-1: continue
        A[[r,found]]=A[[found,r]]
        for rr in range(rows):
            if rr!=r and A[rr,c]: A[rr]=(A[rr]+A[r])%2
        pivots.append(c); r+=1
    return A,pivots

_cache={}
def encode(rng,H,rk):
    if rk not in _cache: _cache[rk]=gf2_rref(H)
    A,pivots=_cache[rk]; free=sorted(set(range(N))-set(pivots))
    info=rng.integers(0,2,len(free)); cw=np.zeros(N,dtype=int)
    for i,fc in enumerate(free): cw[fc]=info[i]
    for i,pc in enumerate(pivots):
        val=sum(int(A[i,fc])*int(cw[fc]) for fc in free)%2
        cw[pc]=val
    assert syn(H,cw).sum()==0; return cw

def channel_llr(cw,snr_db,seed):
    rng=np.random.default_rng(seed); snr=10**(snr_db/10)
    sig=np.sqrt(1/(2*snr)); bpsk=1-2*cw.astype(float)
    y=bpsk+sig*rng.standard_normal(len(cw)); llr=2*y/sig**2
    return np.clip(np.round(llr).astype(int),-16,15)

def min_sum(llr_q,base,H):
    nl=base.shape[0]
    def perm(buf,sh):
        if sh<=0: return buf.copy()
        out=np.zeros_like(buf)
        for n in range(Z): out[n]=buf[(n-sh+Z)%Z]
        return out
    def dsh(l,c):
        curr=base[l,c]
        if curr<0: return -1
        if c==0: return int(curr)
        prev=next((base[l,cc] for cc in range(c-1,-1,-1) if base[l,cc]>=0),0)
        return (curr-prev+Z)%Z
    last_act=[next(c for c in range(NUM_COLS-1,-1,-1) if base[l,c]>=0) for l in range(nl)]
    first_act=[next(c for c in range(NUM_COLS) if base[l,c]>=0) for l in range(nl)]
    def vwrap(l):
        # The differential dsh() chain already re-applies (base[l,first_act[l]] - 0)
        # the moment the broadcast path re-enters the layer's first active column
        # (same physical permutation wire, fired a second time for the VN pass).
        # If first_act[l] == 0, that re-entry IS column 0 itself, so vwrap must
        # supply the (base[l,0] - base[l,last_act]) term directly.
        # If first_act[l] > 0, column 0 is bypassed and dsh() will supply the
        # +base[l,first_act[l]] term on its own when the path reaches that column
        # -- so vwrap must NOT also subtract base[l,first_act[l]], or that term
        # cancels twice and the broadcast lands one hop out of phase.
        if first_act[l] == 0:
            return (base[l,0]-base[l,last_act[l]]+Z)%Z
        else:
            return (-base[l,last_act[l]])%Z
    ls=np.zeros((NUM_COLS,Z,nl),dtype=int); lm=np.zeros((NUM_COLS,Z,nl),dtype=int)
    chat=np.zeros(N,dtype=int); ei=[]
    for it in range(1,MAX_ITER+1):
        fi=(it==1)
        sc=np.zeros((Z,nl),dtype=int); m1=np.full((Z,nl),MAX_MAG,dtype=int); m2=np.full((Z,nl),MAX_MAG,dtype=int)
        for c in range(NUM_COLS):
            for l in range(nl):
                s=dsh(l,c)
                if s>0: sc[:,l]=perm(sc[:,l],s); m1[:,l]=perm(m1[:,l],s); m2[:,l]=perm(m2[:,l],s)
            nsc=sc.copy();nm1=m1.copy();nm2=m2.copy()
            for v in range(Z):
                qv=int(llr_q[c*Z+v]);qs=1 if qv<0 else 0;qm=min(abs(qv),MAX_MAG)
                for l in range(nl):
                    if base[l,c]<0: continue
                    vs=qs if fi else int(ls[c,v,l]); vm=qm if fi else int(lm[c,v,l])
                    nsc[v,l]=int(sc[v,l])^vs
                    if vm<m1[v,l]: nm1[v,l],nm2[v,l]=vm,m1[v,l]
                    elif vm<m2[v,l]: nm1[v,l],nm2[v,l]=m1[v,l],vm
            sc,m1,m2=nsc,nm1,nm2
        sc2,m12,m22=sc.copy(),m1.copy(),m2.copy()
        nls=ls.copy();nlm=lm.copy()
        for c in range(NUM_COLS):
            for l in range(nl):
                s=vwrap(l) if c==0 else dsh(l,c)
                if s>0: sc2[:,l]=perm(sc2[:,l],s); m12[:,l]=perm(m12[:,l],s); m22[:,l]=perm(m22[:,l],s)
            for v in range(Z):
                qv=int(llr_q[c*Z+v]);qs=1 if qv<0 else 0;qm=min(abs(qv),MAX_MAG)
                Lv=qv; mcvs=[0]*nl
                for l in range(nl):
                    if base[l,c]<0: continue
                    vs=qs if fi else int(ls[c,v,l]); vm=qm if fi else int(lm[c,v,l])
                    sf=int(sc2[v,l]);m1f=int(m12[v,l]);m2f=int(m22[v,l])
                    mm=m2f if vm<=m1f else m1f
                    mv=-mm if (sf^vs) else mm
                    mcvs[l]=mv; Lv+=mv
                chat[c*Z+v]=1 if Lv<0 else 0
                for l in range(nl):
                    if base[l,c]<0: continue
                    lv=Lv-mcvs[l]; nls[c,v,l]=1 if lv<0 else 0; nlm[c,v,l]=min(abs(lv),MAX_MAG)
        ls,lm=nls,nlm
        e=int(syn(H,chat).sum()); ei.append(e)
        if e==0: break
    return chat,ei

print(f"{'Rate':<8}{'Case':<30}{'SNR':>5}{'Conv':>6}{'Iter':>5}{'BErr':>6}")
print('-'*60)
for rate,(out_dir,nl) in RATE_INFO.items():
    os.makedirs(out_dir,exist_ok=True)
    base=BASE[rate]; H=build_H(base)
    for label,cwt,snr,seed in CASES:
        rng=np.random.default_rng(seed*1000)
        cw=np.zeros(N,dtype=int) if cwt=='zero' else encode(rng,H,rate)
        llr=channel_llr(cw,snr,seed)
        chat,ei=min_sum(llr,base,H)
        conv=ei[-1]==0; iters=len(ei); be=int(np.sum(chat!=cw))
        print(f"{rate:<8}{label:<30}{snr:>5.1f}{'YES' if conv else 'NO':>6}{iters:>5}{be:>6}")
        bp=os.path.join(out_dir,label)
        with open(bp+'_llr.hex','w') as f:
            for v in llr: f.write(f'{v&0x1F:02x}\n')
        with open(bp+'_chat.txt','w') as f:
            for b in cw: f.write(f'{b}\n')
        with open(bp+'_info.txt','w') as f:
            f.write(f'rate={rate} label={label} snr={snr} seed={seed} conv={conv} iters={iters} be={be} ei={ei}\n')
print('\nDone. Vectors in test_cases_r1316/ test_cases_r34/ test_cases_r58/ test_cases_r12/')
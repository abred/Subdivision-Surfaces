//----------------------------------------------------------------------------------
// File:   InstancedTessellation.fxh
// Email:  sdkfeedback@nvidia.com
// 
// Copyright (c) 2008 NVIDIA Corporation. All rights reserved.
//
// TO  THE MAXIMUM  EXTENT PERMITTED  BY APPLICABLE  LAW, THIS SOFTWARE  IS PROVIDED
// *AS IS*  AND NVIDIA AND  ITS SUPPLIERS DISCLAIM  ALL WARRANTIES,  EITHER  EXPRESS
// OR IMPLIED, INCLUDING, BUT NOT LIMITED  TO, IMPLIED WARRANTIES OF MERCHANTABILITY
// AND FITNESS FOR A PARTICULAR PURPOSE.  IN NO EVENT SHALL  NVIDIA OR ITS SUPPLIERS
// BE  LIABLE  FOR  ANY  SPECIAL,  INCIDENTAL,  INDIRECT,  OR  CONSEQUENTIAL DAMAGES
// WHATSOEVER (INCLUDING, WITHOUT LIMITATION,  DAMAGES FOR LOSS OF BUSINESS PROFITS,
// BUSINESS INTERRUPTION, LOSS OF BUSINESS INFORMATION, OR ANY OTHER PECUNIARY LOSS)
// ARISING OUT OF THE  USE OF OR INABILITY  TO USE THIS SOFTWARE, EVEN IF NVIDIA HAS
// BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
//
//----------------------------------------------------------------------------------



// Surface evaluation
float3 EvaluateBezierPosition(float2 uv, float3 p[16])
{
    float2 B0 =     (1 - uv) * (1 - uv) * (1 - uv);
    float2 B1 = 3 * (1 - uv) * (1 - uv) * (    uv);
    float2 B2 = 3 * (    uv) * (    uv) * (1 - uv);
    float2 B3 =     (    uv) * (    uv) * (    uv);

    float3 w0 = (B0.x * p[ 0] + B1.x * p[ 1] + B2.x * p[ 2] + B3.x * p[ 3]) * B0.y;
    float3 w1 = (B0.x * p[ 4] + B1.x * p[ 5] + B2.x * p[ 6] + B3.x * p[ 7]) * B1.y;
    float3 w2 = (B0.x * p[ 8] + B1.x * p[ 9] + B2.x * p[10] + B3.x * p[11]) * B2.y;
    float3 w3 = (B0.x * p[12] + B1.x * p[13] + B2.x * p[14] + B3.x * p[15]) * B3.y;

    return w0 + w1 + w2 + w3;
}
void ComputeInteriorTangents(float3 p[16], out float3 ipu[4], out float3 ipv[4])
{
    // ipu: -->   ipv: upwards
    for (int i = 0; i < 4; i++)
    {
        ipu[i] = 3 * (p[4*i + 2] - p[4*i + 1]);
        ipv[i] = 3 * (p[4*2 + i] - p[4*1 + i]);
    }
}


float3 EvaluateBezierNormal(float2 uv, float3 ipu[4], float3 ipv[4], float3 puv[16])
{
    float2 T0 =     (1 - uv) * (1 - uv);
    float2 T1 = 2 * (1 - uv) * (    uv);
    float2 T2 =     (    uv) * (    uv);

    float2 B0 =     (1 - uv) * (1 - uv) * (1 - uv);
    float2 B1 = 3 * (1 - uv) * (1 - uv) * (    uv);
    float2 B2 = 3 * (    uv) * (    uv) * (1 - uv);
    float2 B3 =     (    uv) * (    uv) * (    uv);

    float3 du = (B0.y * puv[0] + B1.y * puv[1] + B2.y * puv[2] + B3.y * puv[3]) * T0.x +
                (B0.y * ipu[0] + B1.y * ipu[1] + B2.y * ipu[2] + B3.y * ipu[3]) * T1.x +
                (B0.y * puv[4] + B1.y * puv[5] + B2.y * puv[6] + B3.y * puv[7]) * T2.x;

    float3 dv = (B0.x * puv[0+8] + B1.x * puv[1+8] + B2.x * puv[2+8] + B3.x * puv[3+8]) * T0.y +
                (B0.x * ipv[  0] + B1.x * ipv[  1] + B2.x * ipv[  2] + B3.x * ipv[  3]) * T1.y +
                (B0.x * puv[4+8] + B1.x * puv[5+8] + B2.x * puv[6+8] + B3.x * puv[7+8]) * T2.y;

    return normalize(cross(du, dv));
}

// Evaluate bezier tangent in two steps to prevent running out of registers in D3D9.
void EvaluateBezierTangents_A(float2 uv, float3 p[16], out float3 du, out float3 dv)
{
    float2 T1 = 2 * (1 - uv) * (    uv);

    float2 B0 =     (1 - uv) * (1 - uv) * (1 - uv);
    float2 B1 = 3 * (1 - uv) * (1 - uv) * (    uv);
    float2 B2 = 3 * (    uv) * (    uv) * (1 - uv);
    float2 B3 =     (    uv) * (    uv) * (    uv);

    du = 3 * (B0.y * (p[4*0 + 2] - p[4*0 + 1]) + B1.y * (p[4*1 + 2] - p[4*1 + 1]) + B2.y * (p[4*2 + 2] - p[4*2 + 1]) + B3.y * (p[4*3 + 2] - p[4*3 + 1])) * T1.x;
    dv = 3 * (B0.x * (p[4*2 + 0] - p[4*1 + 0]) + B1.x * (p[4*2 + 1] - p[4*1 + 1]) + B2.x * (p[4*2 + 2] - p[4*1 + 2]) + B3.x * (p[4*2 + 3] - p[4*1 + 3])) * T1.y;
}

float3 EvaluateBezierNormal_B(float2 uv, float3 puv[16], float3 du, float3 dv)
{
    float2 T0 =     (1 - uv) * (1 - uv);
    float2 T2 =     (    uv) * (    uv);

    float2 B0 =     (1 - uv) * (1 - uv) * (1 - uv);
    float2 B1 = 3 * (1 - uv) * (1 - uv) * (    uv);
    float2 B2 = 3 * (    uv) * (    uv) * (1 - uv);
    float2 B3 =     (    uv) * (    uv) * (    uv);

    du += (B0.y * puv[0] + B1.y * puv[1] + B2.y * puv[2] + B3.y * puv[3]) * T0.x +
          (B0.y * puv[4] + B1.y * puv[5] + B2.y * puv[6] + B3.y * puv[7]) * T2.x;

    dv += (B0.x * puv[0+8] + B1.x * puv[1+8] + B2.x * puv[2+8] + B3.x * puv[3+8]) * T0.y +
          (B0.x * puv[4+8] + B1.x * puv[5+8] + B2.x * puv[6+8] + B3.x * puv[7+8]) * T2.y;

    return normalize(cross(du, dv));
}

// Evaluate normal using position and tangent control points.
float3 EvaluateBezierNormal(float2 uv, float3 p[16], float3 puv[16])
{
    float3 ipu[4];
    float3 ipv[4];

    ComputeInteriorTangents(p, ipu, ipv);

    return EvaluateBezierNormal(uv, ipu, ipv, puv);
}


// Evaluate normal using only position control points.
float3 EvaluateBezierNormal(float2 uv, float3 p[16])
{
    float2 T0 =     (1 - uv) * (1 - uv);
    float2 T1 = 2 * (1 - uv) * (    uv);
    float2 T2 =     (    uv) * (    uv);

    float2 B0 =     (1 - uv) * (1 - uv) * (1 - uv);
    float2 B1 = 3 * (1 - uv) * (1 - uv) * (    uv);
    float2 B2 = 3 * (    uv) * (    uv) * (1 - uv);
    float2 B3 =     (    uv) * (    uv) * (    uv);

    float3 pu[12];
    float3 pv[12];

    for (int i = 0; i < 4; i++)
    {
        pu[i+0] = 3 * (p[4*i + 1] - p[4*i + 0]);
        pv[i+0] = 3 * (p[4*1 + i] - p[4*0 + i]);

        pu[i+4] = 3 * (p[4*i + 2] - p[4*i + 1]);
        pv[i+4] = 3 * (p[4*2 + i] - p[4*1 + i]);

        pu[i+8] = 3 * (p[4*i + 3] - p[4*i + 2]);
        pv[i+8] = 3 * (p[4*3 + i] - p[4*2 + i]);
    }

    float3 du = (B0.y * pu[0] + B1.y * pu[1] + B2.y * pu[ 2] + B3.y * pu[ 3]) * T0.x +
                (B0.y * pu[4] + B1.y * pu[5] + B2.y * pu[ 6] + B3.y * pu[ 7]) * T1.x +
                (B0.y * pu[8] + B1.y * pu[9] + B2.y * pu[10] + B3.y * pu[11]) * T2.x;

    float3 dv = (B0.x * pv[0] + B1.x * pv[1] + B2.x * pv[ 2] + B3.x * pv[ 3]) * T0.y +
                (B0.x * pv[4] + B1.x * pv[5] + B2.x * pv[ 6] + B3.x * pv[ 7]) * T1.y +
                (B0.x * pv[8] + B1.x * pv[9] + B2.x * pv[10] + B3.x * pv[11]) * T2.y;

    return normalize(cross(du, dv));
}

void DeCasteljau(float u, float3 p0, float3 p1, float3 p2, float3 p3, out float3 p)
{
    float3 q0 = lerp(p0, p1, u);
    float3 q1 = lerp(p1, p2, u);
    float3 q2 = lerp(p2, p3, u);
    float3 r0 = lerp(q0, q1, u);
    float3 r1 = lerp(q1, q2, u);

    p = lerp(r0, r1, u);
}

void DeCasteljau(float u, float3 p0, float3 p1, float3 p2, float3 p3, out float3 p, out float3 dp)
{
    float3 q0 = lerp(p0, p1, u);
    float3 q1 = lerp(p1, p2, u);
    float3 q2 = lerp(p2, p3, u);
    float3 r0 = lerp(q0, q1, u);
    float3 r1 = lerp(q1, q2, u);
    
    dp = r0 - r1;
    p = lerp(r0, r1, u);
}

void EvaluateBezier(float2 uv, float3 p[16], out float3 pos, out float3 nor)
{
    float3 t0, t1, t2, t3;
    float3 p0, p1, p2, p3;

    DeCasteljau(uv.x, p[ 0], p[ 1], p[ 2], p[ 3], p0, t0);
    DeCasteljau(uv.x, p[ 4], p[ 5], p[ 6], p[ 7], p1, t1);
    DeCasteljau(uv.x, p[ 8], p[ 9], p[10], p[11], p2, t2);
    DeCasteljau(uv.x, p[12], p[13], p[14], p[15], p3, t3);

    float3 du, dv;

    DeCasteljau(uv.y, p0, p1, p2, p3, pos, dv);
    DeCasteljau(uv.y, t0, t1, t2, t3, du);

    nor = normalize(cross(du, dv));
}

void EvaluateGregory(float2 uv, float3 p[20], out float3 pos, out float3 nor)
{
    float3 q[16];

    float2 UV = 1 - uv;

    float d11 = (uv.x + uv.y) == 0 ? 1 : (uv.x + uv.y);
    float d12 = (UV.x + uv.y) == 0 ? 1 : (UV.x + uv.y);
    float d21 = (uv.x + UV.y) == 0 ? 1 : (uv.x + UV.y);
    float d22 = (UV.x + UV.y) == 0 ? 1 : (UV.x + UV.y);

    //  8     9     10     11         0     1     2     3
    // 12   0\1     2/3    13         4     5     6     7
    // 14   4/5     6\7    15         8     9     10    11
    // 16    17     18     19         12    13    14    15

    q[ 5] = (uv.x * p[1] + uv.y * p[0]) / d11;
    q[ 6] = (UV.x * p[2] + uv.y * p[3]) / d12;
    q[ 9] = (uv.x * p[5] + UV.y * p[4]) / d21;
    q[10] = (UV.x * p[6] + UV.y * p[7]) / d22;

    // Map gregory control points to bezier control points.
    q[ 0] = p[8];
    q[ 1] = p[9];
    q[ 2] = p[10];
    q[ 3] = p[11];
    q[ 4] = p[12];
    q[ 7] = p[13];
    q[ 8] = p[14];
    q[11] = p[15];
    q[12] = p[16];
    q[13] = p[17];
    q[14] = p[18];
    q[15] = p[19];
   
   EvaluateBezier(uv, q, pos, nor);

}

void EvaluatePmSector(float3 stw, float3 q[15], out float3 pos, out float3 nor)
{

    float3 p[10];
    uint k,j;    
    k=0;
    float s,t,w;
    s=stw.x; t=stw.y; w=stw.z;
    
    [unroll]
    for (j=0; j<4; j++) {
        p[k++]=s*q[j]+t*q[j+1]+w*q[j+5];
    }
    [unroll]
    for (j=5; j<8; j++) {
        p[k++]=s*q[j]+t*q[j+1]+w*q[j+4];
    }
    [unroll]		
    for (j=9; j<11; j++) {
        p[k++]=s*q[j]+t*q[j+1]+w*q[j+3];
    }	 
    p[9]=s*q[12]+t*q[13]+w*q[14]; 	
    
    k=0;	
    [unroll]	 
    for (j=0; j<3; j++) {
        q[k++]=s*p[j]+t*p[j+1]+w*p[j+4];
    } 
    [unroll]  
    for (j=4; j<6; j++) {
        q[k++]=s*p[j]+t*p[j+1]+w*p[j+3];
    } 	
    q[5]=s*p[7]+t*p[8]+w*p[9]; 
    [unroll]		  
    for (j=0; j<2; j++) {
        p[j]=s*q[j]+t*q[j+1]+w*q[j+3];
    }  
    p[2]=s*q[3]+t*q[4]+w*q[5]; 
    
    pos=s*p[0]+t*p[1]+w*p[2];
    nor=normalize(cross(p[0] - p[2], p[1] - p[0]));

}

float2 EvaluateSeamlessTexCoord(float2 uv, float2 tc[16])
{
    float2 L0 = (1 - uv);
    float2 L1 = (    uv);

    float2 t = (L0.x * tc[ 0] + L1.x * tc[4]) * L0.y + 
               (L0.x * tc[12] + L1.x * tc[8]) * L1.y;

    // Boundaries
    if (uv.y == 0) t = tc[ 0 + 1] * L0.x + tc[ 4 + 2] * L1.x;
    if (uv.y == 1) t = tc[12 + 2] * L0.x + tc[ 8 + 1] * L1.x;
    if (uv.x == 0) t = tc[ 0 + 2] * L0.y + tc[12 + 1] * L1.y;
    if (uv.x == 1) t = tc[ 4 + 1] * L0.y + tc[ 8 + 2] * L1.y;

    // Corners
    if (uv.x == 0 && uv.y == 0) t = tc[0 + 3];
    if (uv.x == 1 && uv.y == 0) t = tc[4 + 3];
    if (uv.x == 1 && uv.y == 1) t = tc[8 + 3];
    if (uv.x == 0 && uv.y == 1) t = tc[12 + 3];

    return t;
}

float2 EvaluateTexCoord(float2 uv, float2 tc[16])
{
    float2 L0 = (1 - uv);
    float2 L1 = (    uv);

	float2 t = (L0.x * tc[ 0] + L1.x * tc[4]) * L0.y + 
               (L0.x * tc[12] + L1.x * tc[8]) * L1.y;

    return t;
}

float2 EvaluateTexCoord_Tri(float2 uv, float2 tc[12])
{
    
    return (uv.x * tc[ 0] + uv.y * tc[4] + (1-uv.x-uv.y) * tc[8]);
}

// Optimized implementation.
float2 seamlessTriangleTexcoordLerp(float2 uv, float2 tc[12])
{
	// Barycentric coordinates
	float u = uv.x; float v = uv.y; float w = 1-u-v;

	// Texcoord indices
	int iu = 2 * (v == 0) + (w == 0);
	int iv = 2 * (w == 0) + (u == 0);
	int iw = 2 * (u == 0) + (v == 0);

	// Interpolate
	return u* tc[0 + iu] + v * tc[4 + iv] + w * tc[8 + iw];

}
void DeCasteljau(float u, float3 p0, float3 p1, float3 p2, out float3 p)
{
    float3 q0 = lerp(p0, p1, u);
    float3 q1 = lerp(p1, p2, u);
    
    p = lerp(q0, q1, u);
}
void EvalBezierPosDeC(float2 uv, float3 p[16], out float3 pos)
{
    float3 t0, t1, t2, t3;
    float3 p0, p1, p2, p3;


    DeCasteljau(uv.x, p[ 0], p[ 1], p[ 2], p[ 3], p0);
    DeCasteljau(uv.x, p[ 4], p[ 5], p[ 6], p[ 7], p1);
    DeCasteljau(uv.x, p[ 8], p[ 9], p[10], p[11], p2);
    DeCasteljau(uv.x, p[12], p[13], p[14], p[15], p3);

    DeCasteljau(uv.y, p0, p1, p2, p3, pos);
}
void EvalBezierDeC(float2 uv, float3 p[16], out float3 pos, out float3 nor)
{
    float3 t0, t1, t2, t3;
    float3 p0, p1, p2, p3;


    DeCasteljau(uv.x, p[ 0], p[ 1], p[ 2], p[ 3], p0, t0);
    DeCasteljau(uv.x, p[ 4], p[ 5], p[ 6], p[ 7], p1, t1);
    DeCasteljau(uv.x, p[ 8], p[ 9], p[10], p[11], p2, t2);
    DeCasteljau(uv.x, p[12], p[13], p[14], p[15], p3, t3);

    float3 du, dv;

    DeCasteljau(uv.y, p0, p1, p2, p3, pos, du);
    DeCasteljau(uv.y, t0, t1, t2, t3, dv);

    nor = normalize(cross(3 * dv, 3 * du));
}
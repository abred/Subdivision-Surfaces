//----------------------------------------------------------------------------------
// File:   InstancedTessellation.fx
// Email:  sdkfeedback@nvidia.com
// 
// Copyright (c) 2007 NVIDIA Corporation. All rights reserved.
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
#define BEZIER 0
#define GREGORY 1
#define PM 2
// Common parameters
cbuffer cbEveryFrame
{
    matrix  WorldView; 
    matrix  WorldViewProj; 
    float3 EyePos;   // object-space eye position
    uint renderingChoice;
};

#include "InstancedTessellation.fxh"

#define PI 3.141592653589793f

Buffer<float4> ControlPoints4; // @@ Use the same packing for all methods.
Buffer<float3> ControlPoints3;
Buffer<float4> TexCoords;
Buffer<float4> LoDs;

Texture2D OcclusionMap;
Texture2D SmoothOcclusionMap;
Texture2D NormalMap;
Texture2D DisplacementMap;

Texture2D ReferenceNormalMap;
Texture2D ReferencePositionMap;

// Instanced tessellation parameteres

float MaxLoD;
float LoDBias;
float DisplacementScale;
bool FlatShading = false;
float3 SeamColor = float3(1, 1, 1);

float ScreenX;
float ScreenY;
uint basePatchOffset;
uint errorMetric;


// Texture samplers

SamplerState DisplacementSampler
{
//    Filter = ANISOTROPIC;
    Filter = MIN_MAG_LINEAR_MIP_POINT;
//    Filter = MIN_MAG_MIP_POINT;
    AddressU = Clamp;
    AddressV = Clamp;
};

SamplerState TextureSampler
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};



// Shaders and structures for tessellation

struct AppVertexStatic
{
    float2 uv : POSITION;
    float4 stwn : TEXCOORD0;
    uint id : SV_InstanceID;
};
struct AppVertexDynamic
{
    float2 uv : POSITION;
    uint id : PatchID;
};


struct MeshVertex
{
    float4 ClipPos : SV_Position;
    float3 Pos : POSITION;
    float3 Normal : NORMAL;
    float2 TexCoord : TEXCOORD0;
    float3 Color : TEXCOORD1;
};
//////////////////////////////////////////////////////////////////////////////////////////
struct InputMeshVertex
{
    float4 pos                 : POSITION0;
};
struct InputMeshVertex_Out
{
    float4 pos                 : POSITION0;
    float4 posV                : POSITION1;
};
struct PS_INPUT_WIRE
{
    float4 Pos : SV_POSITION;
    float4 Col : TEXCOORD0;
    noperspective float3 Heights : TEXCOORD1;
};
//-----------------------------------------------------------------------------------------
float LineWidth = 4.0;
float4 FillColor = float4(0.1, 0.2, 0.4, 1);
float4 WireColor = float4(0.2, 0.3, 0.6, 1);
//--------------------------------------------------------------------------------------
///////////////////////////// states for rendering base mesh/////////////////////////////////////////////////////////
DepthStencilState DSSDepthLessEqual
{
    DepthEnable = true;
    DepthWriteMask = ZERO;
    DepthFunc = Less_Equal;
};
RasterizerState RSFill
{
    FillMode = SOLID;
    CullMode = None;
    DepthBias = false;
    MultisampleEnable = true;
};
BlendState BSBlending
{
    BlendEnable[0] = TRUE;
    SrcBlend = SRC_ALPHA;
    DestBlend = INV_SRC_ALPHA ;
    BlendOp = ADD;
    SrcBlendAlpha = SRC_ALPHA;
    DestBlendAlpha = DEST_ALPHA;
    BlendOpAlpha = ADD;
    RenderTargetWriteMask[0] = 0x0F;
};
DepthStencilState EnableDepth
{
    DepthEnable = TRUE;
    DepthWriteMask = ALL;
    DepthFunc = LESS_EQUAL;
};
///////////////////////////// functions for rendering base mesh/////////////////////////////////////////////////////////
float evalMinDistanceToEdges(in PS_INPUT_WIRE input, out uint edgeId )
{
    float dist;

    float3 ddxHeights = ddx( input.Heights );
    float3 ddyHeights = ddy( input.Heights );
    float3 ddHeights2 =  ddxHeights*ddxHeights + ddyHeights*ddyHeights;
    
    float3 pixHeights2 = input.Heights *  input.Heights / ddHeights2 ;
    
    // Find which edge is closer
    uint3 order = uint3(0, 1, 2);
    if (pixHeights2[1] < pixHeights2[0])
    {
        order.xy = order.yx;
    }
    if (pixHeights2[2] < pixHeights2[order.y])
    {
        order.yz = order.zy;
    }
    if (pixHeights2[2] < pixHeights2[order.x])
    {
        order.xy = order.yx;
    }
    edgeId = order.x;
    
    // When closest is edge #2, pick the one after
    if (edgeId == 2)
    {
        edgeId = order.y;
    }
    
    dist = sqrt( pixHeights2[edgeId] );
    
    return dist;
}
// Compute the triangle face normal from 3 points
float3 faceNormal(in float3 posA, in float3 posB, in float3 posC)
{
    return normalize( cross(normalize(posB - posA), normalize(posC - posA)) );
}
// Compute the final color of a face depending on its facing of the light
float4 shadeFace(in float4 verA, in float4 verB, in float4 verC)
{    
    return float4(FillColor.xyz, 1);
}
//////////////////////////////////////////////////////////////////////////////////////
void LoadRegularControlPoints(int idx, out float3 positionControlPoints[16])
{
    float3 q[16];
    [unroll]
    for (int i = 0; i < 4; i++)
    {
    
#ifdef NO_PACKING  // if the control points are stored in unpacked form
        q[4 * i + 0] = ControlPoints3.Load(idx * 16 + i * 4 + 0);
        q[4 * i + 1] = ControlPoints3.Load(idx * 16 + i * 4 + 1);
        q[4 * i + 2] = ControlPoints3.Load(idx * 16 + i * 4 + 2);
        q[4 * i + 3] = ControlPoints3.Load(idx * 16 + i * 4 + 3);
#else
        float4 tmp[3];

        tmp[0] = ControlPoints4.Load(idx * 12 + i * 3 + 0);
        tmp[1] = ControlPoints4.Load(idx * 12 + i * 3 + 1);
        tmp[2] = ControlPoints4.Load(idx * 12 + i * 3 + 2);
        
        q[4 * i + 0] = tmp[0].xyz;
        q[4 * i + 1] = float3( tmp[0].w, tmp[1].xy );
        q[4 * i + 2] = float3( tmp[1].zw, tmp[2].x );
        q[4 * i + 3] = tmp[2].yzw;
#endif
    }

    [unroll]
    for (int j = 0; j < 16; j++)
    {
        positionControlPoints[j]=q[j]; 
    }
}

void LoadBezierPositionControlPoints(int idx, out float3 positionControlPoints[16])
{
    float3 q[16];
     
    [unroll]
    for (int i = 0; i < 4; i++)
    {
#ifdef NO_PACKING // if the control points are stored in unpacked form
        q[4 * i + 0] = ControlPoints3.Load(idx * 32 + i * 4 + 0);
        q[4 * i + 1] = ControlPoints3.Load(idx * 32 + i * 4 + 1);
        q[4 * i + 2] = ControlPoints3.Load(idx * 32 + i * 4 + 2);
        q[4 * i + 3] = ControlPoints3.Load(idx * 32 + i * 4 + 3);
#else
        float4 tmp[3];

        tmp[0] = ControlPoints4.Load(idx * 24 + i * 3 + 0);
        tmp[1] = ControlPoints4.Load(idx * 24 + i * 3 + 1);
        tmp[2] = ControlPoints4.Load(idx * 24 + i * 3 + 2);
        q[4 * i + 0] = tmp[0].xyz;
        q[4 * i + 1] = float3( tmp[0].w, tmp[1].xy );
        q[4 * i + 2] = float3( tmp[1].zw, tmp[2].x );
        q[4 * i + 3] = tmp[2].yzw;
#endif
    }
    
    [unroll]
    for (int j = 0; j < 16; j++)
    {
        positionControlPoints[j]=q[j]; 
    }
}

void LoadBezierTangentControlPoints(int idx, out float3 tangentControlPoints[16])
{
    float3 q[16];
    [unroll]
    for (int i = 0; i < 4; i++)
    {
#ifdef NO_PACKING // if the control points are stored in unpacked form
        q[4 * i + 0] = ControlPoints3.Load(idx * 32 + i * 4 + 0 + 16);
        q[4 * i + 1] = ControlPoints3.Load(idx * 32 + i * 4 + 1 + 16);
        q[4 * i + 2] = ControlPoints3.Load(idx * 32 + i * 4 + 2 + 16);
        q[4 * i + 3] = ControlPoints3.Load(idx * 32 + i * 4 + 3 + 16);
#else
        float4 tmp[3];

        tmp[0] = ControlPoints4.Load(idx * 24 + i * 3 + 0 + 12);
        tmp[1] = ControlPoints4.Load(idx * 24 + i * 3 + 1 + 12);
        tmp[2] = ControlPoints4.Load(idx * 24 + i * 3 + 2 + 12);
        
        q[4 * i + 0] = tmp[0].xyz;
        q[4 * i + 1] = float3( tmp[0].w, tmp[1].xy );
        q[4 * i + 2] = float3( tmp[1].zw, tmp[2].x );
        q[4 * i + 3] = tmp[2].yzw;
#endif
    }
    [unroll]
    for (int j = 0; j < 16; j++)
    {
        tangentControlPoints[j]=q[j]; 
    }
    
}

void LoadGregoryPositionControlPoints(int idx, out float3 positionControlPoints[20])
{
    [unroll]
    for (int i = 0; i < 5; i++)
    {
#ifdef NO_PACKING // if the control points are stored in unpacked form
        positionControlPoints[4 * i + 0] = ControlPoints3.Load(idx * 20 + i * 4 + 0);
        positionControlPoints[4 * i + 1] = ControlPoints3.Load(idx * 20 + i * 4 + 1);
        positionControlPoints[4 * i + 2] = ControlPoints3.Load(idx * 20 + i * 4 + 2);
        positionControlPoints[4 * i + 3] = ControlPoints3.Load(idx * 20 + i * 4 + 3);
#else
        float4 tmp[3];

        tmp[0] = ControlPoints4.Load(idx * 15 + i * 3 + 0);
        tmp[1] = ControlPoints4.Load(idx * 15 + i * 3 + 1);
        tmp[2] = ControlPoints4.Load(idx * 15 + i * 3 + 2);
        
        positionControlPoints[4 * i + 0] = tmp[0].xyz;
        positionControlPoints[4 * i + 1] = float3( tmp[0].w, tmp[1].xy );
        positionControlPoints[4 * i + 2] = float3( tmp[1].zw, tmp[2].x );
        positionControlPoints[4 * i + 3] = tmp[2].yzw;
#endif
    }
}
void LoadPmControlPoints(float idx, out float3 positionControlPoints[24])
{
    float3 p[24];
    [unroll]
    for (int i = 0; i < 24; i++)
    {
        positionControlPoints[i] = ControlPoints3.Load(idx * 24 + i );
    }
}
void LoadTextureCoordinates(int idx, out float2 textureCoordinates[16])
{
    [unroll]
    for (int i = 0; i < 8; i++)
    {
        float4 tmp = TexCoords.Load(idx * 8 + i);
        textureCoordinates[2 * i + 0] = tmp.xy;
        textureCoordinates[2 * i + 1] = tmp.zw;
    }
}

void LoadTextureCoordinates_Tri(int idx, int method, out float2 textureCoordinates[12])
{
    uint i;
    float2 tc[12];
    [unroll]
    for (i = 0; i < 6; i++)
    {
        float4 tmp = TexCoords.Load(idx * 6 + i);
        textureCoordinates[2 * i + 0] = tmp.xy;
        textureCoordinates[2 * i + 1] = tmp.zw;
        tc[2 * i + 0] = tmp.xy;
        tc[2 * i + 1] = tmp.zw;
    }
    if (method==1)
    {
        textureCoordinates[0]=tc[0]; textureCoordinates[1]=tc[2]; textureCoordinates[2]=tc[1]; textureCoordinates[3]=tc[3];
        textureCoordinates[4]=tc[8]; textureCoordinates[5]=tc[10]; textureCoordinates[6]=tc[9]; textureCoordinates[7]=tc[11];
        textureCoordinates[8]=tc[4]; textureCoordinates[9]=tc[6]; textureCoordinates[10]=tc[5]; textureCoordinates[11]=tc[7];
    }
}


float2 projectToScreen(float3 p)
{
    float4 projected = mul( float4( p, 1.0f ), WorldViewProj );
    projected.xy *= 1.0f / abs( projected.w );
    
    return float2( (projected.x / 2.0f + 0.5f) * ScreenX, (projected.y / 2.0f + 0.5f) * ScreenY );
}

// Compute tessellation level based on screen-space length of hull boundary.
float evaluateEdgeLoD(float3 p0, float3 p1, float3 p2, float3 p3)
{
    float2 screenPoints[4];

    screenPoints[0] = projectToScreen(p0);
    screenPoints[1] = projectToScreen(p1);
    screenPoints[2] = projectToScreen(p2);
    screenPoints[3] = projectToScreen(p3);
    
    float l0 = length( screenPoints[0].xy - screenPoints[1].xy );
    float l1 = length( screenPoints[1].xy - screenPoints[2].xy );
    float l2 = length( screenPoints[2].xy - screenPoints[3].xy );

    float len = (l0 + l2) + l1;
    
    float lod = len / LoDBias;    // lodScale

    lod = clamp(lod , 1.0f, MaxLoD );

    len = (length(p1-p0) + length(p2-p3)); // + length(p2-p1);

    float3 dir = normalize(EyePos- float3(0,0,0)); //mul(WorldView, float3(0, 0, -1));

    float d0 = dot(p0, dir) - dot(EyePos, dir);
    float d1 = dot(p1, dir) - dot(EyePos, dir);
    float d2 = dot(p2, dir) - dot(EyePos, dir);
    float d3 = dot(p3, dir) - dot(EyePos, dir);

    float dist = min (d0, d1);
    dist = min (dist, d2);
    dist = min (dist, d3);

    float lod2 = 100 * len / LoDBias;
    lod2 = lerp(lod, lod2, 0.5);

    lod2 = clamp(lod2, 1.0f, MaxLoD );
    return exp2(round(log2(lod2)));        // round to nearest power of two.
}


// Tessellation Level evaluation

float4 PreprocessedLoDVS( uint id : SV_InstanceID, uniform int method) : LODS
{
    float4 tessLevel;
    if (method == 1)    //Gregory
    {
        float3 positionControlPoints[20];
        //  8     9     10     11
        // 12   0\1     2/3    13
        // 14   4/5     6\7    15
        // 16    17     18     19
        LoadGregoryPositionControlPoints(id, positionControlPoints);
        tessLevel.x = evaluateEdgeLoD(positionControlPoints[16], positionControlPoints[14], positionControlPoints[12], positionControlPoints[8]);
        tessLevel.y = evaluateEdgeLoD(positionControlPoints[19], positionControlPoints[15], positionControlPoints[13], positionControlPoints[11]);
        tessLevel.z = evaluateEdgeLoD(positionControlPoints[16], positionControlPoints[17], positionControlPoints[18], positionControlPoints[19]);
        tessLevel.w = evaluateEdgeLoD(positionControlPoints[8], positionControlPoints[9], positionControlPoints[10], positionControlPoints[11]);
    }
    else if (method == 0) {  //Regular
        float3 positionControlPoints[16];
        //  0     1     2     3
        //  4     5     6     7    
        //  8     9     10    11
        //  12    13    14    15
        LoadRegularControlPoints(id, positionControlPoints);
        tessLevel.x = evaluateEdgeLoD(positionControlPoints[ 0], positionControlPoints[ 4], positionControlPoints[ 8], positionControlPoints[12]);
        tessLevel.y = evaluateEdgeLoD(positionControlPoints[ 3], positionControlPoints[ 7], positionControlPoints[11], positionControlPoints[15]);
        tessLevel.w = evaluateEdgeLoD(positionControlPoints[ 0], positionControlPoints[ 1], positionControlPoints[ 2], positionControlPoints[ 3]);
        tessLevel.z = evaluateEdgeLoD(positionControlPoints[12], positionControlPoints[13], positionControlPoints[14], positionControlPoints[15]);
    }
    else if (method == 2) {  //Bezier
        float3 positionControlPoints[16];
        //  0     1     2     3
        //  4     5     6     7    
        //  8     9     10    11
        //  12    13    14    15
        LoadBezierPositionControlPoints(id, positionControlPoints);
        tessLevel.x = evaluateEdgeLoD(positionControlPoints[ 0], positionControlPoints[ 4], positionControlPoints[ 8], positionControlPoints[12]);
        tessLevel.y = evaluateEdgeLoD(positionControlPoints[ 3], positionControlPoints[ 7], positionControlPoints[11], positionControlPoints[15]);
        tessLevel.z = evaluateEdgeLoD(positionControlPoints[12], positionControlPoints[13], positionControlPoints[14], positionControlPoints[15]);
        tessLevel.w = evaluateEdgeLoD(positionControlPoints[ 0], positionControlPoints[ 1], positionControlPoints[ 2], positionControlPoints[ 3]);
    }
    else if (method == 3) {  //Pm
        //          18  14  13   12                             
        //          19           8         
        //          20           7              
        //          0   1   2    6                 
        float3 positionControlPoints[24];
        LoadPmControlPoints(id, positionControlPoints);
        tessLevel.x = evaluateEdgeLoD(positionControlPoints[ 0], positionControlPoints[20], positionControlPoints[19], positionControlPoints[18]);
        tessLevel.y = evaluateEdgeLoD(positionControlPoints[ 6], positionControlPoints[ 7], positionControlPoints[ 8], positionControlPoints[12]);
        tessLevel.z = evaluateEdgeLoD(positionControlPoints[18], positionControlPoints[14], positionControlPoints[13], positionControlPoints[12]);
        tessLevel.w = evaluateEdgeLoD(positionControlPoints[ 0], positionControlPoints[ 1], positionControlPoints[ 2], positionControlPoints[ 6]);
    }
    else {
        tessLevel=float4(2,2,2,2);
    }
    return tessLevel;
}

void EvaluateGregorySurface(float idx, float2 uv, out float3 pos, out float3 nor)
{
    float3 gregoryControlPoints[20];
    LoadGregoryPositionControlPoints(idx, gregoryControlPoints);

    EvaluateGregory(uv, gregoryControlPoints, /*out*/pos, /*out*/nor);

}
void EvaluateGregoryTriangleSurface(float idx, float2 uv, out float3 pos, out float3 nor)
{
    //Load Gregory Position ControlPoints
    float3 p[15];
    uint beginIndex=15*idx;    
    [unroll]
    for (uint i=0; i<15; i++) {
        p[i] = ControlPoints3.Load(beginIndex+i);
    }
    //Evaluate position and normal
    //                                                           0
    //                     6                                  1    5
    //               14   0|1     7           ===>          2    6    9
    //            13  5/4    3\2    8                     3    7    10   12
    //         12      11     10      9                 4    8    11   13   14

    //        11      10              
    //       13/14    12             
    // 2     4/3     9\8     6              
    // 0      1      7       5               
    float3 C0, C1, C2;    
    float u,v,w;
    u=uv.x; v=uv.y; w=1-u-v;

    float  d0 = ( v + u )==0 ? 1:(v+u); 
    float  d1 = ( w + v )==0 ? 1:(w+v); 
    float  d2 = ( u + w )==0 ? 1:(u+w); 

    C0 = (v*p[1] +u*p[0])/d0;
    C1 = (w*p[5] +v*p[4])/d1;
    C2 = (u*p[3] +w*p[2])/d2;

    float3 q[15]; 
    q[0]=p[6]; 
    q[1]=(p[6]+3*p[14])/4;
    q[2]=(p[14]+p[13])/2;
    q[3]=(3*p[13]+p[12])/4;
    q[4]=p[12];
    q[5]=(3*p[7]+p[6])/4;
    q[6]=C0;
    q[7]=C1;
    q[8]=(p[12]+3*p[11])/4;
    q[9]=(p[7]+p[8])/2;
    q[10]=C2;
    q[11]=(p[11]+p[10])/2;
    q[12]=(p[9]+3*p[8])/4;
    q[13]=(p[9]+3*p[10])/4;
    q[14]=p[9];
    uint j, k=0;
    float s=u; float t= v; 
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
    nor=normalize(cross(p[2] - p[0], p[1] - p[0])); 
}

void EvaluateBezierSurface(float idx, float2 uv, out float3 pos, out float3 nor)
{
    float3 p[16]; // geometry control points
    
    LoadBezierPositionControlPoints(idx, p);
    EvalBezierPosDeC(uv, p, pos);

    float3 t[16];  //adjusted tangent vectors
    LoadBezierTangentControlPoints(idx, t);

    float3 u[12], v[12];
    // interior u vectors 
    u[1]=3*(p[2]-p[1]); u[4]=3*(p[6]-p[5]); u[7]=3*(p[10]-p[9]); u[10]=3*(p[14]-p[13]);
    // corner u vectors
    u[0]=t[0];  u[2]=t[4]; u[9]=t[3]; u[11]=t[7];
    // edge u vectors
    u[3]=t[1]; u[5]=t[5]; u[6]=t[2]; u[8]=t[6];
    
    // interior v vectors 
    v[4]=3*(p[8]-p[4]); v[5]=3*(p[9]-p[5]); v[6]=3*(p[10]-p[6]); v[7]=3*(p[11]-p[7]);
    // corner v vectors
    v[0]=t[8]; v[3]=t[11]; v[8]=t[12]; v[11]=t[15];
    // edge v vectors
    v[1]=t[9]; v[2]=t[10]; v[9]=t[13]; v[10]=t[14];
    float3 s0, s1, s2, s3, du, dv;
    DeCasteljau(uv.x, u[0], u[1], u[2], s0);
    DeCasteljau(uv.x, u[3], u[4], u[5], s1);
    DeCasteljau(uv.x, u[6], u[7], u[8], s2);
    DeCasteljau(uv.x, u[9], u[10], u[11], s3);
    
    DeCasteljau(uv.y, s0, s1, s2, s3, du);
    
    DeCasteljau(uv.x, v[0], v[1], v[2], v[3], s0);
    DeCasteljau(uv.x, v[4], v[5], v[6], v[7], s1);
    DeCasteljau(uv.x, v[8], v[9], v[10], v[11], s2);
    
    DeCasteljau(uv.y, s0, s1, s2, dv);
    
    nor = normalize(cross(du, dv));

}
void  EvaluatePmSurface(float idx, float4 stwn, out float3 pos, out float3 nor)
{
    
    // gather 15 control points of a quartic triangular patch
    //                                                      14
    //                                                   12    13
    //                   5            ===>             9    10    11
    //                3    4                        5    6     7    8
    //          0   1    2                       0    1     2    3    4
   
    uint pnum=(uint)stwn.w;
    float3 q[15];
    float s,t,w;
    s=stwn.x; t=stwn.y; w=stwn.z;

    uint beginIndex=24*idx;    
    uint start= beginIndex + 6*pnum;
    uint startp=beginIndex + 6*((pnum+1)%4);
    uint startm=beginIndex + 6*((pnum+3)%4);
    q[0] = ControlPoints3.Load(start);
    q[1] = 0.25*ControlPoints3.Load(start) + 0.75*ControlPoints3.Load(start+1);
    q[2] = 0.5*(ControlPoints3.Load(start+1) + ControlPoints3.Load(start+2));
    q[3] = 0.25*ControlPoints3.Load(startp)+ 0.75*ControlPoints3.Load(start+2);
    q[4] = ControlPoints3.Load(startp);
    q[6]= ControlPoints3.Load(start+3);
    q[7]= ControlPoints3.Load(start+4);
    q[10]=ControlPoints3.Load(start+5);                                                          
    q[5]=0.5*q[1]+0.125*q[0]+0.375*(ControlPoints3.Load(startm+2));
    q[8]=0.5*q[3]+0.125*q[4]+0.375*(ControlPoints3.Load(startp+1));
    q[9]=0.5*(q[6]+ControlPoints3.Load(startm+4));
    q[11]=0.5*(q[7]+ControlPoints3.Load(startp+3));
    q[12]=0.5*(q[10]+ControlPoints3.Load(startm+5));
    q[13]=0.5*(q[10]+ControlPoints3.Load(startp+5));
    q[14]=0.5*q[13]+0.25*(ControlPoints3.Load(startm+5)+ControlPoints3.Load(beginIndex + 6*((pnum+2)%4)+5));

    float3 p[10]; uint j, k=0;
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
void  EvaluatePmSurfaceFromUV(float idx, float2 uv, out float3 pos, out float3 nor)
{
    float s,t,w,pid,u,v;
    u=uv.x; v=uv.y;
    if (v<=u && u+v<=1) { //T1
        s=1-u-v; t=u-v; w=2*v; pid=0.0;
    }
    else if (v<=u && u+v>1) { //T2
        s=u-v; t=u+v-1; w=2-2*u; pid=1.0;
    }
    else if (v>u && u+v<=1) { //T4
        s=v-u; t=1-v-u; w=2*u; pid=3.0;
    }
    else { //T3
        s=u+v-1; t=v-u; w=2-2*v; pid=2.0;
    }
    float4 stwn=float4(s,t,w,pid);
    EvaluatePmSurface(idx, stwn, pos, nor);
}   
void EvaluatePmTriangleSurface(float idx, float4 stwn, out float3 pos, out float3 nor)
{
    
    // gather 15 control points of a quartic triangular patch
    //                                                      14
    //                                                  12    13
    //                   5           ===>             9    10    11
    //                3    4                        5    6     7    8
    //          0   1    2                       0    1     2    3    4
   
    uint pnum=(uint)stwn.w;
    float3 q[15];
    float s,t,w, k1, k2; 
    s=stwn.x; t=stwn.y; w=stwn.z;

    k2=1/(2*(1-cos(2*PI/3)));
    k1=1-2*k2;
    uint beginIndex=19*idx;    
    uint start= beginIndex + 6*pnum;
    uint startp=beginIndex + 6*((pnum+1)%3);
    uint startm=beginIndex + 6*((pnum+2)%3);
    q[0] = ControlPoints3.Load(start);
    q[1] = 0.25*ControlPoints3.Load(start) + 0.75*ControlPoints3.Load(start+1);
    q[2] = 0.5*(ControlPoints3.Load(start+1) + ControlPoints3.Load(start+2));
    q[3] = 0.25*ControlPoints3.Load(startp)+ 0.75*ControlPoints3.Load(start+2);
    q[4] = ControlPoints3.Load(startp);
    q[6]= ControlPoints3.Load(start+3);
    q[7]= ControlPoints3.Load(start+4);
    q[14]=ControlPoints3.Load(beginIndex + 18);
    q[10]=ControlPoints3.Load(start+5);
    q[5]=k1*q[0]+k2*(q[1]+0.25*q[0]+0.75*(ControlPoints3.Load(startm+2)));
    q[8]=k1*q[4]+k2*(q[3]+0.25*q[4]+0.75*(ControlPoints3.Load(startp+1)));
    q[9]=k1*q[5]+k2*(q[6]+ControlPoints3.Load(startm+4));
    q[11]=k1*q[8]+k2*(q[7]+ControlPoints3.Load(startp+3));
    q[12]=k1*q[9]+k2*(q[10]+ControlPoints3.Load(startm+5));
    q[13]=k1*q[11]+k2*(q[10]+ControlPoints3.Load(startp+5));
    
    float3 p[10]; uint j, k=0;
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
void EvaluatePmTriangleSurfaceFromUV(float idx, float2 uv, out float3 pos, out float3 nor)
{ 
    float u=uv.x; float v=uv.y;
    float x=1-u-v;
    float s,t,w,pid;
    if ( (v>=x && u>=x ) || u==1.0 || v==1.0 )
    { // in T1, also including the centeroid (1/3, 1/3, 1/3)
        s=u-x;
        t=v-x;
        w=3*x;
        pid=0.0f;
    }
    else if ((x>u && v>=u) || x==1.0 )
    { // in T2
        s=v-u;
        t=x-u;
        w=3*u;
        pid=1.0f;
    }
    else  
    { // in T3
        s=x-v;
        t=u-v;
        w=3*v;
        pid=2.0f;
    }
    
    EvaluatePmTriangleSurface(idx, float4(s,t,w,pid), pos, nor);
}
void EvaluateRegularSurface(float idx, float2 uv, out float3 pos, out float3 nor)
{
    float3 positionControlPoints[16];
    LoadRegularControlPoints(idx, positionControlPoints);

    EvaluateBezier(uv, positionControlPoints, /*out*/pos, /*out*/nor);
}

// Vertex Shader for tessellation
MeshVertex TessellationVS( AppVertexStatic input, uniform int method, uniform int type )
{
    float2 uv = input.uv;
    float4 stwn = input.stwn;
    
    float3 pos, nor;
    if (type == 0) EvaluateRegularSurface(input.id, uv, pos, nor);
    else if (type == 1) {
        if (method == 0) EvaluateBezierSurface(input.id, uv, pos, nor);
        else if (method == 1) EvaluateGregorySurface(input.id, uv, pos, nor);
        else if (method == 2) EvaluatePmSurface(input.id, stwn, pos, nor);
    }
    else if (type == 2) {
        if (method == 1) EvaluateGregoryTriangleSurface(input.id, uv, pos, nor);
        else EvaluatePmTriangleSurface(input.id, stwn, pos, nor);
    }


    float2 texCoord, seamlessTexCoord;
    if (type == 2) { //triangle
        // @@ Add EvaluateTriTexCoords(input.id, uv, texCoord, seamlessTexCoord);
        float2 textureCoordinates[12];
        LoadTextureCoordinates_Tri(input.id, method, textureCoordinates);
        texCoord = EvaluateTexCoord_Tri(uv, textureCoordinates);
        seamlessTexCoord = seamlessTriangleTexcoordLerp(uv, textureCoordinates);
    }
    else if (type == 1) { //quad 
        // @@ Add this method:
        // EvaluateQuadTexCoords(input.id, uv, texCoord, seamlessTexCoord);
        float2 textureCoordinates[16];
        LoadTextureCoordinates(input.id, textureCoordinates);
        
        texCoord = EvaluateTexCoord( uv, textureCoordinates);
        seamlessTexCoord = EvaluateSeamlessTexCoord(uv, textureCoordinates);
    }
    else {//regular
        float2 textureCoordinates[16];
        LoadTextureCoordinates(input.id, textureCoordinates);

        texCoord = EvaluateTexCoord(uv, textureCoordinates);
        seamlessTexCoord = EvaluateSeamlessTexCoord(uv, textureCoordinates);   
    }

    // Only apply displacement when not showing error:
    if (errorMetric == 0)
    {
        //pos += nor *DisplacementScale * (DisplacementMap.SampleLevel(DisplacementSampler, seamlessTexCoord + 0.5/1024, 0).r );
          pos += DisplacementScale * DisplacementMap.SampleLevel(TextureSampler, seamlessTexCoord + 0.5/1024 , 0).rgb;
       // pos = DisplacementMap.SampleLevel(TextureSampler, seamlessTexCoord + 0.5/1024 , 0).rgb;
    }

    MeshVertex output;
    output.ClipPos = mul(float4(pos, 1.0f ), WorldViewProj);
    output.Pos = pos;
    output.Normal = nor;
    output.TexCoord = texCoord;
    
    float3 color3 = float3(0.5f, 0.35f, 0.3f);

    if (renderingChoice && type == 1)
        color3 = float3(0.71f, 0.53f, 0.98f);
    else if (renderingChoice && type == 2)
        color3 = float3(0.3f, 0.8f, 0.4f);
    
    output.Color = color3;
        
    if ((seamlessTexCoord.x != texCoord.x || seamlessTexCoord.y != texCoord.y) 
         && SeamColor.x==1.0f && SeamColor.y==0.0f&& SeamColor.z==0.0f) 
        output.Color = SeamColor;

    // Display position or normal error.
    if (errorMetric == 2)
    {
        float3 refNormal = 2 * ReferenceNormalMap.SampleLevel(TextureSampler, seamlessTexCoord, 0).xyz - 1;

        float error = dot(normalize(refNormal), normalize(nor));
        error = saturate(256 * error * error - 255);

        if (error < 0.5) output.Color = lerp(float3(1,0,0), float3(0,1,0), 2 * error);
        else output.Color = lerp(float3(0,1,0), float3(0,0,1), 2 * error - 1);
    }
    else if (errorMetric == 1)
    {
        float3 refPosition = ReferencePositionMap.SampleLevel(TextureSampler, seamlessTexCoord + 0.5/1024, 0).rgb;
        float3 v = pos - refPosition;

        // This approximates the position error without taking into account the parametric distortion.
        float3 refNormal = 2 * ReferenceNormalMap.SampleLevel(TextureSampler, seamlessTexCoord + 0.5/1024, 0).rgb - 1;
        float error = dot(normalize(refNormal), v);
        error = 1 - saturate(2 * 1024 * error);

        if (error < 0.5) output.Color = lerp(float3(1,0,0), float3(0,1,0), 2 * error);
        else output.Color = lerp(float3(0,1,0), float3(0,0,1), 2 * error - 1);
    }

    return output;
}


// Vertex Shader for tessellation with dynamic LoD and CPU-processed patches

MeshVertex TessellationPreprocessedLoDVS( AppVertexDynamic input, uniform int method, uniform int type )
{
    float2 uv = input.uv;
    float4 edgeLod = LoDs.Load( input.id );
    MeshVertex output = (MeshVertex) 0;

    // This tessellation pattern approximates the DX11 hardware more closely, but it's more expensive.
    float2 lod;
    lod.x = max(edgeLod.x, edgeLod.y);
    lod.y = max(edgeLod.z, edgeLod.w);

    if (uv.y == 0.0f) lod.y = edgeLod.w;
    else if (uv.y == 1.0f) lod.y = edgeLod.z;

    if (uv.x == 0.0f) lod.x = edgeLod.x;
    else if (uv.x == 1.0f) lod.x = edgeLod.y;
    if (lod.x < lod.y)
    {
        uv.y = floor(uv.y * lod.x) / lod.x;
        uv.x = floor(uv.x * lod.y) / lod.y;
    }
    else
    {
        uv.x = floor(uv.x * lod.y) / lod.y;
        uv.y = floor(uv.y * lod.x) / lod.x;
    }

    float3 pos, nor;
    
    if (type == 0) EvaluateRegularSurface(input.id, uv, pos, nor);
    else if (type == 1) {
        if (method == 0) EvaluateBezierSurface(input.id, uv, pos, nor);
        else if (method == 1) EvaluateGregorySurface(input.id, uv, pos, nor);
        else EvaluatePmSurfaceFromUV(input.id, uv, pos, nor);
    }
    else if (type == 2) {
        if (method == 1) EvaluateGregoryTriangleSurface(input.id, uv, pos, nor);
        else EvaluatePmTriangleSurfaceFromUV(input.id, uv, pos, nor);
    }

    float2 texCoord, seamlessTexCoord;
    if (type != 2) {
        // @@ Add this method:
        // EvaluateQuadTexCoords(input.id, uv, texCoord, seamlessTexCoord);

        float2 textureCoordinates[16];
        LoadTextureCoordinates(input.id, textureCoordinates);

        texCoord = EvaluateTexCoord(uv, textureCoordinates);
        seamlessTexCoord = EvaluateSeamlessTexCoord(uv, textureCoordinates);
    }
    else {
        // @@ Evaluate triangle coordinates.
        float2 textureCoordinates[12];
        LoadTextureCoordinates_Tri(input.id, method, textureCoordinates);
        texCoord = EvaluateTexCoord_Tri(uv, textureCoordinates);
        seamlessTexCoord = seamlessTriangleTexcoordLerp(uv, textureCoordinates);
    }
    
    //pos += nor * DisplacementScale * (DisplacementMap.SampleLevel(DisplacementSampler, seamlessTexCoord + 0.5/1024, 0).r - 0.5f);
    pos += DisplacementScale * DisplacementMap.SampleLevel(DisplacementSampler, seamlessTexCoord + 0.5/1024, 0).rgb;
    
    
    float3 color3 = float3(0.5f, 0.35f, 0.3f);

    if (renderingChoice && type == 1)
        color3 = float3(0.71f, 0.53f, 0.98f);
    else if (renderingChoice && type == 2)
        color3 = float3(0.3f, 0.8f, 0.4f);
    
    output.Color = color3;
        
    if ((seamlessTexCoord.x != texCoord.x || seamlessTexCoord.y != texCoord.y) 
         && SeamColor.x==1.0f && SeamColor.y==0.0f&& SeamColor.z==0.0f) 
        output.Color = SeamColor;
    
    //MeshVertex output;
    output.ClipPos = mul(float4(pos, 1.0f), WorldViewProj);
    output.Pos = pos;
    output.Normal = nor;
    output.TexCoord = texCoord;

    return output;
}

// Geometry Shader for wireframe output

[maxvertexcount(4)]
void TessellationWireframeGS( triangle MeshVertex input[3], inout LineStream<MeshVertex> lineStream )
{
    lineStream.Append (input[0]);
    lineStream.Append (input[1]);
    lineStream.Append (input[2]);
    lineStream.Append (input[0]);
    lineStream.RestartStrip ();
}

// Pixel Shaders

float4 TessellationFullShadingPS( MeshVertex input, uniform int type) : SV_Target
{   
    // the shading computation is done in object space (usually in world space), since only one object in the scene 
    float3 normal = 2 * NormalMap.Sample(TextureSampler, input.TexCoord + 0.5f/2048).xyz - 1;
    normal = lerp(input.Normal, normal, DisplacementScale);

    float occlusion = OcclusionMap.Sample(TextureSampler, input.TexCoord).r;
    float smoothOcclusion = SmoothOcclusionMap.Sample(TextureSampler, input.TexCoord).r;
    occlusion = lerp(smoothOcclusion, occlusion, DisplacementScale);
    
    if (FlatShading)
    {
        float3 dx = ddx( input.Pos );
        float3 dy = ddy( input.Pos );
        normal = normalize( cross( dx, dy ) );
        occlusion = 1.0f;
    }

    float3 lightVec = mul((float3x3)WorldView, normalize(float3(.2, .5, -1)));
    float3 eyeVec = normalize(EyePos - input.Pos);

    float3 reflectedVec = normalize( normal * 2.0f * dot( eyeVec, normal ) - eyeVec );
        
    if (errorMetric > 0)
    {
        float3 diffuse = input.Color * saturate(0.5f * dot(input.Normal, lightVec) + 0.5f);
        return float4(diffuse, 1.0f);
    }
    else
    {

        float3 ambient = input.Color * 0.1f;
        float3 diffuse = input.Color * saturate(dot(normal, lightVec));
        float3 specular = 0.3f * saturate(pow(dot(reflectedVec, lightVec), 5.0f));
        return float4(ambient + occlusion * (diffuse + specular), 1.0f);
    }
}

float4 TessellationWireframePS( MeshVertex input ) : SV_Target
{
    return float4( 0.9f, 0.9f, 0.9f, 0.9f );
}


// Miscellaneous states

BlendState EnableColorWrites
{
    RenderTargetWriteMask[0] = 0xf;
};

DepthStencilState EnableDepthWrites
{
    DepthEnable = true;
    DepthFunc = Less_Equal;
    DepthWriteMask = ALL;
};

DepthStencilState DisableDepthWrites
{
    DepthEnable = false;
    DepthWriteMask = ZERO;
    DepthFunc = Less_Equal;

    StencilEnable = false;
    StencilReadMask = 0xFF;
    StencilWriteMask = 0x00;
};

RasterizerState Multisampling
{
    MultisampleEnable = true;
    FillMode = SOLID;
};
RasterizerState MultisamplingDepthBias
{
    MultisampleEnable = true;
    DepthBias = 1;
    SlopeScaledDepthBias = 1;
    FillMode = SOLID;
};
RasterizerState MultisamplingWireframe
{
    MultisampleEnable = true;
    FillMode = WIREFRAME;
};
////////////////////////////////// Shaders //////////////////////////////////////////////////////////
InputMeshVertex_Out BaseMeshVS( InputMeshVertex input)
{
    InputMeshVertex_Out output;
    
    output.pos = mul(float4(input.pos.xyz,1), WorldViewProj);
    output.posV = mul(float4(input.pos.xyz,1), WorldView);
         
    return output;
}    
[maxvertexcount(3)]
void BaseMeshGS( triangle InputMeshVertex_Out input[3], inout TriangleStream<PS_INPUT_WIRE> outStream )
{
    PS_INPUT_WIRE output;

    // Shade and colour face.
    output.Col = shadeFace(input[0].posV, input[1].posV, input[2].posV);

    // Emit the 3 vertices
    // The Height attribute is based on the constant
    output.Pos = input[0].pos;
    output.Heights = float3( 1, 0, 0 );
    outStream.Append( output );

    output.Pos = input[1].pos;
    output.Heights = float3( 0, 1, 0 );
    outStream.Append( output );

    output.Pos = input[2].pos;
    output.Heights = float3( 0, 0, 1 );
    outStream.Append( output );

    outStream.RestartStrip();
}
float4 BaseMeshPS( PS_INPUT_WIRE input) : SV_Target
{
    // Compute the shortest distance between the fragment and the edges.
    uint edgeId = 0;
    float dist = evalMinDistanceToEdges(input, edgeId);

    // Cull fragments too far from the edge.
    if (dist > 0.5*LineWidth+1) discard;

    // Map the computed distance to the [0,2] range on the border of the line.
    dist = clamp((dist - (0.5*LineWidth - 1)), 0, 2);

    // Alpha is computed from the function exp2(-2(x)^2).
    dist *= dist;
    float alpha = exp2(-2*dist);

    
    // Standard wire color
    float4 color = float4( WireColor.xyz, alpha );
    //color.x=input.Diagonal;
        
    return color;
}
float4 zOnlyPS( ) : SV_Target
{
    return float4(0, 0, 0, 0);
}
/////////////////////////////// Techniques //////////////////////////////////////////////////////////////
// Techniques to compute LoDs
technique10 LoDGregoryTechnique
{
    pass P0
    {
        SetDepthStencilState( DisableDepthWrites, 0 );
        
        SetVertexShader( CompileShader( vs_4_0, PreprocessedLoDVS(1) ) );
        SetGeometryShader( ConstructGSWithSO( CompileShader( vs_4_0, PreprocessedLoDVS(1) ), "LODS.xyzw" ) );
        SetPixelShader( NULL );
    }
}
technique10 LoDBezierTechnique
{
    pass P0
    {
        SetDepthStencilState( DisableDepthWrites, 0 );
        
        SetVertexShader( CompileShader( vs_4_0, PreprocessedLoDVS(2) ) );
        SetGeometryShader( ConstructGSWithSO( CompileShader( vs_4_0, PreprocessedLoDVS(2) ), "LODS.xyzw" ) );
        SetPixelShader( NULL );
    }
}
technique10 LoDPmTechnique
{
    pass P0
    {
        SetDepthStencilState( DisableDepthWrites, 0 );
        
        SetVertexShader( CompileShader( vs_4_0, PreprocessedLoDVS(3) ) );
        SetGeometryShader( ConstructGSWithSO( CompileShader( vs_4_0, PreprocessedLoDVS(3) ), "LODS.xyzw" ) );
        SetPixelShader( NULL );
    }
}
technique10 LoDGregoryTriangleTechnique
{
    pass P0
    {
        SetDepthStencilState( DisableDepthWrites, 0 );
        
        SetVertexShader( CompileShader( vs_4_0, PreprocessedLoDVS(4) ) );
        SetGeometryShader( ConstructGSWithSO( CompileShader( vs_4_0, PreprocessedLoDVS(4) ), "LODS.xyzw" ) );
        SetPixelShader( NULL );
    }
}
technique10 LoDPmTriangleTechnique
{
    pass P0
    {
        SetDepthStencilState( DisableDepthWrites, 0 );
        
        SetVertexShader( CompileShader( vs_4_0, PreprocessedLoDVS(5) ) );
        SetGeometryShader( ConstructGSWithSO( CompileShader( vs_4_0, PreprocessedLoDVS(5) ), "LODS.xyzw" ) );
        SetPixelShader( NULL );
    }
}
technique10 LoDRegularTechnique
{
    pass P0
    {
        SetDepthStencilState( DisableDepthWrites, 0 );
        
        SetVertexShader( CompileShader( vs_4_0, PreprocessedLoDVS(0) ) );
        SetGeometryShader( ConstructGSWithSO( CompileShader( vs_4_0, PreprocessedLoDVS(0) ), "LODS.xyzw" ) );
        SetPixelShader( NULL );
    }
}

// Techniques to render with static LoD
technique10 StaticLoDRegularSurfaceEvaluationTechnique
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( Multisampling );

        SetVertexShader( CompileShader( vs_4_0, TessellationVS(0, 0) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(0) ) );
    }
}
technique10 StaticLoDBezierSurfaceEvaluationTechnique
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( Multisampling );

        SetVertexShader( CompileShader( vs_4_0, TessellationVS(0, 1) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(1) ) );
    }
}
technique10 StaticLoDGregorySurfaceEvaluationTechnique
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( Multisampling );

        SetVertexShader( CompileShader( vs_4_0, TessellationVS(1, 1) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(1) ) );
    }
}
technique10 StaticLoDPmSurfaceEvaluationTechnique
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( Multisampling );

        SetVertexShader( CompileShader( vs_4_0, TessellationVS(2, 1) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(1) ) );
    }
}
technique10 StaticLoDPmTriangleSurfaceEvaluationTechnique
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( Multisampling );

        SetVertexShader( CompileShader( vs_4_0, TessellationVS(2, 2) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(2) ) );
    }
}
technique10 StaticLoDGregoryTriangleSurfaceEvaluationTechnique
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( Multisampling );

        SetVertexShader( CompileShader( vs_4_0, TessellationVS(1, 2) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(2) ) );
    }
}
technique10 StaticLoDRegularSurfaceEvaluationTechnique_Wireframe
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingDepthBias );

        SetVertexShader( CompileShader( vs_4_0, TessellationVS(0, 0) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(0) ) );
    }
    pass P1
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingWireframe );

        SetVertexShader( CompileShader( vs_4_0, TessellationVS(0, 0) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationWireframePS() ) );
    }
}
technique10 StaticLoDBezierSurfaceEvaluationTechnique_Wireframe
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingDepthBias );

        SetVertexShader( CompileShader( vs_4_0, TessellationVS(0, 1) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(1) ) );
    }
    pass P1
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingWireframe );

        SetVertexShader( CompileShader( vs_4_0, TessellationVS(0, 1) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationWireframePS() ) );
    }
}
technique10 StaticLoDGregorySurfaceEvaluationTechnique_Wireframe
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingDepthBias );

        SetVertexShader( CompileShader( vs_4_0, TessellationVS(1, 1) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(1) ) );
    }
    pass P1
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingWireframe );

        SetVertexShader( CompileShader( vs_4_0, TessellationVS(1, 1) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationWireframePS() ) );
    }
}
technique10 StaticLoDPmSurfaceEvaluationTechnique_Wireframe
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingDepthBias );

        SetVertexShader( CompileShader( vs_4_0, TessellationVS(2, 1) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(1) ) );
    }
    pass P1
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingWireframe );

        SetVertexShader( CompileShader( vs_4_0, TessellationVS(2, 1) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationWireframePS() ) );
    }
}

technique10 StaticLoDPmTriangleSurfaceEvaluationTechnique_Wireframe
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingDepthBias );

        SetVertexShader( CompileShader( vs_4_0, TessellationVS(2, 2) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(2) ) );
    }
    pass P1
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingWireframe );

        SetVertexShader( CompileShader( vs_4_0, TessellationVS(2, 2) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationWireframePS() ) );
    }
}
technique10 StaticLoDGregoryTriangleSurfaceEvaluationTechnique_Wireframe
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingDepthBias );

        SetVertexShader( CompileShader( vs_4_0, TessellationVS(1, 2) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(2) ) );
    }
    pass P1
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingWireframe );

        SetVertexShader( CompileShader( vs_4_0, TessellationVS(1, 2) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationWireframePS() ) );
    }
}
// Techniques to render with dynamic LoD per patch
technique10 DynamicLoDRegularEvaluationTechnique
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( Multisampling );

        SetVertexShader( CompileShader( vs_4_0, TessellationPreprocessedLoDVS(0, 0) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(0) ) );
    }
}
technique10 DynamicLoDRegularEvaluationTechnique_Wireframe
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingDepthBias );

        SetVertexShader( CompileShader( vs_4_0, TessellationPreprocessedLoDVS(0, 0) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(0) ) );
    }
    pass P1
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingWireframe );

        SetVertexShader( CompileShader( vs_4_0, TessellationPreprocessedLoDVS(0, 0) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationWireframePS() ) );
    }
}
technique10 DynamicLoDGregoryEvaluationTechnique
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( Multisampling );

        SetVertexShader( CompileShader( vs_4_0, TessellationPreprocessedLoDVS(GREGORY, 1) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(1) ) );
    }
}
technique10 DynamicLoDGregoryEvaluationTechnique_Wireframe
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingDepthBias );

        SetVertexShader( CompileShader( vs_4_0, TessellationPreprocessedLoDVS(GREGORY, 1) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(1) ) );
    }
    pass P1
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingWireframe );

        SetVertexShader( CompileShader( vs_4_0, TessellationPreprocessedLoDVS(GREGORY, 1) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationWireframePS() ) );
    }
}
technique10 DynamicLoDGregoryTriangleEvaluationTechnique
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( Multisampling );

        SetVertexShader( CompileShader( vs_4_0, TessellationPreprocessedLoDVS(GREGORY, 2) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(2) ) );
    }
}
technique10 DynamicLoDGregoryTriangleEvaluationTechnique_Wireframe
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingDepthBias );

        SetVertexShader( CompileShader( vs_4_0, TessellationPreprocessedLoDVS(GREGORY, 2) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(2) ) );
    }
    pass P1
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingWireframe );

        SetVertexShader( CompileShader( vs_4_0, TessellationPreprocessedLoDVS(GREGORY, 2) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationWireframePS() ) );
    }
}
technique10 DynamicLoDBezierEvaluationTechnique
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( Multisampling );

        SetVertexShader( CompileShader( vs_4_0, TessellationPreprocessedLoDVS(BEZIER, 1) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(1) ) );
    }
}
technique10 DynamicLoDBezierEvaluationTechnique_Wireframe
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingDepthBias );

        SetVertexShader( CompileShader( vs_4_0, TessellationPreprocessedLoDVS(BEZIER, 1) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(1) ) );
    }
    pass P1
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingWireframe );

        SetVertexShader( CompileShader( vs_4_0, TessellationPreprocessedLoDVS(BEZIER, 1) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationWireframePS() ) );
    }
}
technique10 DynamicLoDPmEvaluationTechnique
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( Multisampling );

        SetVertexShader( CompileShader( vs_4_0, TessellationPreprocessedLoDVS(PM, 1) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(1) ) );
    }
}
technique10 DynamicLoDPmEvaluationTechnique_Wireframe
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingDepthBias );

        SetVertexShader( CompileShader( vs_4_0, TessellationPreprocessedLoDVS(PM, 1) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(1) ) );
    }
    pass P1
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingWireframe );

        SetVertexShader( CompileShader( vs_4_0, TessellationPreprocessedLoDVS(PM, 1) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationWireframePS() ) );
    }
}
technique10 DynamicLoDPmTriangleEvaluationTechnique
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( Multisampling );

        SetVertexShader( CompileShader( vs_4_0, TessellationPreprocessedLoDVS(PM, 2) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(2) ) );
    }
}
technique10 DynamicLoDPmTriangleEvaluationTechnique_Wireframe
{
    pass P0
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingDepthBias );

        SetVertexShader( CompileShader( vs_4_0, TessellationPreprocessedLoDVS(PM, 2) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationFullShadingPS(2) ) );
    }
    pass P1
    {
        SetBlendState( EnableColorWrites, float4( 0, 0, 0, 0 ), 0xffffffff );
        SetDepthStencilState( EnableDepthWrites, 0 );
        SetRasterizerState( MultisamplingWireframe );

        SetVertexShader( CompileShader( vs_4_0, TessellationPreprocessedLoDVS(PM, 2) ) );
        SetGeometryShader( NULL );
        SetPixelShader( CompileShader( ps_4_0, TessellationWireframePS() ) );
    }
}
technique10 RenderBaseMesh
{
    pass P0
    {
        SetDepthStencilState( EnableDepth, 0 );
        SetRasterizerState( RSFill );
        SetBlendState( BSBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
        SetVertexShader( CompileShader( vs_4_0, BaseMeshVS() ) );
        SetGeometryShader( CompileShader( gs_4_0, BaseMeshGS() ) );
        SetPixelShader( CompileShader( ps_4_0, zOnlyPS() ) );
    }
    pass P1
    {
        SetDepthStencilState( DSSDepthLessEqual, 0 );
        SetRasterizerState( RSFill );
        SetBlendState( BSBlending, float4( 0.0f, 0.0f, 0.0f, 0.0f ), 0xFFFFFFFF );
        SetVertexShader( CompileShader( vs_4_0, BaseMeshVS() ) );
        SetGeometryShader( CompileShader( gs_4_0, BaseMeshGS() ) );
        SetPixelShader( CompileShader( ps_4_0, BaseMeshPS() ) );
    }
}


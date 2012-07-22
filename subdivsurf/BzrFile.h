
//----------------------------------------------------------------------------------
// File:   BzrFile.h
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

#ifndef BZRFILE_H
#define BZRFILE_H

#include <stdio.h>

#include <GL/glew.h>

#include <glm/glm.hpp>
#include <glm/ext.hpp>

//struct float2 {
//    float x, y;
//};
//struct float3 {
//    float x, y, z;
//};
//struct float4 {
//    float x, y, z, w;
//};


typedef glm::vec2 float2;
typedef glm::vec3 float3;
typedef glm::vec4 float4;


class BzrFile
{
public:
    BzrFile(const char * fileName);
    ~BzrFile();

    int regularPatchCount() const { return m_regularPatchCount; }
    int quadPatchCount() const { return m_quadPatchCount; }
    int trianglePatchCount() const { return m_triPatchCount; }

    int totalPatchCount() const { return m_regularPatchCount + m_quadPatchCount + m_triPatchCount; }

    int indexCount() const { return m_indexCount; }

    const float3 & center() const { return m_center; }
    
    GLuint createMeshVertexBuffer() const;
    GLuint createMeshIndexBuffer() const;

    // Control points as textures
    GLuint createRegularBezierControlPointTexture2D() const;
    GLuint createRegularTexCoordTexture2D() const;

    GLuint createQuadBezierControlPointTexture2D() const;
    GLuint createQuadGregoryControlPointTexture2D() const;
    GLuint createQuadPmControlPointTexture2D() const;
    GLuint createQuadTexCoordTexture2D() const;

    GLuint createTriangleGregoryControlPointTexture2D() const;
    GLuint createTrianglePmControlPointTexture2D() const;
    GLuint createTriangleTexCoordTexture2D() const;

    // Control points as texture buffers
    GLuint createRegularBezierControlPointTextureBuffer() const;
    GLuint createRegularTexCoordTextureBuffer() const;

    GLuint createQuadBezierControlPointTextureBuffer() const;
    GLuint createQuadGregoryControlPointTextureBuffer() const;
    GLuint createQuadPmControlPointTextureBuffer() const;
    GLuint createQuadTexCoordTextureBuffer() const;

    GLuint createTriangleGregoryControlPointTextureBuffer() const;
    GLuint createTrianglePmControlPointTextureBuffer() const;
    GLuint createTriangleTexCoordTextureBuffer() const;

    // Control points as vertex buffers
    GLuint createRegularBezierControlPointVertexBuffer() const;
    GLuint createRegularTexCoordVertexBuffer() const;

    GLuint createQuadBezierControlPointVertexBuffer() const;
    GLuint createQuadGregoryControlPointVertexBuffer() const;
    GLuint createQuadPmControlPointVertexBuffer() const;
    GLuint createQuadTexCoordVertexBuffer() const;

    GLuint createTriangleGregoryControlPointVertexBuffer() const;
    GLuint createTrianglePmControlPointVertexBuffer() const;
    GLuint createTriangleTexCoordVertexBuffer() const;


//private:
    
    GLuint createControlPointTexture2D(float3 * ptr, int patchCount, int controlPointCount) const;
    GLuint createControlPointTexBuffer(GLenum target, float2 * ptr, int patchCount, int controlPointCount) const;
    GLuint createControlPointBuffer(GLenum target, float3 * ptr, int patchCount, int controlPointCount) const;
    
    int m_regularPatchCount;
    int m_quadPatchCount;
    int m_triPatchCount;

    struct {
        float3 * bezierControlPoints;
        float2 * texcoords;
        float3 * normalControlPoints;
    } m_regularPatches;

    struct {
        float3 * bezierControlPoints;
        float3 * gregoryControlPoints;
        float3 * pmControlPoints;
        float2 * texcoords;
        float2 * texcoords2;
        float3 * normalControlPoints;
    } m_quadPatches;

    struct {
        float3 * gregoryControlPoints;
        float3 * pmControlPoints;
        float2 * texcoords;
    } m_triPatches;

    int m_vertexCount;
    float3 * m_vertices;
    int * m_valences;

    int m_maxValence;
    //int * m_oneRingIndices;

    int * m_regularFaceIndices;
    int * m_quadFaceIndices;
    int * m_triFaceIndices;

    int * m_regularFaceOffsets;
    int * m_quadFaceOffsets;
    int * m_triFaceOffsets;

    int m_indexCount;
    int * m_indices;

    float3 m_center;
};


#endif // BZRFILE_H

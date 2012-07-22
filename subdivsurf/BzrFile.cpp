#include "BzrFile.h"


#define PACK_GL_TEXTURES 1


BzrFile::BzrFile(const char * fileName) :
    m_regularPatchCount(0),
    m_quadPatchCount(0),
    m_triPatchCount(0)
{
    m_regularPatches.bezierControlPoints = NULL;
    m_regularPatches.texcoords = NULL;

    m_quadPatches.bezierControlPoints = NULL;
    m_quadPatches.gregoryControlPoints = NULL;
    m_quadPatches.pmControlPoints = NULL;
    m_quadPatches.texcoords = NULL;

    m_triPatches.gregoryControlPoints = NULL;
    m_triPatches.pmControlPoints = NULL;
    m_triPatches.texcoords = NULL;

    m_vertices = NULL;
    m_valences = NULL;

    m_maxValence = 0;

    m_regularFaceIndices = NULL;
    m_quadFaceIndices = NULL;
    m_triFaceIndices = NULL;

    m_indexCount = 0;
    m_indices = NULL;


    FILE * fp = NULL;
    fp = fopen(fileName, "rb" );

    if (fp == NULL) return;

    // Bezier File Format :
    //   Header ('BZR ')            | sizeof(uint)
    //   Version (1.0)              | sizeof(uint)
    //
    //   Part1  Precomputed Control Points:
    //     Regular patch count            | sizeof(uint)
    //     Quad patch count               | sizeof(uint)
    //     Triangle patch count           | sizeof(uint)
    //     Regular Patches:
    //       Bezier control points        | 16 * regularPatchCount * sizeof(float3)
    //       Texture coordinates          | 16 * regularPatchCount * sizeof(float2)
    //       Normal control points        | 16 * regularPatchCount * sizeof(float3)
    //     Quad Patches:
    //       Bezier control points        | 32 * quadPatchCount * sizeof(float3)
    //       Gregory control points       | 20 * quadPatchCount * sizeof(float3)
    //       Pm control points            | 24 * quadPatchCount * sizeof(float3)
    //       Texture coordinates          | 16 * quadPatchCount * sizeof(float2)
    //       Normal control points        | 16 * quadPatchCount * sizeof(float3)
    //     Triangle Patches:
    //       Gregory control points       | 15 * trianglePatchCount * sizeof(float3)
    //       Pm control points            | 19 * trianglePatchCount * sizeof(float3)
    //       Texture coordinates          | 12 * trianglePatchCount * sizeof(float2)
    
    //   Part2 Input Meshe Topology:
    //     Vertex count                   | sizeof(uint)
    //     Vertices                       | vertexCount * sizeof(float3)
    //     Valences                       | vertexCount * sizeof(int)
    //     Max valence                    | sizeof(uint)
    //     Regular face indices           | 4 * regularPatchCount * sizeof(uint)
    //     Quad face indices              | 4 * irregularpatchCount * sizeof(uint)
    //     Triangle face indices          | 3 * trianglePatchCount * sizeof(uint)

    int header, version;
    fread(&header, sizeof(int), 1, fp);
    fread(&version, sizeof(int), 1, fp);
    if (header != ' RZB' || version != 0x0100)
    {
        return;
    }

    fread(&m_regularPatchCount, sizeof(int), 1, fp);
    fread(&m_quadPatchCount, sizeof(int), 1, fp);
    fread(&m_triPatchCount, sizeof(int), 1, fp);
   // m_triPatchCount=0;

    m_regularPatches.bezierControlPoints = new float3[m_regularPatchCount * 16];
    m_regularPatches.texcoords = new float2[m_regularPatchCount * 16];
    m_regularPatches.normalControlPoints = new float3[m_regularPatchCount * 16];
    fread(m_regularPatches.bezierControlPoints, sizeof(float3) * 16, m_regularPatchCount, fp);
    fread(m_regularPatches.texcoords, sizeof(float2) * 16, m_regularPatchCount, fp);
    fread(m_regularPatches.normalControlPoints, sizeof(float3) * 16, m_regularPatchCount, fp);

    // Read quad patches
    m_quadPatches.bezierControlPoints = new float3[m_quadPatchCount * 32];
    m_quadPatches.gregoryControlPoints = new float3[m_quadPatchCount * 20];
    m_quadPatches.pmControlPoints = new float3[m_quadPatchCount * 24];
    m_quadPatches.texcoords = new float2[m_quadPatchCount * 16];
    m_quadPatches.normalControlPoints = new float3[m_quadPatchCount * 16];

    fread(m_quadPatches.bezierControlPoints, sizeof(float3) * 32, m_quadPatchCount, fp);
    fread(m_quadPatches.gregoryControlPoints, sizeof(float3) * 20, m_quadPatchCount, fp);
    fread(m_quadPatches.pmControlPoints, sizeof(float3) * 24, m_quadPatchCount, fp);
    fread(m_quadPatches.texcoords, sizeof(float2) * 16, m_quadPatchCount, fp);
    fread(m_quadPatches.normalControlPoints, sizeof(float3) * 16, m_quadPatchCount, fp);

    // Read triangle patches
    m_triPatches.gregoryControlPoints = new float3[m_triPatchCount * 15];
    m_triPatches.pmControlPoints = new float3[m_triPatchCount * 19];
    m_triPatches.texcoords = new float2[m_triPatchCount * 12];

    fread(m_triPatches.gregoryControlPoints, sizeof(float3) * 15, m_triPatchCount, fp);
    fread(m_triPatches.pmControlPoints, sizeof(float3) * 19, m_triPatchCount, fp);
    fread(m_triPatches.texcoords, sizeof(float2) * 12, m_triPatchCount, fp);

    // Read vertices
    fread(&m_vertexCount, sizeof(int), 1, fp);
    m_vertices = new float3[m_vertexCount];
    m_valences = new int [m_vertexCount];

    fread(m_vertices, sizeof(float3), m_vertexCount, fp);
    fread(m_valences, sizeof(int), m_vertexCount, fp);
    fread(&m_maxValence, sizeof(int), 1, fp);

    m_regularFaceIndices = new int [4 * m_regularPatchCount];
    m_quadFaceIndices = new int [4 * m_quadPatchCount];
    m_triFaceIndices = new int [3 * m_triPatchCount];


    fread(m_regularFaceIndices, sizeof(int), 4 * m_regularPatchCount, fp);
    fread(m_quadFaceIndices, sizeof(int), 4 * m_quadPatchCount, fp);
    fread(m_triFaceIndices, sizeof(int), 3 * m_triPatchCount, fp);


    // Compute triangle indices
    m_indexCount = 6 * m_regularPatchCount + 6 * m_quadPatchCount + 3 * m_triPatchCount;
    m_indices = new int[m_indexCount];

    // keep the same ordering: 2-0-1, 0-2-3 for showing input quad mesh
    // the algorithm replies on this ordering
    int idx = 0;
    for (int i = 0; i < m_regularPatchCount; i++)
    {
        m_indices[idx++] = m_regularFaceIndices[4 * i + 2];
        m_indices[idx++] = m_regularFaceIndices[4 * i + 0];
        m_indices[idx++] = m_regularFaceIndices[4 * i + 1];

        m_indices[idx++] = m_regularFaceIndices[4 * i + 0];
        m_indices[idx++] = m_regularFaceIndices[4 * i + 2];
        m_indices[idx++] = m_regularFaceIndices[4 * i + 3];
    }
    for (int i = 0; i < m_quadPatchCount; i++)
    {
        m_indices[idx++] = m_quadFaceIndices[4 * i + 2];
        m_indices[idx++] = m_quadFaceIndices[4 * i + 0];
        m_indices[idx++] = m_quadFaceIndices[4 * i + 1];

        m_indices[idx++] = m_quadFaceIndices[4 * i + 0];
        m_indices[idx++] = m_quadFaceIndices[4 * i + 2];
        m_indices[idx++] = m_quadFaceIndices[4 * i + 3];
    }
    for (int i = 0; i < m_triPatchCount; i++)
    {
        m_indices[idx++] = m_triFaceIndices[3 * i + 0];
        m_indices[idx++] = m_triFaceIndices[3 * i + 1];
        m_indices[idx++] = m_triFaceIndices[3 * i + 2];
    }
    

    // Compute bbox.
    float3 minCorner = m_vertices[0];
    float3 maxCorner = m_vertices[0];

    for (int i = 0; i < m_vertexCount; i++)
    {
        const float3 & v = m_vertices[i];

        if (minCorner.x > v.x) minCorner.x = v.x;
        else if (maxCorner.x < v.x) maxCorner.x = v.x;

        if (minCorner.y > v.y) minCorner.y = v.y;
        else if (maxCorner.y < v.y) maxCorner.y = v.y;

        if (minCorner.z > v.z) minCorner.z = v.z;
        else if (maxCorner.z < v.z) maxCorner.z = v.z;
    }

    m_center = (minCorner + maxCorner) * 0.5f;
    //float3 extents = (minCorner - maxCorner) * 0.5f;

    fclose(fp);
}


BzrFile::~BzrFile()
{

    delete [] m_regularPatches.bezierControlPoints;
    delete [] m_regularPatches.texcoords;
    delete [] m_regularPatches.normalControlPoints;

    delete [] m_quadPatches.bezierControlPoints;
    delete [] m_quadPatches.gregoryControlPoints;
    delete [] m_quadPatches.pmControlPoints;
    delete [] m_quadPatches.texcoords;
   // delete [] m_quadPatches.texcoords2;
    delete [] m_quadPatches.normalControlPoints;

    delete [] m_triPatches.gregoryControlPoints;
    delete [] m_triPatches.pmControlPoints;
    delete [] m_triPatches.texcoords;

    delete [] m_vertices;
    delete [] m_valences;

    delete [] m_regularFaceIndices;
    delete [] m_quadFaceIndices;
    delete [] m_triFaceIndices;

    delete [] m_indices;
}


GLuint BzrFile::createMeshVertexBuffer() const
{
    GLuint id = 0;
    glGenBuffers(1, &id);

    glBindBuffer(GL_ARRAY_BUFFER, id);
    glBufferData(GL_ARRAY_BUFFER, 3 * sizeof(float) * m_vertexCount, m_vertices, GL_STATIC_DRAW);

    return id;
}

GLuint BzrFile::createMeshIndexBuffer() const
{
    GLuint id = 0;
    glGenBuffers(1, &id);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, id);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(unsigned int) * m_indexCount, m_indices, GL_STATIC_DRAW);

    return id;
}


GLuint BzrFile::createControlPointTexture2D(float3 * ptr, int patchCount, int controlPointCount) const
{
    GLuint id = 0;
    glGenTextures(1, &id);

#if PACK_GL_TEXTURES

    int width = controlPointCount * 3 / 4;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, width, patchCount, 0, GL_RGB, GL_FLOAT, ptr);

#else

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB32F, controlPointCount, patchCount, 0, GL_RGB, GL_FLOAT, ptr);

#endif

    return id;
}


// Control points as textures
GLuint BzrFile::createRegularBezierControlPointTexture2D() const
{
    return createControlPointTexture2D(m_regularPatches.bezierControlPoints, m_regularPatchCount, 16);
}
GLuint BzrFile::createRegularTexCoordTexture2D() const
{
    return 0;
}

GLuint BzrFile::createQuadBezierControlPointTexture2D() const
{
    return createControlPointTexture2D(m_quadPatches.bezierControlPoints, m_quadPatchCount, 32);
}
GLuint BzrFile::createQuadGregoryControlPointTexture2D() const
{
    return createControlPointTexture2D(m_quadPatches.gregoryControlPoints, m_quadPatchCount, 20);
}
GLuint BzrFile::createQuadPmControlPointTexture2D() const
{
    return createControlPointTexture2D(m_quadPatches.pmControlPoints, m_quadPatchCount, 24);
}
GLuint BzrFile::createQuadTexCoordTexture2D() const
{
    return 0;
}

GLuint BzrFile::createTriangleGregoryControlPointTexture2D() const
{
    return createControlPointTexture2D(m_triPatches.gregoryControlPoints, m_triPatchCount, 15);
}
GLuint BzrFile::createTrianglePmControlPointTexture2D() const
{
    return createControlPointTexture2D(m_triPatches.pmControlPoints, m_triPatchCount, 19);
}
GLuint BzrFile::createTriangleTexCoordTexture2D() const
{
    return 0;
}

	
// target is GL_TEXTURE_BUFFER or GL_
GLuint BzrFile::createControlPointBuffer(GLenum target, float3 * ptr, int patchCount, int controlPointCount) const
{
    GLuint id = 0;
    glGenBuffers(1, &id);

    glBindBuffer(target, id);
    glBufferData(target, 3 * sizeof(float) * controlPointCount * patchCount, ptr, GL_STATIC_DRAW);

    return id;
}
GLuint BzrFile::createControlPointTexBuffer(GLenum target, float2 * ptr, int patchCount, int controlPointCount) const
{
    GLuint id = 0;
    glGenBuffers(1, &id);

    glBindBuffer(target, id);
    glBufferData(target, 2 * sizeof(float) * controlPointCount * patchCount, ptr, GL_STATIC_DRAW);

    return id;
}



// Control points as texture buffers
GLuint BzrFile::createRegularBezierControlPointTextureBuffer() const
{
    return createControlPointBuffer(GL_TEXTURE_BUFFER, m_regularPatches.bezierControlPoints, m_regularPatchCount, 16);
}
GLuint BzrFile::createRegularTexCoordTextureBuffer() const
{
    return createControlPointTexBuffer(GL_TEXTURE_BUFFER, m_regularPatches.texcoords, m_regularPatchCount, 16);
}

GLuint BzrFile::createQuadBezierControlPointTextureBuffer() const
{
    return createControlPointBuffer(GL_TEXTURE_BUFFER, m_quadPatches.bezierControlPoints, m_quadPatchCount, 32);
}
GLuint BzrFile::createQuadGregoryControlPointTextureBuffer() const
{
    return createControlPointBuffer(GL_TEXTURE_BUFFER, m_quadPatches.gregoryControlPoints, m_quadPatchCount, 20);
}
GLuint BzrFile::createQuadPmControlPointTextureBuffer() const
{
    return createControlPointBuffer(GL_TEXTURE_BUFFER, m_quadPatches.pmControlPoints, m_quadPatchCount, 24);
}
GLuint BzrFile::createQuadTexCoordTextureBuffer() const
{
    return createControlPointTexBuffer(GL_TEXTURE_BUFFER, m_quadPatches.texcoords, m_quadPatchCount, 16);
}

GLuint BzrFile::createTriangleGregoryControlPointTextureBuffer() const
{
    return createControlPointBuffer(GL_TEXTURE_BUFFER, m_triPatches.gregoryControlPoints, m_triPatchCount, 15);
}
GLuint BzrFile::createTrianglePmControlPointTextureBuffer() const
{
    return createControlPointBuffer(GL_TEXTURE_BUFFER, m_triPatches.pmControlPoints, m_triPatchCount, 19);
}
GLuint BzrFile::createTriangleTexCoordTextureBuffer() const
{
    return createControlPointTexBuffer(GL_TEXTURE_BUFFER, m_triPatches.texcoords, m_triPatchCount, 12);
}

// Control points as vertex buffers
GLuint BzrFile::createRegularBezierControlPointVertexBuffer() const
{
    return createControlPointBuffer(GL_ARRAY_BUFFER, m_regularPatches.bezierControlPoints, m_regularPatchCount, 16);
}
GLuint BzrFile::createRegularTexCoordVertexBuffer() const
{
    return createControlPointTexBuffer(GL_ARRAY_BUFFER, m_regularPatches.texcoords, m_regularPatchCount, 16);
}

GLuint BzrFile::createQuadBezierControlPointVertexBuffer() const
{
    return createControlPointBuffer(GL_ARRAY_BUFFER, m_quadPatches.bezierControlPoints, m_quadPatchCount, 32);
}
GLuint BzrFile::createQuadGregoryControlPointVertexBuffer() const
{
    return createControlPointBuffer(GL_ARRAY_BUFFER, m_quadPatches.gregoryControlPoints, m_quadPatchCount, 20);
}
GLuint BzrFile::createQuadPmControlPointVertexBuffer() const
{
    return createControlPointBuffer(GL_ARRAY_BUFFER, m_quadPatches.pmControlPoints, m_quadPatchCount, 24);
}
GLuint BzrFile::createQuadTexCoordVertexBuffer() const
{
    return createControlPointTexBuffer(GL_ARRAY_BUFFER, m_quadPatches.texcoords, m_quadPatchCount, 16);
}

GLuint BzrFile::createTriangleGregoryControlPointVertexBuffer() const
{
    return createControlPointBuffer(GL_ARRAY_BUFFER, m_triPatches.gregoryControlPoints, m_triPatchCount, 15);
}
GLuint BzrFile::createTrianglePmControlPointVertexBuffer() const
{
    return createControlPointBuffer(GL_ARRAY_BUFFER, m_triPatches.pmControlPoints, m_triPatchCount, 19);
}
GLuint BzrFile::createTriangleTexCoordVertexBuffer() const
{
    return createControlPointTexBuffer(GL_ARRAY_BUFFER, m_triPatches.texcoords, m_triPatchCount, 12);
}


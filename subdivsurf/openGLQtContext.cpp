#include "openGLQtContext.h"

//
//readTextFile
//
char* readTextFile(std::string fileName)
{
	std::ifstream file (fileName.c_str(), std::ifstream::in);

	std::string text;
	
	while (file.good())
	{
		std::string s;

		getline (file, s);
		text += "\n" + s;
	}
	
	char* target = new char [text.size()+1];
	strcpy (target, text.c_str());
	
	return target;
	
}
//



void GLAPIENTRY debugOutput (GLenum source, 
			     GLenum type, 
			     GLuint id, 
			     GLenum severity, 
			     GLsizei length, 
			     const GLchar* message, 
			     GLvoid* userParam)
{
	char debSource[32], debType[32], debSev[32];
	if(source == GL_DEBUG_SOURCE_API_ARB)
		strcpy(debSource, "OpenGL");
	else if(source == GL_DEBUG_SOURCE_WINDOW_SYSTEM_ARB)
		strcpy(debSource, "Windows");
	else if(source == GL_DEBUG_SOURCE_SHADER_COMPILER_ARB)
		strcpy(debSource, "Shader Compiler");
	else if(source == GL_DEBUG_SOURCE_THIRD_PARTY_ARB)
		strcpy(debSource, "Third Party");
	else if(source == GL_DEBUG_SOURCE_APPLICATION_ARB)
		strcpy(debSource, "Application");
	else if(source == GL_DEBUG_SOURCE_OTHER_ARB)
		strcpy(debSource, "Other");
 
	if(type == GL_DEBUG_TYPE_ERROR_ARB)
		strcpy(debType, "error");
	else if(type == GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR_ARB)
		strcpy(debType, "deprecated behavior");
	else if(type == GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR_ARB)
		strcpy(debType, "undefined behavior");
	else if(type == GL_DEBUG_TYPE_PORTABILITY_ARB)
		strcpy(debType, "portability");
	else if(type == GL_DEBUG_TYPE_PERFORMANCE_ARB)
		strcpy(debType, "performance");
	else if(type == GL_DEBUG_TYPE_OTHER_ARB)
		strcpy(debType, "message");
 
	if(severity == GL_DEBUG_SEVERITY_HIGH_ARB)
		strcpy(debSev, "high");
	else if(severity == GL_DEBUG_SEVERITY_MEDIUM_ARB)
		strcpy(debSev, "medium");
	else if(severity == GL_DEBUG_SEVERITY_LOW_ARB)
		strcpy(debSev, "low");

	std::cout << debSource << ": " << debType << " (" << debSev << ") " << id << ": " << message << std::endl;
}
	
	
//
//Konstruktoren, Destruktoren
//
OpenGLQtContext::OpenGLQtContext(QGLFormat* context, QWidget *parent) :
	QGLWidget (*context, parent)
{
	// Qt kann in mehrere Contexte zeichnen, dies setzt unseren neu erstellten als aktuellen 
	makeCurrent();
	
	
	if (!isValid())
		std::cout << "QGL: oGL context invalid" << std::endl;	
	if (!format().doubleBuffer())
		std::cout << "QGL: oGL doublebuffer deaktiviert" << std::endl;
	if (!format().stencil() )
		qWarning("QGL: Could not get stencil buffer; results will be suboptimal");
	if (!format().alpha() )
		qWarning("QGL: Could not get alpha channel; results will be suboptimal");
	if (!format().depth() )
		qWarning("QGL: Could not get depth buffer; results will be suboptimal");	
		
	
	setFocusPolicy (Qt::ClickFocus);

//	timerFPS_ = new QTimer(this);
//	connect(timerFPS_, SIGNAL(timeout()), this, SLOT(timeOutFPS()));
//	timerFPS_->start(1000);

}
//

OpenGLQtContext::~OpenGLQtContext()
{

}
//


//
// initializeGL
//
// virtuelle Funktion der Elternklasse wird hierdurch überschrieben
// initialisieren von glew, setzen von hintergrundfarbe und einigen OpenGL-states
//
void OpenGLQtContext::initializeGL()
{
	glewExperimental = GL_TRUE;
	GLenum glewInitResult = glewInit();
	std::cout << "QGL: OpenGL Version: " << glGetString(GL_VERSION) << std::endl << std::endl;
	
	if(GLEW_OK != glewInitResult)
	{
		std::cout << "QGL: ERROR "<<glewGetErrorString(glewInitResult) << std::endl;
		exit(EXIT_FAILURE);
	}			

	if (glewIsExtensionSupported("GL_ARB_debug_output"))
	{
		std::cout << "QGL: ARB debug output verfuegbar" << std::endl;
		glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS_ARB);
		glDebugMessageControlARB(GL_DONT_CARE, GL_DONT_CARE, GL_DONT_CARE, 0, nullptr, GL_TRUE);
		glDebugMessageCallbackARB(&debugOutput, nullptr);
	}
	else if (glewIsExtensionSupported("GL_AMD_debug_output"))
	{
		std::cout << "QGL: AMD debug output verfuegbar" << std::endl;
                //setupAmdDebugPrinter();
	}
	else
	{
		std::cout << "QGL: Kein debug output verfuegbar oder deaktiviert" << std::endl;
	}


	


//	glClearDepth(1.0f);
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glDisable(GL_DEPTH_CLAMP);
	
//	glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
	glDisable(GL_BLEND);


	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LESS);
	glDisable(GL_CULL_FACE);
//	glCullFace(GL_BACK);
//	glFrontFace(GL_CW);
	glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

	initScene();
}
//


//
// initScene
//
//
void OpenGLQtContext::initScene()
{
	initShader();
	initMatrices();
	initStuff();
}
//


//
// initMatrices
//
//
void OpenGLQtContext::initMatrices()
{
	modelMatrix_ = glm::scale(glm::mat4(1.0f), glm::vec3(5.0f));
	viewMatrix_ = glm::translate(glm::mat4(1.0f), glm::vec3(0.0f, 0.0f, -3.0));
	modelViewMatrix_ = viewMatrix_ * modelMatrix_;
	normalMatrix_ = glm::transpose(glm::inverse(modelViewMatrix_));
	projectionMatrix_ = glm::perspective(60.0f, float(800) / float(600), 0.1f, 100.f);
	mvpMatrix_ = projectionMatrix_ * modelViewMatrix_;
//	lightPos_ = viewMatrix_ * lightPos_;
	
	for (unsigned int i = 0; i < NUMBEROFSHADER; i += 1)
	{
		glUseProgram(shaderID_[i]);
		GLuint mvpMatrixLocation_ = glGetUniformLocation(shaderID_[i], "MVP");
		glUniformMatrix4fv(mvpMatrixLocation_, 1, GL_FALSE, &mvpMatrix_[0][0]); 
		GLuint mvMatrixLocation_ = glGetUniformLocation(shaderID_[i], "MV");
		glUniformMatrix4fv(mvMatrixLocation_, 1, GL_FALSE, &modelViewMatrix_[0][0]);
		GLuint normalMatrixLocation_ = glGetUniformLocation(shaderID_[i], "normalMatrix");
		glUniformMatrix4fv(normalMatrixLocation_, 1, GL_FALSE, &normalMatrix_[0][0]); 
		
		glUniform4fv(glGetUniformLocation(shaderID_[i], "lightPosition"), 1, &lightPos_[0]);
	}

}
//


//
// initStuff
//
//
void OpenGLQtContext::initStuff()
{

	mesh_ = new BzrFile("mesh/testmonster.bzr");
	
//	for (unsigned int i = 0; i < mesh_->m_vertexCount; i += 1)
//	{
//		std::cout << mesh_->m_vertices[i].x << " " << mesh_->m_vertices[i].y << " " << mesh_->m_vertices[i].z << "      " << mesh_->m_valences[i] << "\n";
//	}
	
	std::cout << 
	"Mesh:\n" << 
	"regPatchCount " << mesh_->regularPatchCount() << 
	"\nquadPatchCount " << mesh_->quadPatchCount() << 
	"\ntrianglePatchCount " << mesh_->trianglePatchCount() << 
	"\ntotal " << mesh_->totalPatchCount() << 
	"\nindexCount " << mesh_->indexCount() << 
	"\ncenter " << mesh_->center().x << " "<< mesh_->center().y << " " << mesh_->center().z <<
	"\nvertexCount " << mesh_->m_vertexCount <<
//	"\ntes " << mesh_->m_triPatches <<
	"\n";
	
	for (unsigned int i = 0; i < 16; i += 1)
	{
		std::cout << mesh_->m_quadPatches.bezierControlPoints[i].x << " " << mesh_->m_quadPatches.bezierControlPoints[i].y << " " << mesh_->m_quadPatches.bezierControlPoints[i].z << "\n";
//		if (i % 4 == 3)
//		{
//			std::cout << std::endl;
//		}
	}
	for (unsigned int i = 0; i < 251*16; i += 1)
	{
		std::cout << mesh_->m_quadPatches.texcoords[i].x << " " << mesh_->m_quadPatches.texcoords[i].y << "\n";
		if (i % 16 == 15)
		{
			std::cout << std::endl;
		}
	}
	
	ilInit();
	GLuint texTmp;
	ilGenImages(1, &texTmp);
	ilBindImage(texTmp);
	ILboolean success = ilLoadImage("mesh/testmonster_omap.png");
	if (success)
	{
		glGenTextures(1, &occlusionMap_);
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, occlusionMap_);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, 1024, 1024, 0, GL_RGBA, GL_UNSIGNED_BYTE, ilGetData());
		
		for (unsigned int i = 0; i < NUMBEROFSHADER; i += 1)
		{
			glUseProgram(shaderID_[i]);
			glUniform1i(glGetUniformLocation(shaderID_[i], "occlusionMap"), 0);
		}
	}
	
	success = ilLoadImage("mesh/testmonster_omap2.png");
	if (success)
	{
		glGenTextures(1, &smoothOcclusionMap_);
		glActiveTexture(GL_TEXTURE1);
		glBindTexture(GL_TEXTURE_2D, smoothOcclusionMap_);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, 512, 512, 0, GL_RGB, GL_UNSIGNED_BYTE, ilGetData());
		
		for (unsigned int i = 0; i < NUMBEROFSHADER; i += 1)
		{
			glUseProgram(shaderID_[i]);
			glUniform1i(glGetUniformLocation(shaderID_[i], "smoothOcclusionMap"), 1);
		}
	}
	
	success = ilLoadImage("mesh/testmonster_nmap.png");
	if (success)
	{
		glGenTextures(1, &normalMap_);
		glActiveTexture(GL_TEXTURE2);
		glBindTexture(GL_TEXTURE_2D, normalMap_);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, 2048, 2048, 0, GL_RGB, GL_UNSIGNED_BYTE, ilGetData());

		glBindTexture(GL_TEXTURE_2D, normalMap_);
		
		for (unsigned int i = 0; i < NUMBEROFSHADER; i += 1)
		{
			glUseProgram(shaderID_[i]);
			glUniform1i(glGetUniformLocation(shaderID_[i], "normalMap"), 2);
		}
	}
	
	success = ilLoadImage("mesh/testmonster_vmap.dds");
	if (success)
	{
		glGenTextures(1, &displacementMap_);
		glActiveTexture(GL_TEXTURE3);
		glBindTexture(GL_TEXTURE_2D, displacementMap_);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1024, 1024, 0, GL_RGBA, GL_FLOAT, ilGetData());

		glBindTexture(GL_TEXTURE_2D, displacementMap_);
		
		for (unsigned int i = 0; i < NUMBEROFSHADER; i += 1)
		{
			glUseProgram(shaderID_[i]);
			glUniform1i(glGetUniformLocation(shaderID_[i], "displacementMap"), 3);
		}
	}
	
//	success = ilLoadImage("mesh/reference_pmap.dds");
//	if (success)
//	{
//		glGenTextures(1, &refPosMap_);
//		glActiveTexture(GL_TEXTURE4);
//		glBindTexture(GL_TEXTURE_2D, refPosMap_);
//		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, 1024, 1024, 0, GL_RGBA, GL_FLOAT, ilGetData());
//	
//		glBindTexture(GL_TEXTURE_2D, refPosMap_);
//		
//		for (unsigned int i = 0; i < NUMBEROFSHADER; i += 1)
//		{
//			glUseProgram(shaderID_[i]);
//			glUniform1i(glGetUniformLocation(shaderID_[i], "occlusionMap"), 4);
//		}
//	}
	
//	success = ilLoadImage("mesh/reference_nmap.dds");
//	if (success)
//	{
//		glGenTextures(1, &refNormalMap_);
//		glActiveTexture(GL_TEXTURE5);
//		glBindTexture(GL_TEXTURE_2D, refNormalMap_);
//		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);	
//		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, 1024, 1024, 0, GL_RGBA, GL_FLOAT, ilGetData());
//	
//		glBindTexture(GL_TEXTURE_2D, refNormalMap_);
//		
//		for (unsigned int i = 0; i < NUMBEROFSHADER; i += 1)
//		{
//			glUseProgram(shaderID_[i]);
//			glUniform1i(glGetUniformLocation(shaderID_[i], "occlusionMap"), 5);
//		}
//	}
	
	
	glm::vec3 diffuseMat(0.3f, 0.75f, 0.75f);
	glm::vec3 ambientMat(0.4f, 0.4f, 0.4f);
	glm::vec3 specularMat(0.5f, 0.5f, 0.5f);
	float shininess(50);
	
	for (unsigned int i = 0; i < NUMBEROFSHADER; i += 1)
	{
		glUseProgram(shaderID_[i]);
		glUniform3fv(glGetUniformLocation(shaderID_[i], "diffuseMaterial"), 1, &diffuseMat[0]);
		glUniform3fv(glGetUniformLocation(shaderID_[i], "ambientMaterial"), 1, &ambientMat[0]);
		glUniform3fv(glGetUniformLocation(shaderID_[i], "specularMaterial"), 1, &specularMat[0]);
		glUniform1f(glGetUniformLocation(shaderID_[i], "shininess"), shininess);
		
		glUniform1i(glGetUniformLocation(shaderID_[i], "drawLines"), wireframe_);
		
		
		glUniform1i(glGetUniformLocation(shaderID_[i], "drawLines"), wireframe_);
		glUniform1i(glGetUniformLocation(shaderID_[i], "shading"), shading_);
		glUniform1i(glGetUniformLocation(shaderID_[i], "color3"), color_);
		glUniform1f(glGetUniformLocation(shaderID_[i], "displacementScale"), displacement_);
		glUniform1f(glGetUniformLocation(shaderID_[i], "tessLevel"), tessLevel_);
		glUniform1i(glGetUniformLocation(shaderID_[i], "seamlessTex"), seamlessTex_);
	}

	
	std::vector<glm::vec2> vertices;
	{
		vertices.push_back(glm::vec2(-1.0f, -1.0f));
		vertices.push_back(glm::vec2( 1.0f, -1.0f));
		vertices.push_back(glm::vec2( 1.0f,  1.0f));
		vertices.push_back(glm::vec2(-1.0f,  1.0f));
	}
	std::cout << "#vertices: " << vertices.size() << std::endl;
	
	std::vector<glm::vec4> colors;
	{
		colors.push_back(glm::vec4(1.0f, 0.0f, 0.0f, 1.0f));
		colors.push_back(glm::vec4(1.0f, 1.0f, 0.0f, 1.0f));
		colors.push_back(glm::vec4(0.0f, 1.0f, 0.0f, 1.0f));
		colors.push_back(glm::vec4(0.0f, 0.0f, 1.0f, 1.0f));
	}
	std::cout << "#colors: " << colors.size() << std::endl;
		
	std::vector<glm::vec2> texCoord;
	{
		texCoord.push_back(glm::vec2(0.0f, 0.0f));
		texCoord.push_back(glm::vec2(1.0f, 0.0f));
		texCoord.push_back(glm::vec2(1.0f, 1.0f));
		texCoord.push_back(glm::vec2(0.0f, 1.0f));
	}
	std::cout << "#texCoord: " << texCoord.size() << std::endl;
	
	std::vector<GLuint> indices;
	{
		indices.push_back(GLuint(0));
		indices.push_back(GLuint(1));
		indices.push_back(GLuint(2));
		indices.push_back(GLuint(3));
	}
	std::cout << "#indices: " << indices.size() << std::endl;
	
	glGenVertexArrays(1, &vao_);
	glGenBuffers(1, &vBuf_);
	glGenBuffers(1, &cBuf_);
	glGenBuffers(1, &tBuf_);
//	glGenBuffers(1, &iBuf_);

	glBindVertexArray(vao_);
	{	
		glBindBuffer(GL_ARRAY_BUFFER, vBuf_);
		glBufferData(GL_ARRAY_BUFFER, 2 * sizeof(GLfloat) * vertices.size(), &(vertices[0]), GL_STATIC_DRAW);
		glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, 0);
		glEnableVertexAttribArray(0);
	
		glBindBuffer(GL_ARRAY_BUFFER, cBuf_);
		glBufferData(GL_ARRAY_BUFFER, 4 * sizeof(GLfloat) * colors.size(), &(colors[0]), GL_STATIC_DRAW);
		glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, 0, 0);
		glEnableVertexAttribArray(1);
		
		glBindBuffer(GL_ARRAY_BUFFER, tBuf_);
		glBufferData(GL_ARRAY_BUFFER, 2 * sizeof(GLfloat) * texCoord.size(), &(texCoord[0]), GL_STATIC_DRAW);
		glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 0, 0);
		glEnableVertexAttribArray(2);
	}
	glBindVertexArray(0);
	
	
	glGenVertexArrays(1, &vaoMesh_);
	glGenBuffers(1, &vBufMesh_);
	glGenBuffers(1, &iBufMesh_);
	
	glBindVertexArray(vaoMesh_);
	{	
		vBufMesh_ = mesh_->createMeshVertexBuffer();
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
		glEnableVertexAttribArray(0);
		
		iBufMesh_ = mesh_->createMeshIndexBuffer();
	}
	glBindVertexArray(0);
		
	
	glGenVertexArrays(3, vaoSurf_);
	glGenBuffers(3, vBufSurf_);
	glGenBuffers(3, tBufSurf_);
	
	glBindVertexArray(vaoSurf_[0]);
	{	
		vBufSurf_[0] = mesh_->createRegularBezierControlPointVertexBuffer();
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
		glEnableVertexAttribArray(0);
		
		
		tBufSurf_[0] = mesh_->createRegularTexCoordVertexBuffer();
		glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 0, 0);
		glEnableVertexAttribArray(2);
	}
	glBindVertexArray(0);
	
	glBindVertexArray(vaoSurf_[1]);
	{	
		vBufSurf_[1] = mesh_->createQuadBezierControlPointVertexBuffer();
//		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat) * 32, 0);
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
		glEnableVertexAttribArray(0);
		
//		//tangent
//		glVertexAttribPointer(4, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(GLfloat) * 32, BUFFER_OFFSET(3 * sizeof(GLfloat) * 16));
//		glEnableVertexAttribArray(4);
		
		tBufSurf_[1] = mesh_->createQuadBezierTexCoordVertexBuffer();
		glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 0, 0);
		glEnableVertexAttribArray(2);
	}
	glBindVertexArray(0);
	
	glBindVertexArray(vaoSurf_[2]);
	{	
		vBufSurf_[2] = mesh_->createTriangleGregoryControlPointVertexBuffer();
		glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);
		glEnableVertexAttribArray(0);
		
		
		tBufSurf_[2] = mesh_->createTriangleGregoryTexCoordVertexBuffer();
		glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 0, 0);
		glEnableVertexAttribArray(2);
	}
	glBindVertexArray(0);
}
//


//
// initShader
//
// Erstellen von Shadern
//
void OpenGLQtContext::initShader()
{
//	// Timer für FPS starten
//	timerSinceLastFrame_.start();


	std::string const SHADER_PREFIX[NUMBEROFSHADER] = {"shader/reg/regSubsurf", 
					      "shader/quad/quadSubsurf", 
					      "shader/tri/triSubsurf",
					      "shader/mesh/meshSubsurf",
					      "shader/singleQuad/quad"};

	for (unsigned int i = 0; i < NUMBEROFSHADER; ++i)
	{
		if (i == NUMBEROFSHADER-2)
		{
			std::string const vsFile(SHADER_PREFIX[i] + ".vert");
			std::string const gsFile(SHADER_PREFIX[i] + ".geom");
			std::string const fsFile(SHADER_PREFIX[i] + ".frag");
		
			shaderID_[i] = glCreateProgram();
			{
				GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
				const char* vsSource = readTextFile(vsFile);
		
				GLuint geometryShader = glCreateShader(GL_GEOMETRY_SHADER);
				const char* gsSource = readTextFile(gsFile);
		
				GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
				const char* fsSource = readTextFile(fsFile);


				glShaderSource(vertexShader, 1, &vsSource, nullptr);
				glCompileShader(vertexShader);
		
				glShaderSource(geometryShader, 1, &gsSource, nullptr);
				glCompileShader(geometryShader);
	
				glShaderSource(fragmentShader, 1, &fsSource, nullptr);
				glCompileShader(fragmentShader);
	
				glAttachShader(shaderID_[i], vertexShader);
				glAttachShader(shaderID_[i], geometryShader);
				glAttachShader(shaderID_[i], fragmentShader);
		
				glLinkProgram(shaderID_[i]);
		
				glDeleteShader(vertexShader);
				glDeleteShader(geometryShader);
				glDeleteShader(fragmentShader);
		
				glUseProgram(shaderID_[i]);
			}
		}
		else
		{
			std::string const vsFile(SHADER_PREFIX[i] + ".vert");
			std::string const tcFile(SHADER_PREFIX[i] + ".cont");
			std::string const teFile(SHADER_PREFIX[i] + ".eval");
			std::string const gsFile(SHADER_PREFIX[i] + ".geom");
			std::string const fsFile(SHADER_PREFIX[i] + ".frag");
		
	//		std::string const vsFile(SHADER_PREFIX + "tess.vert");
	//		std::string const tcFile(SHADER_PREFIX + "tess.cont");
	//		std::string const teFile(SHADER_PREFIX + "tess.eval");
	//		std::string const gsFile(SHADER_PREFIX + "tess.geom");
	//		std::string const fsFile(SHADER_PREFIX + "tess.frag");
	
			shaderID_[i] = glCreateProgram();
			{
				GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
				const char* vsSource = readTextFile(vsFile);
	
				GLuint tessControlShader = glCreateShader(GL_TESS_CONTROL_SHADER);
				const char* tcSource = readTextFile(tcFile);
		
				GLuint tessEvalShader = glCreateShader(GL_TESS_EVALUATION_SHADER);
				const char* teSource = readTextFile(teFile);
		
				GLuint geometryShader = glCreateShader(GL_GEOMETRY_SHADER);
				const char* gsSource = readTextFile(gsFile);
		
				GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
				const char* fsSource = readTextFile(fsFile);


				glShaderSource(vertexShader, 1, &vsSource, nullptr);
				glCompileShader(vertexShader);
		
				glShaderSource(tessControlShader, 1, &tcSource, nullptr);
				glCompileShader(tessControlShader);
		
				glShaderSource(tessEvalShader, 1, &teSource, nullptr);
				glCompileShader(tessEvalShader);
		
				glShaderSource(geometryShader, 1, &gsSource, nullptr);
				glCompileShader(geometryShader);
	
				glShaderSource(fragmentShader, 1, &fsSource, nullptr);
				glCompileShader(fragmentShader);
	
				glAttachShader(shaderID_[i], vertexShader);
				glAttachShader(shaderID_[i], tessControlShader);
				glAttachShader(shaderID_[i], tessEvalShader);
				glAttachShader(shaderID_[i], geometryShader);
				glAttachShader(shaderID_[i], fragmentShader);
		
				glLinkProgram(shaderID_[i]);
		
				glDeleteShader(vertexShader);
				glDeleteShader(tessControlShader);
				glDeleteShader(tessEvalShader);
				glDeleteShader(geometryShader);
				glDeleteShader(fragmentShader);
		
				glUseProgram(shaderID_[i]);
			}
		}
	}
		
}
//


//
// paintGL
//
// virtuelle Funktion der Elternklasse wird hierdurch überschrieben
// Render-Funktion
//
void OpenGLQtContext::paintGL()
{	
	// clear buffer
   	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	
	
	switch (next_)
	{
		case 0:
			glBindVertexArray(vaoSurf_[0]);
			{
				glUseProgram(shaderID_[0]);
				glPatchParameteri(GL_PATCH_VERTICES, 16);
	
				// needed without Control Shader
				// glPatchParameterfv(GL_PATCH_DEFAULT_INNER_LEVEL, &glm::vec2(16.f)[0]);
				// glPatchParameterfv(GL_PATCH_DEFAULT_OUTER_LEVEL, &glm::vec4(16.f)[0]);

				glDrawArrays(GL_PATCHES, 0, 16 * mesh_->regularPatchCount());
			}
			glBindVertexArray(vaoSurf_[1]);
			{
				glUseProgram(shaderID_[1]);
				glPatchParameteri(GL_PATCH_VERTICES, 32);
	
				glDrawArrays(GL_PATCHES, 0, 32 * mesh_->quadPatchCount());
			}	
			glBindVertexArray(vaoSurf_[2]);
			{
				glUseProgram(shaderID_[2]);
				glPatchParameteri(GL_PATCH_VERTICES, 15);
		
				glDrawArrays(GL_PATCHES, 0, 15 * mesh_->trianglePatchCount());
			}
			break;
			
		case 1:
			// untesselated polygonmesh
			glBindVertexArray(vaoMesh_);
			{
				glUseProgram(shaderID_[3]);
				glDrawElements(GL_TRIANGLES, mesh_->indexCount(), GL_UNSIGNED_INT, nullptr);
			}
			break;
		case 2:	
			// single tesselated quad
			glBindVertexArray(vao_);
			{
				glUseProgram(shaderID_[4]);
				glPatchParameteri(GL_PATCH_VERTICES, 4);
				glDrawArrays(GL_PATCHES, 0, 4);
			}
			break;
	}

	glBindVertexArray(0);
	
//	++frameCount_;
}
//


//
// resizeGL
//
// virtuelle Funktion der Elternklasse wird hierdurch überschrieben
//
void OpenGLQtContext::resizeGL(int width, int height)
{
	glViewport(0, 0, width, height);
	resize(width, height);
	projectionMatrix_ = glm::perspective(60.0f, float(width) / float(height), 0.1f, 100.f);
	mvpMatrix_ = projectionMatrix_ * modelViewMatrix_;
	
	for (unsigned int i = 0; i < NUMBEROFSHADER; i += 1)
	{
		glUseProgram(shaderID_[i]);
		GLuint mvpMatrixLocation_ = glGetUniformLocation(shaderID_[i], "MVP");
		glUniformMatrix4fv(mvpMatrixLocation_, 1, GL_FALSE, &mvpMatrix_[0][0]);
	}
	
}
//



//
// keyPressEvent
//
// wird aufgerufen, sobald eine Taste gedrückt wird
//
void OpenGLQtContext::keyPressEvent(QKeyEvent* event)
{
	int key = event->key();
	if (!hasFocus())
	{
		std::cout << "QGL: keinen Focus!" << std::endl;
	}

	switch (key)
	{
		case Qt::Key_Escape:
					qApp->quit();
					break;


		case Qt::Key_Left:
					viewMatrix_ = glm::translate (glm::mat4(1.0f), glm::vec3 (0.10f, 0.0f, 0.0f)) * viewMatrix_;
					break;
					
		case Qt::Key_Right:
					viewMatrix_ = glm::translate (glm::mat4(1.0f), glm::vec3 (-0.10f, 0.0f, 0.0f)) * viewMatrix_;
					break;

		case Qt::Key_Up:
					viewMatrix_ = glm::translate (glm::mat4(1.0f), glm::vec3 (0.0f, 0.10f, 0.0f)) * viewMatrix_;
					break;
					
		case Qt::Key_Down:
					viewMatrix_ = glm::translate (glm::mat4(1.0f), glm::vec3 (0.0f, -0.10f, 0.0f)) * viewMatrix_;
					break;
					
		case Qt::Key_PageUp:
					viewMatrix_ = glm::translate (glm::mat4(1.0f), glm::vec3 (0.0f, 0.0f, 0.10f)) * viewMatrix_;
					break;
					
		case Qt::Key_PageDown:
					viewMatrix_ = glm::translate (glm::mat4(1.0f), glm::vec3 (0.0f, 0.0f, -0.10f)) * viewMatrix_;
					break;
					
		case Qt::Key_N:
					next_ = (next_+1) % 3;
					break;
					
		case Qt::Key_W:
					wireframe_ = wireframe_ == true ? false : true;
					break;
		
		case Qt::Key_S:
					shading_ = shading_ == true ? false : true;
					break;
					
		case Qt::Key_C:
					color_ = color_ == true ? false : true;
					break;
					
		case Qt::Key_L:
					seamlessTex_ = seamlessTex_ == true ? false : true;
					break;
					
		case Qt::Key_D:
					displacement_ += 0.1f;
					if (displacement_ > 1.0f)
					{
						displacement_ = 0.0f;
					}
					break;
					
		case Qt::Key_T:
					tessLevel_ += 1.0f;
					break;
		case Qt::Key_Y:
					tessLevel_ -= 1.0f;
					if (tessLevel_ < 1.0f)
					{
						tessLevel_ = 1.0f;
					}
					break;
												
	default:		
		std::cout << "QGL: Key nicht belegt" << std::endl;
	}

	
	modelViewMatrix_ = viewMatrix_ * modelMatrix_;
	normalMatrix_ = glm::transpose(glm::inverse(modelViewMatrix_));
	mvpMatrix_ = projectionMatrix_ * modelViewMatrix_;
//	lightPos_ = viewMatrix_ * lightPos_;
	for (unsigned int i = 0; i < NUMBEROFSHADER; i += 1)
	{
		glUseProgram(shaderID_[i]);
		GLuint mvpMatrixLocation_ = glGetUniformLocation(shaderID_[i], "MVP");
		glUniformMatrix4fv(mvpMatrixLocation_, 1, GL_FALSE, &mvpMatrix_[0][0]); 
		GLuint mvMatrixLocation_ = glGetUniformLocation(shaderID_[i], "MV");
		glUniformMatrix4fv(mvMatrixLocation_, 1, GL_FALSE, &modelViewMatrix_[0][0]);
		GLuint normalMatrixLocation_ = glGetUniformLocation(shaderID_[i], "normalMatrix");
		glUniformMatrix4fv(normalMatrixLocation_, 1, GL_FALSE, &normalMatrix_[0][0]);
		
		glUniform1i(glGetUniformLocation(shaderID_[i], "drawLines"), wireframe_);
		glUniform1i(glGetUniformLocation(shaderID_[i], "shading"), shading_);
		glUniform1i(glGetUniformLocation(shaderID_[i], "color3"), color_);
		glUniform1f(glGetUniformLocation(shaderID_[i], "displacementScale"), displacement_);
		glUniform1f(glGetUniformLocation(shaderID_[i], "tessLevel"), tessLevel_);
		glUniform1i(glGetUniformLocation(shaderID_[i], "seamlessTex"), seamlessTex_);
		
//		glUniform4fv(glGetUniformLocation(shaderID_[i], "lightPosition"), 1, &lightPos_[0]);
	}
	update();
}
//


//
// mousePressEvent
//
// wird aufgerufen, wenn eine Maustaste gedrückt wird
//
void OpenGLQtContext::mousePressEvent(QMouseEvent *event)
{
	lastPos_ = event->pos();
}
//


//
// mouseMoveEvent
//
// wird aufgerufen, wenn die Maus bewegt wird
//
void OpenGLQtContext::mouseMoveEvent(QMouseEvent *event)
{
	int dx = event->x() - lastPos_.x();
	int dy = event->y() - lastPos_.y();

	
	if (event->buttons() & Qt::LeftButton)
	{
		if (dx < 0)
			modelMatrix_ = glm::rotate(modelMatrix_, float(-M_PI), glm::vec3(0.0f, 1.0f, 0.0f));
		else
			modelMatrix_ = glm::rotate(modelMatrix_, float(M_PI), glm::vec3(0.0f, 1.0f, 0.0f));
		
		if (dy < 0)
			modelMatrix_ = glm::rotate(modelMatrix_, float(-M_PI), glm::vec3(1.0f, 0.0f, 0.0f));
		else
			modelMatrix_ = glm::rotate(modelMatrix_, float(M_PI), glm::vec3(1.0f, 0.0f, 0.0f));
	}
	else if (event->buttons() & Qt::RightButton)
	{
//		if (dx < 0)
//			
//			viewMatrix_ = viewMatrix_ * glm::rotate(glm::mat4(1.0f), float(-M_PI), glm::vec3(0.0f, 1.0f, 0.0f));
//		else
//			viewMatrix_ = viewMatrix_ * glm::rotate(glm::mat4(1.0f), float(M_PI), glm::vec3(0.0f, 1.0f, 0.0f));
//		
//		if (dy < 0)
//			viewMatrix_ = viewMatrix_ * glm::rotate(glm::mat4(1.0f), float(-M_PI), glm::vec3(1.0f, 0.0f, 0.0f));
//		else
//			viewMatrix_ = viewMatrix_ * glm::rotate(glm::mat4(1.0f), float(M_PI), glm::vec3(1.0f, 0.0f, 0.0f));	
	}
	
	modelViewMatrix_ = viewMatrix_ * modelMatrix_;
	normalMatrix_ = glm::transpose(glm::inverse(modelViewMatrix_));
	mvpMatrix_ = projectionMatrix_ * modelViewMatrix_;
//	lightPos_ = viewMatrix_ * lightPos_;
	for (unsigned int i = 0; i < NUMBEROFSHADER; i += 1)
	{
		glUseProgram(shaderID_[i]);
		GLuint mvpMatrixLocation_ = glGetUniformLocation(shaderID_[i], "MVP");
		glUniformMatrix4fv(mvpMatrixLocation_, 1, GL_FALSE, &mvpMatrix_[0][0]); 
		GLuint mvMatrixLocation_ = glGetUniformLocation(shaderID_[i], "MV");
		glUniformMatrix4fv(mvMatrixLocation_, 1, GL_FALSE, &modelViewMatrix_[0][0]);
		GLuint normalMatrixLocation_ = glGetUniformLocation(shaderID_[i], "normalMatrix");
		glUniformMatrix4fv(normalMatrixLocation_, 1, GL_FALSE, &normalMatrix_[0][0]); 
		
//		glUniform4fv(glGetUniformLocation(shaderID_[i], "lightPosition"), 1, &lightPos_[0]);
	}


	lastPos_ = event->pos();
	
	update();
}
//


//
// mouseReleaseEvent
//
// wird aufgerufen, wenn eine Maustaste losgelassen wird
//
//void OpenGLQtContext::mouseReleaseEvent(QMouseEvent *event)
//{
//
//}
//


//
// timeOut-Funktionen
//
// wird aufgerufen, wenn zugehöriger Timer abläuft
//
//void OpenGLQtContext::timeOutFPS()
//{
//	QString v;
//	v.setNum(frameCount_);
//	frameCount_=0;
//	setWindowTitle(tr("TreeHugger_ @")+v+tr(" FPS"));
//	std::cout << "QGL: " << v.toStdString() << " FPS\n";
//}
//




//	glActiveTexture(GL_TEXTURE20);
//	glBindTexture(GL_TEXTURE_2D, rindeTex_);

//	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 2000, 3008, 0, GL_RGB, GL_FLOAT, barkdata_);
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
//	
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
//	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
//


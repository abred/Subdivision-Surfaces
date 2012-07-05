#include "shader.h"


//
//Konstruktoren, Destruktor
//
Shader::Shader() : pVsShader(0), pGsShader(0), pFsShader(0), shaderID(0)	{}

Shader::Shader (std::string VsFile) 
{
	init(VsFile, std::string(), std::string());
}

Shader::Shader (std::string VsFile, std::string FsFile) 
{
	init(VsFile, std::string(), FsFile);
}

Shader::Shader (std::string VsFile, std::string GsFile, std::string FsFile) 
{
	init(VsFile, GsFile, FsFile);
}

Shader::~Shader()	
{
	glDetachShader (shaderID, pFsShader);
	glDetachShader (shaderID, pGsShader);
	glDetachShader (shaderID, pVsShader);
	
	glDeleteShader (pFsShader);
	glDeleteShader (pGsShader);
	glDeleteShader (pVsShader);

	glDeleteProgram (shaderID);
}
//

int Shader::currentShader_ = 0;

//
//init
//
void	Shader::init (std::string VsFile)
{
	init(VsFile, std::string(), std::string());
}
void	Shader::init (std::string VsFile, std::string FsFile)
{
	init(VsFile, std::string(), FsFile);
}

void	Shader::init (std::string VsFile, std::string GsFile, std::string FsFile)
{

	pVsShader = glCreateShader(GL_VERTEX_SHADER);
	pGsShader = glCreateShader(GL_GEOMETRY_SHADER);
	pFsShader = glCreateShader(GL_FRAGMENT_SHADER);
	
						//std::ifstream VsShaderFile(VsFile.c_str());
						//std::stringstream shaderData;
						//shaderData << VsShaderFile.rdbuf();
						//VsShaderFile.close();
						//const std::string &VsShader = shaderData.str();

						//std::ifstream FsShaderFile(FsFile.c_str());
						////std::stringstream shaderData;
						//shaderData << FsShaderFile.rdbuf();
						//FsShaderFile.close();
						//const std::string &VsShader = shaderData.str();
	
	
	shaderID = glCreateProgram();


	const char* VsText = readTextFile (VsFile);
	glShaderSource(pVsShader, 1, &VsText, 0);
	glCompileShader (pVsShader);

#ifdef _DEBUG
	printShaderInfoLog(pVsShader); // bzw. validateShader(pVsShader, VsFile.c_str());
#endif

	glAttachShader (shaderID ,pVsShader);
	

	if (VsText == NULL)
	{
		std::cout << "Fehler beim Laden des Vertex-Shader" << std::endl;
	}
	delete[] VsText;


	if(GsFile != "")
	{
		const char* GsText = readTextFile (GsFile);
		glShaderSource(pGsShader, 1, &GsText, 0);	
		glCompileShader (pGsShader);

#ifdef _DEBUG
		printShaderInfoLog(pGsShader); // bzw. validateShader(pFsShader, FsFile.c_str());
#endif		

		glAttachShader (shaderID, pGsShader);
		
		if (GsText == NULL)
		{
			std::cout << "Fehler beim Laden des Geometry-Shader" << std::endl;
		}
		delete[] GsText;
	}


	if(FsFile != "")
	{
		const char* FsText = readTextFile (FsFile);
		glShaderSource(pFsShader, 1, &FsText, 0);	
		glCompileShader (pFsShader);

#ifdef _DEBUG
		printShaderInfoLog(pFsShader); // bzw. validateShader(pFsShader, FsFile.c_str());
#endif

		glAttachShader (shaderID, pFsShader);

		if (FsText == NULL)
		{
			std::cout << "Fehler beim Laden des Fragment-Shader" << std::endl;
		}
		delete[] FsText;
	}

	glLinkProgram (shaderID);

#ifdef _DEBUG
	printProgramInfoLog(shaderID);
#endif
}
//


//
//bind, unbind
//
void	Shader::bind()		const
{
	glUseProgram (shaderID);
}
//
void	Shader::unbind()	const
{
	glUseProgram (0);
}
//


//
//id
//
unsigned int	Shader::getID()		const
{
	return shaderID;
}
//


//
//ValidateShader
//
void Shader::validateShader(GLuint shader, const char* file)
{
	const GLuint	BUFFER_SIZE = 512;
	char 		buffer[BUFFER_SIZE];
	GLsizei		length = 0;
	
	memset(buffer, 0, BUFFER_SIZE);
	
	glGetShaderInfoLog (shader, BUFFER_SIZE, &length, buffer);
	
	if (length > 0)
	{
		std::cout << "Shader " << shader << "(" << (file?file:"") << ") compile log:\n" << buffer << std::endl; 
	}
	
}
//


//
// ValidateProgram
//
void Shader::validateProgram (GLuint program)
{
	const GLuint	BUFFER_SIZE = 512;
	char 		buffer[BUFFER_SIZE];
	GLsizei		length = 0;
	
	memset(buffer, 0, BUFFER_SIZE);
	
	glGetProgramInfoLog (program, BUFFER_SIZE, &length, buffer);
	
	if (length > 0)
	{
		std::cout << "Program " << program << " link log:\n" << buffer << std::endl;
	}
	
	glValidateProgram (program);
	GLint status;
	glGetProgramiv (program, GL_VALIDATE_STATUS, &status);
	
	if (status == GL_FALSE)
	{
		std::cout << "Error validating shader " << program << std::endl;
	}
}
//



//
//readTextFile
//
char* readTextFile( std::string fileName)
{
	std::ifstream file ( fileName.c_str(), std::ifstream::in );

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



//
// printProgramInfoLog
//
void printProgramInfoLog(GLuint obj)
{
	int infologLength = 0;
	int charsWritten  = 0;
	char *infoLog;

	glGetProgramiv(obj, GL_INFO_LOG_LENGTH,&infologLength);

	if (infologLength > 0)
	{
		infoLog = (char *)malloc(infologLength);
	        glGetProgramInfoLog(obj, infologLength, &charsWritten, infoLog);
		printf("%s\n",infoLog);
	        free(infoLog);
	}
}
//


//
// printShaderInfoLog
//
void printShaderInfoLog(GLuint obj)
{
	int infologLength = 0;
	int charsWritten  = 0;
	char *infoLog;

	glGetShaderiv(obj, GL_INFO_LOG_LENGTH,&infologLength);

	if (infologLength > 0)
	{
	        infoLog = (char *)malloc(infologLength);
	        glGetShaderInfoLog(obj, infologLength, &charsWritten, infoLog);
			printf("%s\n",infoLog);
	        free(infoLog);
	}
}
//



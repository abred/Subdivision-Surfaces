#ifndef __SHADER_H__
#define __SHADER_H__


#include <GL/glew.h>

#include <QtCore/QtCore>
#include <QtGui/QtGui>
//#include <QtOpenGL>

#include <string>
#include <string.h>
#include <stdio.h>
#include <iostream>
#include <fstream>
#include <sstream>




class Shader 
{
	public:
						Shader ();
						Shader (std::string VsFile);
						Shader (std::string VsFile, std::string FsFile);
						Shader (std::string VsFile, std::string GsFile, std::string FsFile);
						~Shader ();

		void			init (std::string VsFile);
		void			init (std::string VsFile, std::string FsFile);
		void			init (std::string VsFile, std::string GsFile, std::string FsFile);
		void			bind()							const;
		void			unbind()						const;
		unsigned int	getID()							const;	

		void			validateShader (unsigned int shader, const char* file = 0);
		void			validateProgram (unsigned int program);
		
		static	int		currentShader_;
		
	private:
		unsigned int		pVsShader;
		unsigned int		pGsShader;
		unsigned int		pFsShader;

		unsigned int		shaderID;
		
};

char* readTextFile (std::string file);
void printProgramInfoLog(unsigned int obj);
void printShaderInfoLog(unsigned int obj);

#endif /* __SHADER_H__ */

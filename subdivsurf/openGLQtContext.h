#ifndef __OPENGLQTCONTEXT_H__
#define __OPENGLQTCONTEXT_H__

#define BUFFER_OFFSET(i) ((char*) NULL + (i))
#define NUMBEROFSHADER 5


#include <iostream>
#include <fstream>
#include <vector>



#include <GL/glew.h>
#include <QGLWidget>
#include <QMouseEvent>
#include <QKeyEvent>

#include <IL/il.h>



#include <glm/glm.hpp>
#include <glm/ext.hpp>

#include "BzrFile.h"
#include <QApplication>


class OpenGLQtContext : public QGLWidget
{
	Q_OBJECT	// nötig um Qt signals/slots zu nutzen
	
	public:

			OpenGLQtContext(QGLFormat *context, QWidget *parent = 0);
			~OpenGLQtContext();

	
	protected:

			// überschriebene Funktionen der Elternklassen
			void 			initializeGL();
			void 			paintGL();
			void 			resizeGL(int width, int height);


			void 			mousePressEvent(QMouseEvent *);
			//void 			mouseReleaseEvent(QMouseEvent *);
			void 			mouseMoveEvent(QMouseEvent *);
			void			keyPressEvent(QKeyEvent *);

	private:

		void		initScene();
		void		initShader();
		void		initMatrices();
		void		initStuff();
		
		GLuint    	shaderID_[NUMBEROFSHADER];
		
		glm::mat4 	modelMatrix_;
		glm::mat4 	viewMatrix_;
		glm::mat4 	modelViewMatrix_;
		glm::mat4 	normalMatrix_;
		glm::mat4 	projectionMatrix_;
		glm::mat4 	mvpMatrix_;
		
		GLuint    	vao_;
		GLuint    	vBuf_;
		GLuint    	tBuf_;
		GLuint    	cBuf_;
//		GLuint    	iBuf_;
		
		GLuint    	vaoMesh_;
		GLuint    	vBufMesh_;
		GLuint    	iBufMesh_;
		
		GLuint    	vaoSurf_[3];
		GLuint    	vBufSurf_[3];
		GLuint    	tBufSurf_[3];


		QPoint 	  	lastPos_;
		
		BzrFile*  	mesh_;
		
		GLuint    	occlusionMap_;
		GLuint    	smoothOcclusionMap_;
		GLuint    	normalMap_;
		GLuint    	displacementMap_;
		GLuint    	refPosMap_;
		GLuint    	refNormalMap_;
		
		GLuint    	next_ = 0;
		bool		wireframe_ = false;
		bool      	shading_ = true;
		bool      	color_ = false;
		float     	displacement_ = 0.0f;
		float     	tessLevel_ = 16.0f;
		bool      	seamlessTex_ = false;
		
		glm::vec4 	lightPos_ = glm::vec4(10.0f,25.0f, 50.0f, 1.0f);
		

//	public slots:

//		void		timeOutFPS();
};

void GLAPIENTRY debugOutput (GLenum source, 
			     GLenum type, 
			     GLuint id, 
			     GLenum severity, 
			     GLsizei length, 
			     const GLchar* message, 
			     GLvoid* userParam);
			     
#endif // OPENGLQTCONTEXT_H__

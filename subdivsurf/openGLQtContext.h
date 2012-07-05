#ifndef __OPENGLQTCONTEXT_H__
#define __OPENGLQTCONTEXT_H__

#define BUFFER_OFFSET(i) ((char*) NULL + (i))

#include <iostream>


#include <GL/glew.h>
#include <QGLWidget>
#include <QMouseEvent>
#include <QKeyEvent>


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

		void			initScene();


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

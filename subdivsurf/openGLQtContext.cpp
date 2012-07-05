#include "openGLQtContext.h"



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
	if ( !format().stencil() )
		qWarning( "QGL: Could not get stencil buffer; results will be suboptimal" );
	if ( !format().alpha() )
		qWarning( "QGL: Could not get alpha channel; results will be suboptimal" );
	if ( !format().depth() )
		qWarning( "QGL: Could not get depth buffer; results will be suboptimal" );	
		
	
	setFocusPolicy ( Qt::ClickFocus);

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
		glDebugMessageControlARB(GL_DONT_CARE, GL_DONT_CARE, GL_DONT_CARE, 0, NULL, GL_TRUE);
		glDebugMessageCallbackARB(&debugOutput, NULL);
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


	


	glClearDepth(1.0f);
	glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );

//	glBlendFunc(GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
//	glEnable( GL_BLEND );


//	glEnable( GL_DEPTH_TEST );
//	glDepthFunc(GL_LESS);
//	glCullFace(GL_BACK);
//	glFrontFace(GL_CW);
//	glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

	initScene();
}
//


//
// initScene
//
// Erstellen von Shadern, Objekten (z.B. Zylinder)
// Setzen von Matrizen
//
void OpenGLQtContext::initScene()
{
//	// Timer für FPS starten
//	timerSinceLastFrame_.start();
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
	// buffer leeren
   	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);



//	++frameCount_;
//	update();
}
//


//
// resizeGL
//
// virtuelle Funktion der Elternklasse wird hierdurch überschrieben
//
void OpenGLQtContext::resizeGL(int width, int height)
{
//	glViewport(0, 0, width, height);
//	resize(width, height);
//	projectionMatrix_ = glm::perspective(60.0f, float(width) / float(height), 0.1f, 100.f);
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
//		case Qt::Key_Escape:
//					qApp->quit();
//					break;


//		case Qt::Key_Left:
//					modelMatrix_ = glm::translate (glm::mat4(1.0f), glm::vec3 (1.0f, 0.0f, 0.0f)) * modelMatrix_;
//					break;
	default:		
		std::cout << "QGL: Key nicht belegt" << std::endl;
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
//	lastPos_ = event->pos();
}
//


//
// mouseMoveEvent
//
// wird aufgerufen, wenn die Maus bewegt wird
//
void OpenGLQtContext::mouseMoveEvent(QMouseEvent *event)
{
//	int dx = event->x() - lastPos_.x();
//	int dy = event->y() - lastPos_.y();


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
//	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
//    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
//	
//	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
//	glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
//


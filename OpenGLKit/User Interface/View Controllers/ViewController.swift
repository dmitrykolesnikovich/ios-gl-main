/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import GLKit

//
// MARK: - View Controller
//

/// Our subclass of GLKViewController to perform drawing, and logic updates using OpenGL ES.
final class ViewController: GLKViewController {
  
  /// Vertices array that stores 4 Vertex objects used to draw and color a square on screen.
  var Vertices = [
    Vertex(x:  1, y: -1, z: 0, r: 1, g: 0, b: 0, a: 1),
    Vertex(x:  1, y:  1, z: 0, r: 0, g: 1, b: 0, a: 1),
    Vertex(x: -1, y:  1, z: 0, r: 0, g: 0, b: 1, a: 1),
    Vertex(x: -1, y: -1, z: 0, r: 0, g: 0, b: 0, a: 1),
    ]
  
  /// Array used to store the indices in the order we want to draw the triangles of our square.
  var Indices: [GLubyte] = [
    0, 1, 2,
    2, 3, 0
  ]
  
  //
  // MARK: - Variables And Properties
  //
  
  /// Reference to provide easy access to our EAGLContext.
  private var context: EAGLContext?
  
  /// Effect to facilitate having to write shaders in order to achieve shading and lighting.
  private var effect = GLKBaseEffect()
  
  /// Used to store and determine the rotation value of our drawn geometry.
  private var rotation: Float = 0.0
  
  /// Element buffer object. Stores the indices that tell OpenGL what vertices to draw.
  private var ebo = GLuint()
  
  /// Vertex buffer object. Stores our vertex information within the GPU's memory.
  private var vbo = GLuint()
  
  /// Vertex array object. Stores vertex attribute calls that facilitate future drawing. Instead of having to bind/unbind
  /// several buffers constantly to perform drawn, you can simply bind your VAO, make the vertex attribute cals you would
  /// to draw elements on screen, and then whenever you want to draw you simply bind your VAO and it stores those other
  /// vertex attribute calls.
  private var vao = GLuint()
  
  //
  // MARK: - Initialization
  //
  
  /// Method to deinitialize and perform cleanup when the view controller is removed from memory.
  deinit {
    // Delete buffers, cleanup memory, etc.
    tearDownGL()
  }
  
  //
  // MARK: - Private Methods
  //
  
  /// Setup the current OpenGL context, generate and find necessary buffers, and store geometry data in memory (buffers).
  private func setupGL() {
    // Create an OpenGL ES 3.0 context and store it in our local variable.
    context = EAGLContext(api: .openGLES3)
    
    // Set the current EAGLContext to our context we created when performing OpenGL setup.
    EAGLContext.setCurrent(context)
    
    // Perform checks and unwrap options in order to perform more OpenGL setup.
    if let view = self.view as? GLKView, let context = context {
      // Set our view's context to the EAGLContext we just created.s
      view.context = context
      
      // Set ourselves as delegates of GLKViewControllerDelegate
      delegate = self
    }
    
    // Helper variables to identify the position and color attributes for OpenGL calls.
    let vertexAttribColor = GLuint(GLKVertexAttrib.color.rawValue)
    let vertexAttribPosition = GLuint(GLKVertexAttrib.position.rawValue)
    
    // The size, in memory, of a Vertex structure.
    let vertexSize = MemoryLayout<Vertex>.stride
    // The byte offset, in memory, of our color information within a Vertex object.
    let colorOffset = MemoryLayout<GLfloat>.stride * 3
    // Swift pointer object that stores the offset of the color information within our Vertex structure.
    let colorOffsetPointer = UnsafeRawPointer(bitPattern: colorOffset)
    
    // VAO
    
    // Generate and bind a vertex array object.
    glGenVertexArraysOES(1, &vao)
    glBindVertexArrayOES(vao)
    
    // VBO
    
    // Generatea a buffer for our vertex buffer object.
    glGenBuffers(1, &vbo)
    // Bind the vertex buffer object we just generated (created).
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), vbo)
    // Pass data for our vertices to the vertex buffer object.
    glBufferData(GLenum(GL_ARRAY_BUFFER), Vertices.size(), Vertices, GLenum(GL_STATIC_DRAW))
    
    // Enable the position vertex attribute to then specify information about how the position of a vertex is stored.
    glEnableVertexAttribArray(vertexAttribPosition)
    glVertexAttribPointer(vertexAttribPosition, 3, GLenum(GL_FLOAT), GLboolean(UInt8(GL_FALSE)), GLsizei(vertexSize), nil)
    
    // Enable the colors vertex attribute to then specify information about how the color of a vertex is stored.
    glEnableVertexAttribArray(vertexAttribColor)
    glVertexAttribPointer(vertexAttribColor, 4, GLenum(GL_FLOAT), GLboolean(UInt8(GL_FALSE)), GLsizei(vertexSize), colorOffsetPointer)
    
    // EBO
    
    // Generatea a buffer for our element buffer object.
    glGenBuffers(1, &ebo)
    // Bind the element buffer object we just generated (created).
    glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), ebo)
    // Pass data for our element indices to the element buffer object.
    glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), Indices.size(), Indices, GLenum(GL_STATIC_DRAW))
    
    // Unbind all buffers and objects.
    
    // Unbind the vertex buffer and the vertex array object.
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), 0)
    glBindVertexArrayOES(0)
  }
  
  
  /// Perform cleanup, and delete buffers and memory.
  private func tearDownGL() {
    // Set the current EAGLContext to our context. This ensures we are deleting buffers against it and potentially not a
    // different context.
    EAGLContext.setCurrent(context)
    
    // Delete the vertex array object, the element buffer object, and the vertex buffer object.
    glDeleteBuffers(1, &vao)
    glDeleteBuffers(1, &vbo)
    glDeleteBuffers(1, &ebo)
    
    // Set the current EAGLContext to nil.
    EAGLContext.setCurrent(nil)
    
    // Then nil out or variable that references our EAGLContext.
    context = nil
  }
  
  //
  // MARK: - Touch Handling
  //
  
  /// Used to detect when a tap occurs on screen so we can pause updates of our program.
  ///
  /// - Parameters:
  ///   - touches: The touches that occurred on screen.
  ///   - event: Describes the user interactions in the app.
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    // Pause or unpause updating our program.
    isPaused = !isPaused
  }
  
  //
  // MARK: - View Controller
  //
  
  /// Called when the view controller's view is loaded into memory.
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Perform OpenGL setup, create buffers, pass geometry data to memory.
    setupGL()
  }
}

//
// MARK: - GLKViewController Delegate
//
extension ViewController: GLKViewControllerDelegate {
  func glkViewControllerUpdate(_ controller: GLKViewController) {
    let aspect = fabsf(Float(view.bounds.size.width) / Float(view.bounds.size.height))
    let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0), aspect, 4.0, 10.0)
    effect.transform.projectionMatrix = projectionMatrix
    
    var modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -6.0)
    rotation += 90 * Float(timeSinceLastUpdate)
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(rotation), 0, 0, 1)
    effect.transform.modelviewMatrix = modelViewMatrix
  }
}

//
// MARK: - GLKView Delegate
//

/// Extension to implement the GLKViewDelegate methods.
extension ViewController {

  /// Draw the view's contents using OpenGL ES.
  ///
  /// - Parameters:
  ///   - view: The GLKView object to redraw contents into.
  ///   - rect: Rectangle that describes the area to draw into.
  override func glkView(_ view: GLKView, drawIn rect: CGRect) {
    // Set the color we want to clear the screen with (before drawing) to black.
    glClearColor(0.85, 0.85, 0.85, 1.0)
    // Clear the contents of the screen (the color buffer) with the black color we just set.
    glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
    
    // Compiles the shaders for drawing and binds them to the current context.
    effect.prepareToDraw()
    
    // We bind our vertex array object, essentially indicating we want to use its information to draw geometry on screen.
    glBindVertexArrayOES(vao);
    // Make the call to draw elements on screen. We indicate we want to draw triangles, specify the number of vertices we
    // want to draw via our indices array, and also tell OpenGL what variable type is used to store the index information.
    glDrawElements(GLenum(GL_TRIANGLES), GLsizei(Indices.count), GLenum(GL_UNSIGNED_BYTE), nil)
    // Unbind the vertex array object so future calls don't accidentally use it.
    glBindVertexArrayOES(0)
  }
}

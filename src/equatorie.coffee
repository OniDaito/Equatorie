###
                       __  .__              ________ 
   ______ ____   _____/  |_|__| ____   ____/   __   \
  /  ___// __ \_/ ___\   __\  |/  _ \ /    \____    /
  \___ \\  ___/\  \___|  | |  (  <_> )   |  \ /    / 
 /____  >\___  >\___  >__| |__|\____/|___|  //____/  .co.uk
      \/     \/     \/                    \/         
                                              CoffeeGL
                                              Benjamin Blundell - ben@section9.co.uk
                                              http://www.section9.co.uk

This software is released under Creative Commons Attribution Non-Commercial Share Alike
http://creativecommons.org/licenses/by-nc-sa/3.0/

###

class Equatorie

  init : () =>
    
    @top_node = new CoffeeGL.Node()

    r = new CoffeeGL.Request('../models/equatorie.js')

    r.get (data) =>
      @g = new CoffeeGL.JSONModel(data) 
      @g.matrix.translate(new CoffeeGL.Vec3(0,0,0))
      @top_node.add(@g)


    r = new CoffeeGL.Request ('../shaders/basic_lighting.glsl')
    r.get (data) =>
      @shader = new CoffeeGL.Shader(data)
      @shader.bind()

    @c = new CoffeeGL.Camera.MousePerspCamera(new CoffeeGL.Vec3(0,0,25))
    @top_node.add(@c)

    @light = new CoffeeGL.Light.PointLight(new CoffeeGL.Vec3(0.0,0.0,25.0), new CoffeeGL.Colour.RGB(1.0,1.0,1.0) );

    @light2 = new CoffeeGL.Light.PointLight(new CoffeeGL.Vec3(0.0,15.0,5.0), new CoffeeGL.Colour.RGB(1.0,1.0,1.0) );

    @top_node.add(@light)
    @top_node.add(@light2)

    GL.enable(GL.CULL_FACE)
    GL.cullFace(GL.BACK)
    GL.enable(GL.DEPTH_TEST)

  update : (dt) =>
  
    @angle = dt * 0.001 * CoffeeGL.degToRad(20.0)
    if @angle >= CoffeeGL.PI * 2
      @angle = 0
    m = new CoffeeGL.Quaternion()
    m.fromAxisAngle(new CoffeeGL.Vec3(0,1,0), @angle)
    @light.pos = m.transVec(@light.pos)

  
  draw : () =>

    GL.clearColor(0.15, 0.15, 0.15, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

    @shader?.setUniform3v("uAmbientLightingColor", new CoffeeGL.Colour.RGB(0.05,0.05,0.05))

    @c.update()

    @top_node.draw() if @top_node?
  

eq = new Equatorie()

cgl = new CoffeeGL.App('webgl-canvas', eq.init, eq.draw, eq.update)
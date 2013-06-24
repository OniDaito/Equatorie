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

class EquatorieSystem

  constructor : () ->
    @planet_data = {}

    # Data for the Equatorie mathematical model

    @planet_data.mars =
      equant : 2.0
      deferent : 1.0 
      angle : 30.0

    @mean_motus = 0     # Arc of motion of epicycle around deferent
    @mean_argument = 0  # Arc of motion of planet around epicycle


  calculateEpicycle : (planet) ->
    # relative to 0 degrees - the sign of aries    
    # Line of apsides
    x = @planet_data[planet].deferent * Math.sin(CoffeeGL.degToRad @planet_data[planet].angle)
    y = @planet_data[planet].deferent * Math.cos(CoffeeGL.degToRad @planet_data[planet].angle)
    
    # now rotate by mean motus and radius of epicycle (6.353 at present)

    rx = 6.353 * Math.sin( CoffeeGL.degToRad @mean_motus)
    ry = 6.353 * Math.cos( CoffeeGL.degToRad @mean_motus)

    [x + rx, y + ry]  


class Equatorie

  init : () =>
    
    @top_node = new CoffeeGL.Node()

    @system = new EquatorieSystem()

    r0 = new CoffeeGL.Request ('../shaders/basic.glsl')
    r0.get (data) =>
      @shader_basic = new CoffeeGL.Shader(data, {"uColour" : "uColour"})

      r1 = new CoffeeGL.Request ('../shaders/basic_lighting.glsl')
      
      r1.get (data) =>
        @shader = new CoffeeGL.Shader(data)
        @shader.bind()
        @shader?.setUniform3v("uAmbientLightingColor", new CoffeeGL.Colour.RGB(0.15,0.15,0.15))
        @shader.unbind()

        r2 = new CoffeeGL.Request('../models/equatorie.js')

        r2.get (data) =>
          @g = new CoffeeGL.JSONModel(data) 
          @top_node.add(@g)

          # Should be three children nodes with this model. Attach the shaders
          
          @pointer  = @g.children[0]
          @epicycle = @g.children[1]
          @base     = @g.children[2]

          @pointer.shader   = @shader_basic
          @epicycle.shader  = @shader_basic
          @base.shader      = @shader

          @pointer.uColour = new CoffeeGL.Colour.RGBA(1.0,1.0,0.0,1.0)
          @epicycle.uColour = new CoffeeGL.Colour.RGBA(0.6,0.6,0.0,1.0)

          # Remove the pointer and add it as a child of the Epicycle
          @g.remove @pointer
          @epicycle.add @pointer

          # Rotate the Base so the Sign of Aries is in the right place
          q = new CoffeeGL.Quaternion()
          q.fromAxisAngle(new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad(-90.0))

          @base.matrix.mult q.getMatrix4() 


    @c = new CoffeeGL.Camera.MousePerspCamera(new CoffeeGL.Vec3(0,0,25))
    @top_node.add(@c)

    @light = new CoffeeGL.Light.PointLight(new CoffeeGL.Vec3(0.0,5.0,25.0), new CoffeeGL.Colour.RGB(1.0,1.0,1.0) );

    @light2 = new CoffeeGL.Light.PointLight(new CoffeeGL.Vec3(0.0,15.0,5.0), new CoffeeGL.Colour.RGB(1.0,1.0,1.0) );

    @top_node.add(@light)
    @top_node.add(@light2)

    GL.enable(GL.CULL_FACE)
    GL.cullFace(GL.BACK)
    GL.enable(GL.DEPTH_TEST)


    # DAT Gui stuff
    # https://gist.github.com/ikekou/5589109
    g=new dat.GUI()
    g.remember(@)
    
    controller = g.add(@system,'mean_argument',0,360)
    controller = g.add(@system,'mean_motus',0,360)


  update : (dt) =>
  
    @angle = dt * 0.001 * CoffeeGL.degToRad(20.0)
    if @angle >= CoffeeGL.PI * 2
      @angle = 0
    m = new CoffeeGL.Quaternion()
    m.fromAxisAngle(new CoffeeGL.Vec3(0,1,0), @angle)
    m.transVec3(@light.pos)

    # Calculate the epicycle
    [x,y] = @system.calculateEpicycle("mars")

    @epicycle?.matrix.toIdentity()
    @epicycle?.matrix.translate new CoffeeGL.Vec3 x,0,y


    @pointer?.matrix.toIdentity()
    q = new CoffeeGL.Quaternion()
    q.fromAxisAngle(new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad(@system.mean_argument))

    @pointer?.matrix.mult q.getMatrix4()

    @

  draw : () =>

    GL.clearColor(0.15, 0.15, 0.15, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

    @c.update()

    @top_node.draw() if @top_node?
  
eq = new Equatorie()

cgl = new CoffeeGL.App('webgl-canvas', eq, eq.init, eq.draw, eq.update)
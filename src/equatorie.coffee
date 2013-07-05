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


{EquatorieSystem} = require './system'
{EquatorieString} = require './string'

class Equatorie

  init : () =>
    
    # All nodes to be drawn
    @top_node = new CoffeeGL.Node()

    # Nodes for the picking
    @pickable = new CoffeeGL.Node()

    @system = new EquatorieSystem()

    r0 = new CoffeeGL.Request ('../shaders/basic.glsl')
    r0.get (data) =>
      @shader_basic = new CoffeeGL.Shader(data, {"uColour" : "uColour"})
      @white_string.shader = @shader_basic
      @black_string.shader = @shader_basic
      @white_string.uColour = new CoffeeGL.Colour.RGBA(0.9,0.9,0.9,1.0)
      @black_string.uColour = new CoffeeGL.Colour.RGBA(0.1,0.1,0.1,1.0)

      @deferent.shader = @shader_basic
      @deferent.uColour = new CoffeeGL.Colour.RGBA(1.0,0.0,0.0,1.0)



      r1 = new CoffeeGL.Request ('../shaders/basic_lighting.glsl')
      
      r1.get (data) =>
        @shader = new CoffeeGL.Shader(data, {"uAmbientLightingColor" : "uAmbientLightingColor"})
      
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

          @base.uAmbientLightingColor = new CoffeeGL.Colour.RGBA(0.0,1.0,1.0,1.0)

          @pointer.uColour = new CoffeeGL.Colour.RGBA(1.0,1.0,0.0,1.0)
          @epicycle.uColour = new CoffeeGL.Colour.RGBA(0.6,0.6,0.0,1.0)

          # Remove the pointer and add it as a child of the Epicycle
          @g.remove @pointer
          @epicycle.add @pointer

          # Rotate the Base so the Sign of Aries is in the right place
          q = new CoffeeGL.Quaternion()
          q.fromAxisAngle(new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad(-90.0))

          @base.matrix.mult q.getMatrix4() 

          r3 = new CoffeeGL.Request('../shaders/picking.glsl')
          r3.get (data) =>
            @shader_picker = new CoffeeGL.Shader(data, {"uPickingColour" : "uPickingColour"})


    # Points on the surface of the Equatorie
    cube = new CoffeeGL.Shapes.Cuboid new CoffeeGL.Vec3 0.2,0.2,0.2
    @deferent = new CoffeeGL.Node cube
    @top_node.add @deferent




    @c = new CoffeeGL.Camera.MousePerspCamera(new CoffeeGL.Vec3(0,0,25))
    @top_node.add(@c)
    @pickable.add(@c)

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
    
    planets = ["mars","venus","jupiter","saturn"]
    @chosen_planet = "mars"

    controller = g.add(@system,'mean_argument',0,360)
    controller = g.add(@system,'mean_motus',0,360)
    controller = g.add(@,'chosen_planet',planets)

    # Add Strings
    @white_string = new EquatorieString 8.0, 0.1, 20
    @black_string = new EquatorieString 8.0, 0.1, 20
    
    @top_node.add @white_string
    @top_node.add @black_string


    # Launch physics web worker
    @physics = new Worker '/js/physics.js'
    @physics.onmessage = @onPhysicsEvent
    @physics.postMessage { cmd: "startup" }


    # Register for click events
    CoffeeGL.Context.mouseDown.add @onMouseDown, @


  update : (dt) =>
  
    @angle = dt * 0.001 * CoffeeGL.degToRad(20.0)
    if @angle >= CoffeeGL.PI * 2
      @angle = 0
    m = new CoffeeGL.Quaternion()
    m.fromAxisAngle(new CoffeeGL.Vec3(0,1,0), @angle)
    m.transVec3(@light.pos)

    # Calculate the Deferent Centre
    
    [x,y] = @system.calculateDeferentPosition(@chosen_planet)
    @deferent.matrix.identity()
    @deferent.matrix.translate new CoffeeGL.Vec3 x,0.2,y

    [x,y] = @system.calculateEpicyclePosition(@chosen_planet)
    @epicycle?.matrix.identity()
    @epicycle?.matrix.translate new CoffeeGL.Vec3 x,0,y


    @pointer?.matrix.identity()
    q = new CoffeeGL.Quaternion()
    q.fromAxisAngle(new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad(@system.mean_argument))

    @pointer?.matrix.mult q.getMatrix4()
   
    @

  # update the physics - each body in the string needs to have its position and orientation updated
  updatePhysics : (data) ->
    @white_string.update data.white
    @black_string.update data.black

  onMouseDown : (event) ->
    @physics.postMessage {cmd : "white_start_move", data: {x:3, y: 0.5, z: 3}}

  onPhysicsEvent : (event) =>
    switch event.data.cmd
      when "physics" then @updatePhysics event.data.data
      else break

  draw : () =>

    GL.clearColor(0.15, 0.15, 0.15, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

    @c.update()

    @top_node.draw() if @top_node?


    # Draw everything pickable to the pickable FBO
    if @shader_picker?
      @shader_picker.bind()
      @pickable.draw()
      @shader_picker.unbind()

  
eq = new Equatorie()

cgl = new CoffeeGL.App('webgl-canvas', eq, eq.init, eq.draw, eq.update)